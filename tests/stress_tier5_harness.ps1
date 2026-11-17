# Tier 5 Empirical Stress, Concurrency & Hardening Test Suite
# Challenger: challenger_tier5_2
# Purpose: Empirically stress-test CLI launchers, scripts, projects under concurrent, cross-shell, and pathological path conditions.

[CmdletBinding()]
param(
    [string]$ProjectRoot = "D:\vr_game_dev"
)

$ErrorActionPreference = "Continue"

function IIf($condition, $trueVal, $falseVal) {
    if ($condition) { return $trueVal } else { return $falseVal }
}

$results = [System.Collections.Generic.List[PSCustomObject]]::new()
$startTime = Get-Date

function Record-Result {
    param(
        [string]$Category,
        [string]$TestName,
        [bool]$Success,
        [int]$ExitCode,
        [double]$DurationMs,
        [string]$Details,
        [string]$ErrorOutput = ""
    )
    $obj = [PSCustomObject]@{
        Category    = $Category
        TestName    = $TestName
        Success     = $Success
        ExitCode    = $ExitCode
        DurationMs  = [Math]::Round($DurationMs, 2)
        Details     = $Details
        ErrorOutput = $ErrorOutput
    }
    $results.Add($obj)

    $tag = if ($Success) { "[PASS]" } else { "[FAIL]" }
    $color = if ($Success) { "Green" } else { "Red" }
    Write-Host "$tag $Category - $TestName ($([Math]::Round($DurationMs, 1))ms)" -ForegroundColor $color
    if (-not $Success -or $ErrorOutput) {
        Write-Host "       Details: $Details" -ForegroundColor Yellow
        if ($ErrorOutput) {
            Write-Host "       Error: $ErrorOutput" -ForegroundColor Red
        }
    }
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "          STARTING TIER 5 EMPIRICAL STRESS & CONCURRENCY HARNESS               " -ForegroundColor Cyan
Write-Host "================================================================================`n" -ForegroundColor Cyan

$godotCmd = "$ProjectRoot\bin\godot.cmd"
$godotPs1 = "$ProjectRoot\bin\godot.ps1"
$godotBash = "$ProjectRoot\bin\godot"
$checkScript = "$ProjectRoot\scripts\check_environment.ps1"
$vrProj = "$ProjectRoot\projects\vr_hello_world"
$webxrProj = "$ProjectRoot\projects\webxr_hello_world"
$tempBase = "$ProjectRoot\tests\.tier5_temp"

if (Test-Path -LiteralPath $tempBase) {
    Remove-Item -LiteralPath $tempBase -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $tempBase -Force | Out-Null

# ------------------------------------------------------------------------------
# SECTION 1: CONCURRENCY & RAPID BURST EXECUTION
# ------------------------------------------------------------------------------
Write-Host "--- SECTION 1: Concurrency & Rapid Burst Execution ---" -ForegroundColor Magenta

# 1.1 Rapid sequential burst of godot.cmd (20x)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$burstCount = 20
$burstPass = $true
$burstErrors = @()
for ($i = 1; $i -le $burstCount; $i++) {
    $proc = Start-Process -FilePath $godotCmd -ArgumentList "--version" -NoNewWindow -PassThru -Wait
    if ($proc.ExitCode -ne 0) {
        $burstPass = $false
        $burstErrors += "Iteration $i returned exit code $($proc.ExitCode)"
    }
}
$sw.Stop()
$burstExit = IIf $burstPass 0 1
$burstErrText = $burstErrors -join "; "
Record-Result -Category "Concurrency" -TestName "Rapid sequential burst of godot.cmd (20 iterations)" `
    -Success $burstPass -ExitCode $burstExit -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Completed $burstCount sequential executions of godot.cmd --version; Avg: $([Math]::Round($sw.Elapsed.TotalMilliseconds / $burstCount, 1))ms" `
    -ErrorOutput $burstErrText

# 1.2 High-concurrency parallel burst of godot.cmd (10 concurrent processes)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$parallelCount = 10
$procs = @()
$outFiles = @()
$errFiles = @()

for ($i = 0; $i -lt $parallelCount; $i++) {
    $outFile = Join-Path $tempBase "godot_par_${i}.out"
    $errFile = Join-Path $tempBase "godot_par_${i}.err"
    $outFiles += $outFile
    $errFiles += $errFile
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$godotCmd --version`"" `
        -RedirectStandardOutput $outFile -RedirectStandardError $errFile -PassThru
    $procs += $p
}

$allFinished = $true
$timeoutSec = 15
$waitSw = [System.Diagnostics.Stopwatch]::StartNew()
foreach ($p in $procs) {
    $remaining = [Math]::Max(100, ($timeoutSec * 1000) - $waitSw.ElapsedMilliseconds)
    if (-not $p.WaitForExit($remaining)) {
        $allFinished = $false
        try { $p.Kill() } catch {}
    }
}
$sw.Stop()

$parSuccess = $allFinished
$parErr = ""
if (-not $allFinished) {
    $parErr = "One or more parallel godot.cmd processes hung after $timeoutSec s"
} else {
    for ($i = 0; $i -lt $parallelCount; $i++) {
        $exitCode = $procs[$i].ExitCode
        $content = if (Test-Path $outFiles[$i]) { Get-Content $outFiles[$i] -Raw } else { "" }
        if ($exitCode -ne 0 -or -not ($content -match "4\.3\.stable")) {
            $parSuccess = $false
            $parErr += "Process $i exit=$exitCode, out='$content'; "
        }
    }
}
$parExit = IIf $parSuccess 0 1
Record-Result -Category "Concurrency" -TestName "High-concurrency parallel burst (10x simultaneous godot.cmd)" `
    -Success $parSuccess -ExitCode $parExit -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Spawned $parallelCount simultaneous godot.cmd processes" `
    -ErrorOutput $parErr

# 1.3 High-concurrency parallel headless VR project validation (4 concurrent Godot test runners on same project)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$vrProcs = @()
$vrOuts = @()
$vrErrs = @()
$vrCount = 4

for ($i = 0; $i -lt $vrCount; $i++) {
    $outFile = Join-Path $tempBase "vr_par_${i}.out"
    $errFile = Join-Path $tempBase "vr_par_${i}.err"
    $vrOuts += $outFile
    $vrErrs += $errFile
    $p = Start-Process -FilePath $godotCmd `
        -ArgumentList "--headless --path `"$vrProj`" -s res://test_runner.gd" `
        -RedirectStandardOutput $outFile -RedirectStandardError $errFile -PassThru
    $vrProcs += $p
}

$vrFinished = $true
$vrWaitSw = [System.Diagnostics.Stopwatch]::StartNew()
foreach ($p in $vrProcs) {
    $rem = [Math]::Max(100, (20000) - $vrWaitSw.ElapsedMilliseconds)
    if (-not $p.WaitForExit($rem)) {
        $vrFinished = $false
        try { $p.Kill() } catch {}
    }
}
$sw.Stop()

$vrSuccess = $vrFinished
$vrErrMsg = ""
if (-not $vrFinished) {
    $vrErrMsg = "Concurrent Godot VR test runner hung on project lock"
} else {
    for ($i = 0; $i -lt $vrCount; $i++) {
        $c = if (Test-Path $vrOuts[$i]) { Get-Content $vrOuts[$i] -Raw } else { "" }
        if ($vrProcs[$i].ExitCode -ne 0 -or -not ($c -match "ALL CI VALIDATION CHECKS PASSED")) {
            $vrSuccess = $false
            $vrErrMsg += "Instance $i exit=$($vrProcs[$i].ExitCode); "
        }
    }
}
$vrExit = IIf $vrSuccess 0 1
Record-Result -Category "Concurrency" -TestName "Concurrent Godot headless VR test runners (4x same project)" `
    -Success $vrSuccess -ExitCode $vrExit -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Tested for project file locks, cache collisions (.godot directory)" `
    -ErrorOutput $vrErrMsg

# 1.4 Concurrent execution of check_environment.ps1 -SkipBuild (4 concurrent instances)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$chkProcs = @()
$chkOuts = @()
$chkErrs = @()
$chkCount = 4

for ($i = 0; $i -lt $chkCount; $i++) {
    $outFile = Join-Path $tempBase "chk_par_${i}.json"
    $errFile = Join-Path $tempBase "chk_par_${i}.err"
    $chkOuts += $outFile
    $chkErrs += $errFile
    $p = Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$checkScript`" -SkipBuild -Json" `
        -RedirectStandardOutput $outFile -RedirectStandardError $errFile -PassThru
    $chkProcs += $p
}

$chkFinished = $true
$chkWaitSw = [System.Diagnostics.Stopwatch]::StartNew()
foreach ($p in $chkProcs) {
    $rem = [Math]::Max(100, (25000) - $chkWaitSw.ElapsedMilliseconds)
    if (-not $p.WaitForExit($rem)) {
        $chkFinished = $false
        try { $p.Kill() } catch {}
    }
}
$sw.Stop()

$chkSuccess = $chkFinished
$chkErrMsg = ""
if (-not $chkFinished) {
    $chkErrMsg = "Concurrent check_environment.ps1 hung"
} else {
    for ($i = 0; $i -lt $chkCount; $i++) {
        $jsonRaw = if (Test-Path $chkOuts[$i]) { Get-Content $chkOuts[$i] -Raw } else { "" }
        $parsed = $null
        try {
            $parsed = $jsonRaw | ConvertFrom-Json
        } catch {
            $parsed = $null
        }
        if ($chkProcs[$i].ExitCode -ne 0 -or $null -eq $parsed -or $parsed.Failed -ne 0) {
            $chkSuccess = $false
            $chkErrMsg += "Instance $i failed or invalid JSON (Exit=$($chkProcs[$i].ExitCode)); "
        }
    }
}
$chkExit = IIf $chkSuccess 0 1
Record-Result -Category "Concurrency" -TestName "Concurrent check_environment.ps1 -SkipBuild (4x parallel)" `
    -Success $chkSuccess -ExitCode $chkExit -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Tested for concurrent registry queries, script read locks, JSON serialization" `
    -ErrorOutput $chkErrMsg

# 1.5 Rapid sequential builds of WebXR project (3x in a row)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$npmBuildPass = $true
$npmErrMsg = ""
for ($i = 1; $i -le 3; $i++) {
    $p = Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c cd /d `"$webxrProj`" && npm run build" `
        -NoNewWindow -PassThru -Wait
    if ($p.ExitCode -ne 0) {
        $npmBuildPass = $false
        $npmErrMsg += "Build $i failed with exit code $($p.ExitCode); "
    }
}
$sw.Stop()
$npmExit = IIf $npmBuildPass 0 1
Record-Result -Category "Concurrency" -TestName "Rapid sequential WebXR production builds (3 iterations)" `
    -Success $npmBuildPass -ExitCode $npmExit -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Checked dist/ cleaning, vite asset hashing, incremental build stability" `
    -ErrorOutput $npmErrMsg

# ------------------------------------------------------------------------------
# SECTION 2: CROSS-SHELL INVOCATION FIDELITY
# ------------------------------------------------------------------------------
Write-Host "`n--- SECTION 2: Cross-Shell Invocation Fidelity ---" -ForegroundColor Magenta

# 2.1 CMD Invocation: Global PATH resolution from C:\
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$cmdOutFile = Join-Path $tempBase "cmd_global.out"
$cmdErrFile = Join-Path $tempBase "cmd_global.err"
$p = Start-Process -FilePath "cmd.exe" `
    -ArgumentList "/c cd /d C:\ && godot --version" `
    -RedirectStandardOutput $cmdOutFile -RedirectStandardError $cmdErrFile -PassThru -Wait
$sw.Stop()
$cmdOut = if (Test-Path $cmdOutFile) { Get-Content $cmdOutFile -Raw } else { "" }
$cmdSuccess = ($p.ExitCode -eq 0) -and ($cmdOut -match "4\.3\.stable")
$cmdErr = if (Test-Path $cmdErrFile) { Get-Content $cmdErrFile -Raw } else { "" }
Record-Result -Category "CrossShell" -TestName "CMD: Global naked 'godot --version' from C:\" `
    -Success $cmdSuccess -ExitCode $p.ExitCode -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Output: $($cmdOut.Trim())" `
    -ErrorOutput $cmdErr

# 2.2 CMD Invocation: Errorlevel propagation on invalid script
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$p = Start-Process -FilePath "cmd.exe" `
    -ArgumentList "/c `"$godotCmd --headless -s res://non_existent_script_xyz.gd`"" `
    -NoNewWindow -PassThru -Wait
$sw.Stop()
$errLevelSuccess = ($p.ExitCode -ne 0)
$errLevelMsg = IIf ($p.ExitCode -eq 0) "Godot returned 0 despite missing script" ""
Record-Result -Category "CrossShell" -TestName "CMD: %ERRORLEVEL% propagation on engine error" `
    -Success $errLevelSuccess -ExitCode $p.ExitCode -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Exit code: $($p.ExitCode) (Expected non-zero on missing script)" `
    -ErrorOutput $errLevelMsg

# 2.3 PowerShell Invocation: Global resolution and pipeline object capture
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$psOut = powershell.exe -NoProfile -Command "cd C:\; (godot --version) -match '4\.3\.stable'"
$sw.Stop()
$psSuccess = ($LASTEXITCODE -eq 0) -and ($psOut -match "True")
$psOutErr = IIf (-not $psSuccess) "Failed pipeline capture or exit code $LASTEXITCODE" ""
Record-Result -Category "CrossShell" -TestName "PowerShell: Pipeline object capture from C:\" `
    -Success $psSuccess -ExitCode $LASTEXITCODE -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Pipeline match result: $psOut" `
    -ErrorOutput $psOutErr

# 2.4 PowerShell Invocation: $LASTEXITCODE fidelity on non-zero exit
$sw = [System.Diagnostics.Stopwatch]::StartNew()
powershell.exe -NoProfile -Command "& '$godotPs1' --headless -s res://missing_script.gd; exit `$LASTEXITCODE"
$psErrCode = $LASTEXITCODE
$sw.Stop()
$psErrSuccess = ($psErrCode -ne 0)
$psCodeErr = IIf ($psErrCode -eq 0) "godot.ps1 returned 0 on error" ""
Record-Result -Category "CrossShell" -TestName "PowerShell: `$LASTEXITCODE fidelity through godot.ps1" `
    -Success $psErrSuccess -ExitCode $psErrCode -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Propagated exit code: $psErrCode" `
    -ErrorOutput $psCodeErr

# 2.5 Git Bash / POSIX Invocation: Invocation of bin\godot launcher
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$gitBashExe = "C:\Program Files\Git\bin\bash.exe"
$bashOutFile = Join-Path $tempBase "bash_test.out"
$bashErrFile = Join-Path $tempBase "bash_test.err"

$bashInstalled = Test-Path -LiteralPath $gitBashExe
if ($bashInstalled) {
    # Convert path to POSIX style for git bash
    $bashScriptPath = "/d/vr_game_dev/bin/godot"
    $p = Start-Process -FilePath $gitBashExe `
        -ArgumentList "-c `"$bashScriptPath --version`"" `
        -RedirectStandardOutput $bashOutFile -RedirectStandardError $bashErrFile -PassThru -Wait
    $sw.Stop()
    $bashOut = if (Test-Path $bashOutFile) { Get-Content $bashOutFile -Raw } else { "" }
    $bashErr = if (Test-Path $bashErrFile) { Get-Content $bashErrFile -Raw } else { "" }
    
    # Check for shebang / BOM error
    $hasBomError = ($bashErr -match "No such file or directory") -or ($bashErr -match "#!/usr/bin/env")
    $bashClean = ($p.ExitCode -eq 0) -and ($bashOut -match "4\.3\.stable") -and (-not $hasBomError)

    $bashErrMsg = IIf $hasBomError "BOM corruption detected: Stderr contains '$($bashErr.Trim())'" (IIf ($p.ExitCode -ne 0) "Exit code $($p.ExitCode)" "")
    Record-Result -Category "CrossShell" -TestName "Git Bash: Invocation and stderr cleanliness of bin\godot" `
        -Success $bashClean -ExitCode $p.ExitCode -DurationMs $sw.Elapsed.TotalMilliseconds `
        -Details "Stdout: $($bashOut.Trim()); Stderr: $($bashErr.Trim())" `
        -ErrorOutput $bashErrMsg
} else {
    Record-Result -Category "CrossShell" -TestName "Git Bash: Invocation and stderr cleanliness of bin\godot" `
        -Success $false -ExitCode 1 -DurationMs 0 `
        -Details "Git bash not found at $gitBashExe" -ErrorOutput "Missing Git Bash"
}

# 2.6 Git Bash: Execution of test runner via bash wrapper
if ($bashInstalled) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $bashVrOut = Join-Path $tempBase "bash_vr.out"
    $bashVrErr = Join-Path $tempBase "bash_vr.err"
    $p = Start-Process -FilePath $gitBashExe `
        -ArgumentList "-c `"/d/vr_game_dev/bin/godot --headless --path /d/vr_game_dev/projects/vr_hello_world -s res://test_runner.gd`"" `
        -RedirectStandardOutput $bashVrOut -RedirectStandardError $bashVrErr -PassThru -Wait
    $sw.Stop()
    $bOut = if (Test-Path $bashVrOut) { Get-Content $bashVrOut -Raw } else { "" }
    $bErr = if (Test-Path $bashVrErr) { Get-Content $bashVrErr -Raw } else { "" }
    $bPass = ($p.ExitCode -eq 0) -and ($bOut -match "ALL CI VALIDATION CHECKS PASSED")
    $bErrMsg = IIf (-not $bPass) "Failed runner via bash: Stderr=$bErr" ""
    Record-Result -Category "CrossShell" -TestName "Git Bash: Godot VR test runner execution via POSIX shell" `
        -Success $bPass -ExitCode $p.ExitCode -DurationMs $sw.Elapsed.TotalMilliseconds `
        -Details "ExitCode=$($p.ExitCode)" `
        -ErrorOutput $bErrMsg
}

# ------------------------------------------------------------------------------
# SECTION 3: RESILIENCE TO ODD PATHS, SPACES, AND SPECIAL SYMBOLS
# ------------------------------------------------------------------------------
Write-Host "`n--- SECTION 3: Resilience to Odd Paths, Spaces, and Special Symbols ---" -ForegroundColor Magenta

# 3.1 Path with Spaces
$spaceDir = Join-Path $tempBase "Project With Multiple Spaces"
New-Item -ItemType Directory -Path $spaceDir -Force | Out-Null
Copy-Item -Path "$vrProj\*" -Destination $spaceDir -Recurse -Force | Out-Null

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$spaceOut = Join-Path $tempBase "space_test.out"
$spaceErr = Join-Path $tempBase "space_test.err"
$p = Start-Process -FilePath $godotCmd `
    -ArgumentList "--headless --path `"$spaceDir`" -s res://test_runner.gd" `
    -RedirectStandardOutput $spaceOut -RedirectStandardError $spaceErr -PassThru -Wait
$sw.Stop()
$sOut = if (Test-Path $spaceOut) { Get-Content $spaceOut -Raw } else { "" }
$spaceSuccess = ($p.ExitCode -eq 0) -and ($sOut -match "ALL CI VALIDATION CHECKS PASSED")
$spaceErrMsg = IIf (-not $spaceSuccess) "Failed running test runner in path with spaces: Exit=$($p.ExitCode)" ""
Record-Result -Category "PathResilience" -TestName "Path with spaces: Project path containing spaces" `
    -Success $spaceSuccess -ExitCode $p.ExitCode -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Target: $spaceDir" `
    -ErrorOutput $spaceErrMsg

# 3.2 Path with Special Characters (#, @, !, &, ^, ())
$specialDir = Join-Path $tempBase "VR#Proj@2026!(Test)&Special^"
New-Item -ItemType Directory -Path $specialDir -Force | Out-Null
Copy-Item -Path "$vrProj\*" -Destination $specialDir -Recurse -Force | Out-Null

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$specialOut = Join-Path $tempBase "special_test.out"
$specialErr = Join-Path $tempBase "special_test.err"
$p = Start-Process -FilePath $godotCmd `
    -ArgumentList "--headless --path `"$specialDir`" -s res://test_runner.gd" `
    -RedirectStandardOutput $specialOut -RedirectStandardError $specialErr -PassThru -Wait
$sw.Stop()
$spOut = if (Test-Path $specialOut) { Get-Content $specialOut -Raw } else { "" }
$specialSuccess = ($p.ExitCode -eq 0) -and ($spOut -match "ALL CI VALIDATION CHECKS PASSED")
$specialErrMsg = IIf (-not $specialSuccess) "Failed in directory with special symbols: Exit=$($p.ExitCode)" ""
Record-Result -Category "PathResilience" -TestName "Special characters: Project path with #, @, !, &, ^, ()" `
    -Success $specialSuccess -ExitCode $p.ExitCode -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Target: $specialDir" `
    -ErrorOutput $specialErrMsg

# 3.3 Path with Vietnamese Unicode Diacritics
$unicodeDir = Join-Path $tempBase "DựÁn_VR_ThửNghiệm_TiếngViệt"
New-Item -ItemType Directory -Path $unicodeDir -Force | Out-Null
Copy-Item -Path "$vrProj\*" -Destination $unicodeDir -Recurse -Force | Out-Null

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$uOutFile = Join-Path $tempBase "unicode_test.out"
$uErrFile = Join-Path $tempBase "unicode_test.err"
$p = Start-Process -FilePath $godotCmd `
    -ArgumentList "--headless --path `"$unicodeDir`" -s res://test_runner.gd" `
    -RedirectStandardOutput $uOutFile -RedirectStandardError $uErrFile -PassThru -Wait
$sw.Stop()
$uOut = if (Test-Path $uOutFile) { Get-Content $uOutFile -Raw } else { "" }
$uSuccess = ($p.ExitCode -eq 0) -and ($uOut -match "ALL CI VALIDATION CHECKS PASSED")
$uErrMsg = IIf (-not $uSuccess) "Failed in Unicode path: Exit=$($p.ExitCode)" ""
Record-Result -Category "PathResilience" -TestName "Unicode diacritics: Path with Vietnamese characters" `
    -Success $uSuccess -ExitCode $p.ExitCode -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Target: $unicodeDir" `
    -ErrorOutput $uErrMsg

# 3.4 Directory Junction Navigation
$junctionPath = Join-Path $tempBase "vr_junction_link"
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$cmdJunction = cmd.exe /c "mklink /J `"$junctionPath`" `"$vrProj`""
$juncCreated = Test-Path -LiteralPath $junctionPath
$juncSuccess = $false
if ($juncCreated) {
    $jOutFile = Join-Path $tempBase "junc_test.out"
    $jErrFile = Join-Path $tempBase "junc_test.err"
    $p = Start-Process -FilePath $godotCmd `
        -ArgumentList "--headless --path `"$junctionPath`" -s res://test_runner.gd" `
        -RedirectStandardOutput $jOutFile -RedirectStandardError $jErrFile -PassThru -Wait
    $jOut = if (Test-Path $jOutFile) { Get-Content $jOutFile -Raw } else { "" }
    $juncSuccess = ($p.ExitCode -eq 0) -and ($jOut -match "ALL CI VALIDATION CHECKS PASSED")
}
$sw.Stop()
$juncExit = IIf $juncSuccess 0 1
$juncErrMsg = IIf (-not $juncSuccess) "Failed running project through junction: LinkCreated=$juncCreated" ""
Record-Result -Category "PathResilience" -TestName "NTFS Junction: Execution through directory link" `
    -Success $juncSuccess -ExitCode $juncExit -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Junction created: $junctionPath -> $vrProj" `
    -ErrorOutput $juncErrMsg

# 3.5 Deeply Nested Directory Structure (>150 chars)
$deepDir = Join-Path $tempBase "a\very\deeply\nested\hierarchy\created\to\stress\path\buffer\limits\and\long\paths\in\windows\engine\launchers"
New-Item -ItemType Directory -Path $deepDir -Force | Out-Null
Copy-Item -Path "$vrProj\*" -Destination $deepDir -Recurse -Force | Out-Null

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$deepOut = Join-Path $tempBase "deep_test.out"
$deepErr = Join-Path $tempBase "deep_test.err"
$p = Start-Process -FilePath $godotCmd `
    -ArgumentList "--headless --path `"$deepDir`" -s res://test_runner.gd" `
    -RedirectStandardOutput $deepOut -RedirectStandardError $deepErr -PassThru -Wait
$sw.Stop()
$dOut = if (Test-Path $deepOut) { Get-Content $deepOut -Raw } else { "" }
$deepSuccess = ($p.ExitCode -eq 0) -and ($dOut -match "ALL CI VALIDATION CHECKS PASSED")
$deepErrMsg = IIf (-not $deepSuccess) "Failed in deep directory: Exit=$($p.ExitCode)" ""
Record-Result -Category "PathResilience" -TestName "Deeply nested directory (>150 characters)" `
    -Success $deepSuccess -ExitCode $p.ExitCode -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Path length: $($deepDir.Length) characters" `
    -ErrorOutput $deepErrMsg

# 3.6 Check Script Resilience to Explicit ProjectRoot
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$chkSpaceOut = Join-Path $tempBase "chk_space.json"
$chkSpaceErr = Join-Path $tempBase "chk_space.err"
$p = Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$checkScript`" -ProjectRoot `"$ProjectRoot`" -SkipBuild -Json" `
    -RedirectStandardOutput $chkSpaceOut -RedirectStandardError $chkSpaceErr -PassThru -Wait
$sw.Stop()
$chkPass = ($p.ExitCode -eq 0)
$chkRootErr = IIf (-not $chkPass) "Failed with explicit root: Exit=$($p.ExitCode)" ""
Record-Result -Category "PathResilience" -TestName "check_environment.ps1 with explicit ProjectRoot" `
    -Success $chkPass -ExitCode $p.ExitCode -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Explicit ProjectRoot: $ProjectRoot" `
    -ErrorOutput $chkRootErr

# ------------------------------------------------------------------------------
# SECTION 4: PROCESS STABILITY, LEAKS, FILE LOCKS & RESOURCE MONITORING
# ------------------------------------------------------------------------------
Write-Host "`n--- SECTION 4: Process Stability, Leaks & File Locks ---" -ForegroundColor Magenta

# 4.1 Process Orphan / Leak Check
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$godotProcesses = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue
$sw.Stop()
$noLeakedGodot = ($null -eq $godotProcesses -or $godotProcesses.Count -eq 0)
$leakExit = IIf $noLeakedGodot 0 1
$leakErrMsg = IIf (-not $noLeakedGodot) "Found active lingering Godot processes: $($godotProcesses.Id -join ', ')" ""
Record-Result -Category "ProcessStability" -TestName "Process leak audit: No lingering Godot engine processes" `
    -Success $noLeakedGodot -ExitCode $leakExit -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Active Godot processes count: $(if ($godotProcesses) { $godotProcesses.Count } else { 0 })" `
    -ErrorOutput $leakErrMsg

# 4.2 File Lock Audit on Project Files
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$lockedFiles = @()
$criticalFiles = @(
    "$vrProj\project.godot",
    "$vrProj\main.gd",
    "$vrProj\test_runner.gd",
    "$webxrProj\package.json",
    "$webxrProj\src\main.js"
)
foreach ($file in $criticalFiles) {
    try {
        $stream = [System.IO.File]::Open($file, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
        $stream.Dispose()
    } catch {
        $lockedFiles += "$file ($($_.Exception.Message))"
    }
}
$sw.Stop()
$noLocks = ($lockedFiles.Count -eq 0)
$lockExit = IIf $noLocks 0 1
$lockErrMsg = $lockedFiles -join "; "
Record-Result -Category "ProcessStability" -TestName "File lock audit: Critical project source files are unlocked" `
    -Success $noLocks -ExitCode $lockExit -DurationMs $sw.Elapsed.TotalMilliseconds `
    -Details "Checked $( $criticalFiles.Count ) critical project files for exclusive locks" `
    -ErrorOutput $lockErrMsg

# 4.3 Clean up sandbox
Remove-Item -LiteralPath $tempBase -Recurse -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------------------------
# SUMMARY & OUTPUT
# ------------------------------------------------------------------------------
$totalDuration = (Get-Date) - $startTime
$totalTests = $results.Count
$passTests = ($results | Where-Object { $_.Success }).Count
$failTests = ($results | Where-Object { -not $_.Success }).Count

$failColor = IIf ($failTests -gt 0) "Red" "Green"

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "                  TIER 5 STRESS TEST SUITE EXECUTION SUMMARY                    " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Total Tests Run : $totalTests"
Write-Host "Passed          : $passTests" -ForegroundColor Green
Write-Host "Failed          : $failTests" -ForegroundColor $failColor
Write-Host "Total Duration  : $([Math]::Round($totalDuration.TotalSeconds, 2)) seconds"
Write-Host "================================================================================" -ForegroundColor Cyan

# Output JSON summary for automated reporting
$summaryJsonPath = "$ProjectRoot\tests\stress_tier5_results.json"
$results | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $summaryJsonPath -Encoding UTF8

if ($failTests -gt 0) {
    exit 1
} else {
    exit 0
}
