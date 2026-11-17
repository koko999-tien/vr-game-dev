# Challenger Tier 5-4 Adversarial Battery
$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " STARTING CHALLENGER TIER 5-4 ADVERSARIAL BATTERY" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$results = [ordered]@{}
$failedCount = 0

function Assert-Test([string]$name, [bool]$passed, [string]$details) {
    if ($passed) {
        Write-Host "  [PASS] $name" -ForegroundColor Green
        if ($details) { Write-Host "         $details" -ForegroundColor DarkGray }
        $script:results[$name] = @{ Status = "PASS"; Details = $details }
    } else {
        Write-Host "  [FAIL] $name" -ForegroundColor Red
        if ($details) { Write-Host "         $details" -ForegroundColor Yellow }
        $script:results[$name] = @{ Status = "FAIL"; Details = $details }
        $script:failedCount++
    }
}

function Invoke-ProcessRedirect([string]$exe, [string]$cmdArgs) {
    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $p = Start-Process -FilePath $exe -ArgumentList $cmdArgs `
            -RedirectStandardOutput $outFile -RedirectStandardError $errFile `
            -NoNewWindow -PassThru -Wait
        
        $stdout = if (Test-Path $outFile) { [System.IO.File]::ReadAllText($outFile) } else { "" }
        $stderr = if (Test-Path $errFile) { [System.IO.File]::ReadAllText($errFile) } else { "" }
        return [PSCustomObject]@{
            ExitCode = $p.ExitCode
            Stdout   = $stdout
            Stderr   = $stderr
        }
    } finally {
        if (Test-Path $outFile) { Remove-Item $outFile -Force -ErrorAction SilentlyContinue }
        if (Test-Path $errFile) { Remove-Item $errFile -Force -ErrorAction SilentlyContinue }
    }
}

$gitBash = "C:\Program Files\Git\bin\bash.exe"
if (-not (Test-Path $gitBash)) {
    $gitBash = (Get-Command bash.exe -ErrorAction SilentlyContinue).Source
}

# ====================================================================
# TEST GROUP 1: DEF-TIER5-01 RESOLUTION & BASH WRAPPER INTEGRITY
# ====================================================================
Write-Host "`n--- TEST GROUP 1: DEF-TIER5-01 RESOLUTION & BASH WRAPPER ---" -ForegroundColor Yellow

$bashPath1 = "D:\vr_game_dev\bin\godot"
$bashPath2 = "D:\bin\godot"

# 1.1 Check raw bytes of D:\vr_game_dev\bin\godot
$b1 = [System.IO.File]::ReadAllBytes($bashPath1)
$hex1 = ($b1[0..7] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
$noBom1 = ($b1[0] -eq 0x23 -and $b1[1] -eq 0x21 -and $b1[2] -eq 0x2F)
Assert-Test "1.1 D:\vr_game_dev\bin\godot First Bytes ($hex1)" $noBom1 "Expected 23 21 2F (#!/), got $hex1"

# 1.2 Check raw bytes of D:\bin\godot
$b2 = [System.IO.File]::ReadAllBytes($bashPath2)
$hex2 = ($b2[0..7] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
$noBom2 = ($b2[0] -eq 0x23 -and $b2[1] -eq 0x21 -and $b2[2] -eq 0x2F)
Assert-Test "1.2 D:\bin\godot First Bytes ($hex2)" $noBom2 "Expected 23 21 2F (#!/), got $hex2"

# 1.3 Check line endings (strictly POSIX LF, no CR)
$text1 = [System.IO.File]::ReadAllText($bashPath1)
$hasCr1 = $text1.Contains("`r")
Assert-Test "1.3 D:\vr_game_dev\bin\godot Line Endings (POSIX LF)" (-not $hasCr1) "CR characters present: $hasCr1"

$text2 = [System.IO.File]::ReadAllText($bashPath2)
$hasCr2 = $text2.Contains("`r")
Assert-Test "1.4 D:\bin\godot Line Endings (POSIX LF)" (-not $hasCr2) "CR characters present: $hasCr2"

# 1.5 Git Bash Execution with Process redirection
$resGitBash1 = Invoke-ProcessRedirect $gitBash '-c "/d/vr_game_dev/bin/godot --version"'
Assert-Test "1.5 Git Bash Absolute /d/vr_game_dev/bin/godot --version (0 stderr)" `
    ($resGitBash1.ExitCode -eq 0 -and $resGitBash1.Stderr.Length -eq 0 -and $resGitBash1.Stdout -match "4\.3\.stable") `
    "ExitCode: $($resGitBash1.ExitCode), StderrLen: $($resGitBash1.Stderr.Length), Out: $($resGitBash1.Stdout.Trim())"

$resGitBash2 = Invoke-ProcessRedirect $gitBash '-c "/d/bin/godot --version"'
Assert-Test "1.6 Git Bash Absolute /d/bin/godot --version (0 stderr)" `
    ($resGitBash2.ExitCode -eq 0 -and $resGitBash2.Stderr.Length -eq 0 -and $resGitBash2.Stdout -match "4\.3\.stable") `
    "ExitCode: $($resGitBash2.ExitCode), StderrLen: $($resGitBash2.Stderr.Length), Out: $($resGitBash2.Stdout.Trim())"

$resGitBash3 = Invoke-ProcessRedirect $gitBash '-c "godot --version"'
Assert-Test "1.7 Git Bash Naked godot --version on PATH (0 stderr)" `
    ($resGitBash3.ExitCode -eq 0 -and $resGitBash3.Stderr.Length -eq 0 -and $resGitBash3.Stdout -match "4\.3\.stable") `
    "ExitCode: $($resGitBash3.ExitCode), StderrLen: $($resGitBash3.Stderr.Length), Out: $($resGitBash3.Stdout.Trim())"

# 1.8 Git Bash complex argument forwarding with spaces and quotes
$resGitBash4 = Invoke-ProcessRedirect $gitBash '-c "/d/vr_game_dev/bin/godot --headless --path ''/d/vr_game_dev/projects/vr_hello_world'' -s res://test_runner.gd"'
Assert-Test "1.8 Git Bash Complex Arg Forwarding to Headless VR Test Runner" `
    ($resGitBash4.ExitCode -eq 0 -and $resGitBash4.Stdout -match "ALL CI VALIDATION CHECKS PASSED") `
    "ExitCode: $($resGitBash4.ExitCode), Match: $($resGitBash4.Stdout -match 'ALL CI VALIDATION CHECKS PASSED')"

# ====================================================================
# TEST GROUP 2: SETUP SCRIPT IDEMPOTENCY & NON-REGRESSION
# ====================================================================
Write-Host "`n--- TEST GROUP 2: SETUP_ENVIRONMENT.PS1 IDEMPOTENCY ---" -ForegroundColor Yellow

$setupScript = "D:\vr_game_dev\scripts\setup_environment.ps1"
$resSetup = Invoke-ProcessRedirect "powershell.exe" "-NoProfile -ExecutionPolicy Bypass -File `"$setupScript`" -SkipCheck"
Assert-Test "2.1 Run setup_environment.ps1 -SkipCheck (Exit code 0)" ($resSetup.ExitCode -eq 0) "ExitCode: $($resSetup.ExitCode)"

# Re-verify byte 0 is strictly 0x23 on both files after setup
$b1Post = [System.IO.File]::ReadAllBytes($bashPath1)
$b2Post = [System.IO.File]::ReadAllBytes($bashPath2)
Assert-Test "2.2 D:\vr_game_dev\bin\godot First Byte Post-Setup (0x23)" ($b1Post[0] -eq 0x23) "Byte 0: $('{0:X2}' -f $b1Post[0])"
Assert-Test "2.3 D:\bin\godot First Byte Post-Setup (0x23)" ($b2Post[0] -eq 0x23) "Byte 0: $('{0:X2}' -f $b2Post[0])"

# Re-run Git Bash test to guarantee no regression after setup
$resGitBashPost = Invoke-ProcessRedirect $gitBash '-c "godot --version"'
Assert-Test "2.4 Git Bash Clean Execution Post-Setup (0 stderr)" `
    ($resGitBashPost.ExitCode -eq 0 -and $resGitBashPost.Stderr.Length -eq 0) `
    "ExitCode: $($resGitBashPost.ExitCode), Stderr: '$($resGitBashPost.Stderr)'"

# ====================================================================
# TEST GROUP 3: CROSS-SHELL FIDELITY (CMD, POWERSHELL, GIT BASH)
# ====================================================================
Write-Host "`n--- TEST GROUP 3: CROSS-SHELL FIDELITY ---" -ForegroundColor Yellow

# CMD direct and via PATH
$resCmd1 = Invoke-ProcessRedirect "cmd.exe" "/c D:\vr_game_dev\bin\godot.cmd --version"
Assert-Test "3.1 cmd.exe Direct godot.cmd --version" ($resCmd1.ExitCode -eq 0 -and $resCmd1.Stdout -match "4\.3\.stable") "ExitCode: $($resCmd1.ExitCode)"

$resCmd2 = Invoke-ProcessRedirect "cmd.exe" "/c godot --version"
Assert-Test "3.2 cmd.exe Naked godot --version on PATH" ($resCmd2.ExitCode -eq 0 -and $resCmd2.Stdout -match "4\.3\.stable") "ExitCode: $($resCmd2.ExitCode)"

# PowerShell direct and via PATH
$resPs1 = Invoke-ProcessRedirect "powershell.exe" "-NoProfile -ExecutionPolicy Bypass -File D:\vr_game_dev\bin\godot.ps1 --version"
Assert-Test "3.3 PowerShell Direct godot.ps1 --version" ($resPs1.ExitCode -eq 0 -and $resPs1.Stdout -match "4\.3\.stable") "ExitCode: $($resPs1.ExitCode)"

$resPs2 = Invoke-ProcessRedirect "powershell.exe" "-NoProfile -Command godot --version"
Assert-Test "3.4 PowerShell Naked godot --version" ($resPs2.ExitCode -eq 0 -and $resPs2.Stdout -match "4\.3\.stable") "ExitCode: $($resPs2.ExitCode)"

# Test error code propagation across all three shells
$resCmdErr = Invoke-ProcessRedirect "cmd.exe" "/c godot --headless -s res://non_existent_script.gd"
Assert-Test "3.5 cmd.exe Propagates Non-Zero Exit Code on Failure" ($resCmdErr.ExitCode -ne 0) "ExitCode: $($resCmdErr.ExitCode)"

$resPsErr = Invoke-ProcessRedirect "powershell.exe" "-NoProfile -Command `"`$output = & D:\vr_game_dev\bin\godot.cmd --headless -s res://non_existent_script.gd; exit `$LASTEXITCODE`""
Assert-Test "3.6 PowerShell Propagates Non-Zero Exit Code on Failure" ($resPsErr.ExitCode -ne 0) "ExitCode: $($resPsErr.ExitCode)"

$resBashErr = Invoke-ProcessRedirect $gitBash '-c "godot --headless -s res://non_existent_script.gd"'
Assert-Test "3.7 Git Bash Propagates Non-Zero Exit Code on Failure" ($resBashErr.ExitCode -ne 0) "ExitCode: $($resBashErr.ExitCode)"

# ====================================================================
# TEST GROUP 4: CONCURRENCY & BURST PROCESS STRESS TESTING
# ====================================================================
Write-Host "`n--- TEST GROUP 4: CONCURRENCY & BURST STRESS ---" -ForegroundColor Yellow

# 4.1 Burst 12 parallel godot.cmd executions
Write-Host "  Spawning 12 parallel godot.cmd processes..."
$burstCount = 12
$burstProcs = @()
$burstSw = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 0; $i -lt $burstCount; $i++) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "D:\vr_game_dev\bin\godot.cmd"
    $psi.Arguments = "--version"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $burstProcs += [System.Diagnostics.Process]::Start($psi)
}

$burstSuccess = 0
for ($i = 0; $i -lt $burstCount; $i++) {
    $p = $burstProcs[$i]
    $out = $p.StandardOutput.ReadToEnd()
    $err = $p.StandardError.ReadToEnd()
    $p.WaitForExit(10000)
    if ($p.ExitCode -eq 0 -and $out -match "4\.3\.stable") {
        $burstSuccess++
    }
}
$burstSw.Stop()
Assert-Test "4.1 Burst 12 Concurrent godot.cmd Invocations ($burstSuccess/$burstCount in $($burstSw.ElapsedMilliseconds)ms)" `
    ($burstSuccess -eq $burstCount) "Passed: $burstSuccess/$burstCount"

# 4.2 Burst 6 parallel Godot headless test runners on vr_hello_world
Write-Host "  Spawning 6 parallel Godot headless test runners on vr_hello_world..."
$vrRunnerCount = 6
$vrProcs = @()
$vrSw = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 0; $i -lt $vrRunnerCount; $i++) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "D:\vr_game_dev\bin\godot.cmd"
    $psi.Arguments = "--headless --path `"D:\vr_game_dev\projects\vr_hello_world`" -s res://test_runner.gd"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $vrProcs += [System.Diagnostics.Process]::Start($psi)
}

$vrSuccess = 0
for ($i = 0; $i -lt $vrRunnerCount; $i++) {
    $p = $vrProcs[$i]
    $out = $p.StandardOutput.ReadToEnd()
    $err = $p.StandardError.ReadToEnd()
    $p.WaitForExit(20000)
    if ($p.ExitCode -eq 0 -and $out -match "ALL CI VALIDATION CHECKS PASSED") {
        $vrSuccess++
    }
}
$vrSw.Stop()
Assert-Test "4.2 Concurrent 6 Headless VR Test Runners ($vrSuccess/$vrRunnerCount in $($vrSw.ElapsedMilliseconds)ms)" `
    ($vrSuccess -eq $vrRunnerCount) "Passed: $vrSuccess/$vrRunnerCount"

# 4.3 Check lingering Godot processes
$lingering = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue
Assert-Test "4.3 Process Isolation: Zero Lingering Godot Processes" `
    (($null -eq $lingering) -or ($lingering.Count -eq 0)) `
    "Lingering process count: $(if ($lingering) { $lingering.Count } else { 0 })"

# 4.4 Concurrent WebXR Build + Godot VR Test Runner Interleaving
Write-Host "  Testing concurrent WebXR Build + Godot VR Test Runner interleaving..."
$webxrDir = "D:\vr_game_dev\projects\webxr_hello_world"
$psiNpm = New-Object System.Diagnostics.ProcessStartInfo
$psiNpm.FileName = "cmd.exe"
$psiNpm.Arguments = "/c npm run build"
$psiNpm.WorkingDirectory = $webxrDir
$psiNpm.UseShellExecute = $false
$psiNpm.RedirectStandardOutput = $true
$psiNpm.RedirectStandardError = $true
$psiNpm.CreateNoWindow = $true

$psiGodot = New-Object System.Diagnostics.ProcessStartInfo
$psiGodot.FileName = "D:\vr_game_dev\bin\godot.cmd"
$psiGodot.Arguments = "--headless --path `"D:\vr_game_dev\projects\vr_hello_world`" -s res://test_runner.gd"
$psiGodot.UseShellExecute = $false
$psiGodot.RedirectStandardOutput = $true
$psiGodot.RedirectStandardError = $true
$psiGodot.CreateNoWindow = $true

$pNpm = [System.Diagnostics.Process]::Start($psiNpm)
$pGodot = [System.Diagnostics.Process]::Start($psiGodot)

$npmOut = $pNpm.StandardOutput.ReadToEnd()
$pNpm.WaitForExit(30000)

$godotOut = $pGodot.StandardOutput.ReadToEnd()
$pGodot.WaitForExit(20000)

Assert-Test "4.4 Concurrent Interleaved WebXR Build & Godot VR Execution" `
    ($pNpm.ExitCode -eq 0 -and $pGodot.ExitCode -eq 0 -and $godotOut -match "ALL CI VALIDATION CHECKS PASSED") `
    "NpmCode: $($pNpm.ExitCode), GodotCode: $($pGodot.ExitCode)"

# ====================================================================
# TEST GROUP 5: SYSTEM HEALTH CHECK INTEGRITY
# ====================================================================
Write-Host "`n--- TEST GROUP 5: ENVIRONMENT HEALTH CHECK ---" -ForegroundColor Yellow

$healthScript = "D:\vr_game_dev\scripts\check_environment.ps1"
$resHealth = Invoke-ProcessRedirect "powershell.exe" "-NoProfile -ExecutionPolicy Bypass -File `"$healthScript`" -SkipBuild"
Assert-Test "5.1 check_environment.ps1 -SkipBuild Returns Code 0" ($resHealth.ExitCode -eq 0) "ExitCode: $($resHealth.ExitCode)"

$resHealthJson = Invoke-ProcessRedirect "powershell.exe" "-NoProfile -ExecutionPolicy Bypass -File `"$healthScript`" -Json -SkipBuild"
$jsonParsed = $false
try {
    $parsed = $resHealthJson.Stdout | ConvertFrom-Json
    if ($parsed -and $parsed.summary.overall_status -in @("HEALTHY", "WARNING")) {
        $jsonParsed = $true
    }
} catch {
    $jsonParsed = $false
}
Assert-Test "5.2 check_environment.ps1 -Json Outputs Valid Schema" ($jsonParsed -and $resHealthJson.ExitCode -eq 0) `
    "ExitCode: $($resHealthJson.ExitCode), Overall: $(if ($parsed) { $parsed.summary.overall_status } else { 'unparsed' })"

# ====================================================================
# SUMMARY
# ====================================================================
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " CHALLENGER BATTERY COMPLETE: $failedCount Failures" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host " Total Tests: $($results.Count) | Passed: $($results.Count - $failedCount) | Failed: $failedCount" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    exit 1
} else {
    exit 0
}
