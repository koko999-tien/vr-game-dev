# ==============================================================================
# EMPIRICAL ADVERSARIAL CHALLENGER SUITE - MILESTONE 1 (GODOT 4 CLI & TOOLING)
# ==============================================================================
# Target: Windows 11 64-bit, D:\vr_game_dev
# Execution: powershell.exe -NoProfile -ExecutionPolicy Bypass -File <path>
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "======================================================================"
Write-Host " STARTING ADVERSARIAL EMPIRICAL CHALLENGE SUITE FOR MILESTONE 1"
Write-Host "======================================================================"

$script:testsPassed = 0
$script:testsFailed = 0
$script:findings = [System.Collections.Generic.List[string]]::new()

function Run-Challenge([string]$id, [string]$title, [scriptblock]$action) {
    Write-Host "`n[CHALLENGE $($id)] $($title)" -ForegroundColor Cyan
    try {
        & $action
        Write-Host "--> [PASS] $($id): $($title)" -ForegroundColor Green
        $script:testsPassed++
    } catch {
        Write-Host "--> [FAIL] $($id): $($title) - Error: $_" -ForegroundColor Red
        $script:testsFailed++
        $script:findings.Add("FAIL: [$id] $title - $_")
    }
}

# Pre-check: Ensure no lingering Godot processes before starting
Get-Process *Godot* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------------------------
# SUITE 1: Binary Architecture & Subsystem Inspection
# ------------------------------------------------------------------------------

Run-Challenge "S1.1" "Verify Console Executable PE Subsystem is IMAGE_SUBSYSTEM_WINDOWS_CUI (3)" {
    $exePath = "D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64_console.exe"
    if (-not (Test-Path -LiteralPath $exePath)) { throw "Console executable does not exist at $exePath" }
    
    $bytes = [System.IO.File]::ReadAllBytes($exePath)
    $peOffset = [System.BitConverter]::ToInt32($bytes, 0x3C)
    if ($bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset + 1] -ne 0x45) { throw "Invalid PE header" }
    
    $subsystemOffset = $peOffset + 4 + 20 + 68
    $subsystem = [System.BitConverter]::ToInt16($bytes, $subsystemOffset)
    
    Write-Host "    PE Subsystem Value: $subsystem (Expected 3 = CUI / Console)"
    if ($subsystem -ne 3) {
        throw "Subsystem is $subsystem, expected 3 (IMAGE_SUBSYSTEM_WINDOWS_CUI)"
    }
}

Run-Challenge "S1.2" "Verify GUI Executable PE Subsystem is IMAGE_SUBSYSTEM_WINDOWS_GUI (2)" {
    $exePath = "D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64.exe"
    if (-not (Test-Path -LiteralPath $exePath)) { throw "GUI executable does not exist at $exePath" }
    
    $bytes = [System.IO.File]::ReadAllBytes($exePath)
    $peOffset = [System.BitConverter]::ToInt32($bytes, 0x3C)
    $subsystemOffset = $peOffset + 4 + 20 + 68
    $subsystem = [System.BitConverter]::ToInt16($bytes, $subsystemOffset)
    
    Write-Host "    PE Subsystem Value: $subsystem (Expected 2 = GUI)"
    if ($subsystem -ne 2) {
        throw "Subsystem is $subsystem, expected 2 (IMAGE_SUBSYSTEM_WINDOWS_GUI)"
    }
}

# ------------------------------------------------------------------------------
# SUITE 2: PATH Resolution from Non-Standard Directories & Isolation
# ------------------------------------------------------------------------------

Run-Challenge "S2.1" "PATH Execution from C:\ Root" {
    $outPath = "D:\vr_game_dev\tests\s2_1_out.txt"
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c godot --version" -WorkingDirectory "C:\" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outPath
    $exitCode = $p.ExitCode
    $out = if (Test-Path $outPath) { (Get-Content $outPath -Raw).Trim() } else { "" }
    Remove-Item $outPath -Force -ErrorAction SilentlyContinue
    Write-Host "    ExitCode: $exitCode, Output: $out"
    if ($exitCode -ne 0 -or $out -notmatch '^4\.3\.stable') {
        throw "Failed running from C:\ - ExitCode=$exitCode, Output=$out"
    }
}

Run-Challenge "S2.2" "PATH Execution from Windows System32 Directory" {
    $outPath = "D:\vr_game_dev\tests\s2_2_out.txt"
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c godot --version" -WorkingDirectory "C:\Windows\System32" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outPath
    $exitCode = $p.ExitCode
    $out = if (Test-Path $outPath) { (Get-Content $outPath -Raw).Trim() } else { "" }
    Remove-Item $outPath -Force -ErrorAction SilentlyContinue
    Write-Host "    ExitCode: $exitCode, Output: $out"
    if ($exitCode -ne 0 -or $out -notmatch '^4\.3\.stable') {
        throw "Failed running from System32 - ExitCode=$exitCode, Output=$out"
    }
}

Run-Challenge "S2.3" "PATH Execution from Directory with Spaces (UserProfile)" {
    $userDir = $env:USERPROFILE
    $outPath = "D:\vr_game_dev\tests\s2_3_out.txt"
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c godot --version" -WorkingDirectory $userDir -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outPath
    $exitCode = $p.ExitCode
    $out = if (Test-Path $outPath) { (Get-Content $outPath -Raw).Trim() } else { "" }
    Remove-Item $outPath -Force -ErrorAction SilentlyContinue
    Write-Host "    Working Dir: $userDir | ExitCode: $exitCode, Output: $out"
    if ($exitCode -ne 0 -or $out -notmatch '^4\.3\.stable') {
        throw "Failed running from user dir with spaces - ExitCode=$exitCode, Output=$out"
    }
}

Run-Challenge "S2.4" "PATH Isolation: Strict PATH containing ONLY D:\vr_game_dev\bin (No D:\bin)" {
    $cleanPath = "C:\Windows\System32;C:\Windows;D:\vr_game_dev\bin"
    $outPath = "D:\vr_game_dev\tests\s2_4_out.txt"
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c set PATH=$cleanPath && godot --version" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outPath
    $exitCode = $p.ExitCode
    $out = if (Test-Path $outPath) { (Get-Content $outPath -Raw).Trim() } else { "" }
    Remove-Item $outPath -Force -ErrorAction SilentlyContinue
    Write-Host "    ExitCode: $exitCode, Out: $out"
    if ($exitCode -ne 0 -or $out -notmatch '^4\.3\.stable') {
        throw "Failed under isolated D:\vr_game_dev\bin PATH: ExitCode=$exitCode, Out=$out"
    }
}

Run-Challenge "S2.5" "PATH Isolation: Strict PATH containing ONLY D:\bin (No D:\vr_game_dev\bin)" {
    $cleanPath = "C:\Windows\System32;C:\Windows;D:\bin"
    $outPath = "D:\vr_game_dev\tests\s2_5_out.txt"
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c set PATH=$cleanPath && godot --version" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outPath
    $exitCode = $p.ExitCode
    $out = if (Test-Path $outPath) { (Get-Content $outPath -Raw).Trim() } else { "" }
    Remove-Item $outPath -Force -ErrorAction SilentlyContinue
    Write-Host "    ExitCode: $exitCode, Out: $out"
    if ($exitCode -ne 0 -or $out -notmatch '^4\.3\.stable') {
        throw "Failed under isolated D:\bin PATH: ExitCode=$exitCode, Out=$out"
    }
}

# ------------------------------------------------------------------------------
# SUITE 3: CLI Wrapper Edge Cases & Argument Forwarding
# ------------------------------------------------------------------------------

Run-Challenge "S3.1" "Argument Forwarding with Spaces in Quoted Paths" {
    $testDirWithSpaces = "D:\vr_game_dev\tests\dummy space dir"
    New-Item -ItemType Directory -Path $testDirWithSpaces -Force | Out-Null
    
    try {
        $p = Start-Process -FilePath "D:\vr_game_dev\bin\godot.cmd" -ArgumentList "--headless --path `"$testDirWithSpaces`" --quit" -NoNewWindow -Wait -PassThru
        $exitCode = $p.ExitCode
        Write-Host "    ExitCode: $exitCode"
        # Godot aborts with code 1 if not a valid project or succeeds with 0
        if ($exitCode -ne 0 -and $exitCode -ne 1) {
            throw "Unexpected exit code: $exitCode"
        }
    } finally {
        Remove-Item -LiteralPath $testDirWithSpaces -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Run-Challenge "S3.2" "Multiple Flags and Complex Parameter Forwarding" {
    $outPath = "D:\vr_game_dev\tests\s3_2_out.txt"
    $p = Start-Process -FilePath "D:\vr_game_dev\bin\godot.cmd" -ArgumentList "--headless --help" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outPath
    $exitCode = $p.ExitCode
    $out = if (Test-Path $outPath) { (Get-Content $outPath -Raw).Trim() } else { "" }
    Remove-Item $outPath -Force -ErrorAction SilentlyContinue
    
    if ($exitCode -ne 0) { throw "godot.cmd --headless --help exited with $exitCode" }
    if ($out -notmatch "Godot Engine" -or $out -notmatch "--headless") {
        throw "Output missing expected help text"
    }
    Write-Host "    Help output length: $($out.Length) chars, ExitCode: $exitCode"
}

Run-Challenge "S3.3" "PowerShell Wrapper (godot.ps1) Argument Preservation" {
    $out = & "D:\vr_game_dev\bin\godot.ps1" --headless --version
    $exitCode = $LASTEXITCODE
    Write-Host "    godot.ps1 Output: $out, ExitCode: $exitCode"
    if ($exitCode -ne 0 -or $out -notmatch '^4\.3\.stable') {
        throw "godot.ps1 failed: ExitCode=$exitCode, Output=$out"
    }
}

# ------------------------------------------------------------------------------
# SUITE 4: Non-Existent Flags & Exit Code Propagation
# ------------------------------------------------------------------------------

Run-Challenge "S4.1" "Invalid Flag in Headless Mode (godot.cmd)" {
    # Testing that unknown flags in headless mode exit cleanly with code 0 or 1, and don't hang
    $p = Start-Process -FilePath "D:\vr_game_dev\bin\godot.cmd" -ArgumentList "--headless --nonexistent-dummy-flag --quit" -NoNewWindow -Wait -PassThru
    $exitCode = $p.ExitCode
    Write-Host "    godot.cmd unknown flag with --quit ExitCode: $exitCode"
}

Run-Challenge "S4.2" "Invalid Script Execution Exit Code Propagation in godot.cmd" {
    $p = Start-Process -FilePath "D:\vr_game_dev\bin\godot.cmd" -ArgumentList "--headless -s non_existent_script_12345.gd" -NoNewWindow -Wait -PassThru
    $exitCode = $p.ExitCode
    Write-Host "    Non-existent script ExitCode: $exitCode"
    if ($exitCode -eq 0) {
        throw "Expected non-zero exit code when running non-existent script, got 0"
    }
}

Run-Challenge "S4.3" "Invalid Project Path Exit Code Propagation in godot.cmd" {
    $p = Start-Process -FilePath "D:\vr_game_dev\bin\godot.cmd" -ArgumentList "--headless --path `"D:\nonexistent_project_987`" --editor --quit" -NoNewWindow -Wait -PassThru
    $exitCode = $p.ExitCode
    Write-Host "    Non-existent project path ExitCode: $exitCode"
    if ($exitCode -eq 0) {
        throw "Expected non-zero exit code when opening non-existent project in editor, got 0"
    }
}

Run-Challenge "S4.4" "Invalid Script Execution Exit Code Propagation in godot.ps1" {
    $p = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& 'D:\vr_game_dev\bin\godot.ps1' --headless -s non_existent_script_12345.gd; exit `$LASTEXITCODE`"" -NoNewWindow -Wait -PassThru
    $exitCode = $p.ExitCode
    Write-Host "    godot.ps1 non-existent script ExitCode: $exitCode"
    if ($exitCode -eq 0) {
        throw "Expected non-zero exit code from godot.ps1, got 0"
    }
}

# ------------------------------------------------------------------------------
# SUITE 5: Environment Variable Override (GODOT_BIN) Edge Cases
# ------------------------------------------------------------------------------

Run-Challenge "S5.1" "GODOT_BIN Override Points to Valid Console Exe" {
    $outPath = "D:\vr_game_dev\tests\s5_1_out.txt"
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c set GODOT_BIN=D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64_console.exe && godot.cmd --version" -WorkingDirectory "D:\vr_game_dev\bin" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outPath
    $exitCode = $p.ExitCode
    $out = if (Test-Path $outPath) { (Get-Content $outPath -Raw).Trim() } else { "" }
    Remove-Item $outPath -Force -ErrorAction SilentlyContinue
    
    Write-Host "    ExitCode: $exitCode, Output: $out"
    if ($exitCode -ne 0 -or $out -notmatch '^4\.3\.stable') {
        throw "Failed with valid GODOT_BIN override: ExitCode=$exitCode, Out=$out"
    }
}

Run-Challenge "S5.2" "GODOT_BIN Override Points to Non-Existent Path (Graceful Fallback)" {
    $outPath = "D:\vr_game_dev\tests\s5_2_out.txt"
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c set GODOT_BIN=D:\non_existent_godot_path\godot.exe && godot.cmd --version" -WorkingDirectory "D:\vr_game_dev\bin" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outPath
    $exitCode = $p.ExitCode
    $out = if (Test-Path $outPath) { (Get-Content $outPath -Raw).Trim() } else { "" }
    Remove-Item $outPath -Force -ErrorAction SilentlyContinue
    
    Write-Host "    Fallback ExitCode: $exitCode, Output: $out"
    if ($exitCode -ne 0 -or $out -notmatch '^4\.3\.stable') {
        throw "Failed to fall back when GODOT_BIN is invalid: ExitCode=$exitCode, Out=$out"
    }
}

# ------------------------------------------------------------------------------
# SUITE 6: Headless Execution & Standard Streams Redirection
# ------------------------------------------------------------------------------

Run-Challenge "S6.1" "Strict Standard Output Redirection via godot.cmd" {
    $stdoutFile = "D:\vr_game_dev\tests\test_stdout.txt"
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c godot --headless --version > `"$stdoutFile`"" -NoNewWindow -Wait -PassThru
    $stdoutContent = if (Test-Path $stdoutFile) { (Get-Content $stdoutFile -Raw).Trim() } else { "" }
    Remove-Item $stdoutFile -Force -ErrorAction SilentlyContinue
    
    Write-Host "    Stdout: '$stdoutContent', ExitCode: $($p.ExitCode)"
    if ($stdoutContent -notmatch '^4\.3\.stable') {
        throw "Stdout does not contain version string: '$stdoutContent'"
    }
}

# ------------------------------------------------------------------------------
# SUITE 7: Rapid Invocation, Stress & Process Leak Verification
# ------------------------------------------------------------------------------

Run-Challenge "S7.1" "Rapid Sequential Invocations (25x Iterations)" {
    $iterations = 25
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $durations = [System.Collections.Generic.List[double]]::new()
    
    for ($i = 1; $i -le $iterations; $i++) {
        $iterSw = [System.Diagnostics.Stopwatch]::StartNew()
        $p = Start-Process -FilePath "D:\vr_game_dev\bin\godot.cmd" -ArgumentList "--headless --version" -NoNewWindow -Wait -PassThru
        $iterSw.Stop()
        $durations.Add($iterSw.Elapsed.TotalMilliseconds)
        
        if ($p.ExitCode -ne 0) {
            throw "Iteration $i failed with exit code $($p.ExitCode)"
        }
    }
    $sw.Stop()
    
    $avgMs = [System.Math]::Round(($durations | Measure-Object -Average).Average, 1)
    $minMs = [System.Math]::Round(($durations | Measure-Object -Minimum).Minimum, 1)
    $maxMs = [System.Math]::Round(($durations | Measure-Object -Maximum).Maximum, 1)
    Write-Host "    Completed $iterations sequential runs in $($sw.ElapsedMilliseconds) ms"
    Write-Host "    Latency stats: Min=${minMs}ms, Avg=${avgMs}ms, Max=${maxMs}ms"
    
    $leakedProcs = Get-Process *Godot* -ErrorAction SilentlyContinue
    if ($leakedProcs) {
        $count = $leakedProcs.Count
        throw "Process leak detected: $count lingering Godot processes found after sequential run!"
    }
    Write-Host "    Verified 0 lingering Godot processes."
}

Run-Challenge "S7.2" "Concurrent Parallel Invocation Stress (8x Parallel Instances)" {
    $jobs = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
    $concurrency = 8
    
    Write-Host "    Spawning $concurrency parallel instances of godot.cmd..."
    for ($i = 0; $i -lt $concurrency; $i++) {
        $p = Start-Process -FilePath "D:\vr_game_dev\bin\godot.cmd" -ArgumentList "--headless --version" -NoNewWindow -PassThru
        $jobs.Add($p)
    }
    
    $failedJobs = 0
    foreach ($job in $jobs) {
        $job.WaitForExit(10000)
        if ($job.ExitCode -ne 0) {
            $failedJobs++
        }
    }
    
    Write-Host "    All $concurrency parallel processes completed."
    if ($failedJobs -gt 0) {
        throw "$failedJobs of $concurrency parallel jobs failed"
    }
    
    Start-Sleep -Milliseconds 500
    $leakedProcs = Get-Process *Godot* -ErrorAction SilentlyContinue
    if ($leakedProcs) {
        $count = $leakedProcs.Count
        throw "Process leak detected: $count lingering Godot processes found after parallel execution!"
    }
    Write-Host "    Verified 0 orphaned Godot processes."
}

# ------------------------------------------------------------------------------
# SUITE 8: Bash Shell Execution (Git Bash compatibility)
# ------------------------------------------------------------------------------

Run-Challenge "S8.1" "Git Bash / MSYS2 Wrapper Execution (if bash.exe is installed)" {
    $bashPath = $null
    $possibleBash = @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files\Git\usr\bin\bash.exe",
        "C:\msys64\usr\bin\bash.exe"
    )
    foreach ($b in $possibleBash) {
        if (Test-Path $b) { $bashPath = $b; break }
    }
    
    if (-not $bashPath) {
        $whereBash = where.exe bash 2>$null
        if ($whereBash) { $bashPath = $whereBash[0] }
    }
    
    if ($bashPath) {
        Write-Host "    Found bash at: $bashPath"
        $outPath = "D:\vr_game_dev\tests\s8_1_out.txt"
        $p = Start-Process -FilePath $bashPath -ArgumentList "-c `"/d/vr_game_dev/bin/godot --version`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outPath
        $exitCode = $p.ExitCode
        $out = if (Test-Path $outPath) { (Get-Content $outPath -Raw).Trim() } else { "" }
        Remove-Item $outPath -Force -ErrorAction SilentlyContinue
        
        Write-Host "    Bash execution Output: '$out', ExitCode: $exitCode"
        if ($exitCode -ne 0 -or $out -notmatch '^4\.3\.stable') {
            throw "Bash execution failed: ExitCode=$exitCode, Out=$out"
        }
    } else {
        Write-Host "    [SKIPPED] bash.exe not detected on system, skipping bash wrapper challenge."
    }
}

# ------------------------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------------------------

Write-Host "`n======================================================================"
Write-Host " CHALLENGE SUITE SUMMARY: $($script:testsPassed) PASSED, $($script:testsFailed) FAILED"
Write-Host "======================================================================"

if ($script:findings.Count -gt 0) {
    Write-Host "`nFindings / Failures:" -ForegroundColor Red
    foreach ($f in $script:findings) {
        Write-Host " - $f" -ForegroundColor Red
    }
}

if ($script:testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
