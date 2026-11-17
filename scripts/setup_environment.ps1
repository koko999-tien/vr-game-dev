<#
.SYNOPSIS
    VR Game Development Environment Setup & Automated Recovery Script
.DESCRIPTION
    Fully automated provisioning and self-healing recovery script for Windows:
      1. Initializes project directory layout under D:\vr_game_dev
      2. Downloads and extracts Godot Engine 4.3 Stable Win64 portable if missing
      3. Deploys CLI wrappers (godot.cmd, godot.ps1, godot) to D:\vr_game_dev\bin and D:\bin
      4. Configures User PATH in HKCU:\Environment\Path (REG_EXPAND_SZ) with broadcast notification
      5. Restores WebXR project dependencies via npm install
      6. Pre-initializes Godot VR sample import cache via --editor --quit
      7. Invokes check_environment.ps1 to verify 100% operational readiness
.PARAMETER GodotVersion
    Official Godot release version tag (Default: "4.3-stable").
.PARAMETER InstallRoot
    Root installation directory (Default: "D:\vr_game_dev").
.PARAMETER Force
    Forces re-download of engine binaries and re-installation even if already present.
.PARAMETER SkipCheck
    Skips final health-check script invocation.
#>
[CmdletBinding()]
param(
    [string]$GodotVersion = "4.3-stable",
    [string]$InstallRoot = "D:\vr_game_dev",
    [switch]$Force,
    [switch]$SkipCheck
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "       VR GAME DEV ENVIRONMENT SETUP & PROVISIONING (WINDOWS 64-BIT)            " -ForegroundColor Cyan
Write-Host "================================================================================`n" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. Directory Structure Initialization
# ------------------------------------------------------------------------------
Write-Host "[1/6] Creating directory layout under $InstallRoot..." -ForegroundColor Yellow
$toolsDir     = Join-Path $InstallRoot "tools\godot"
$downloadsDir = Join-Path $InstallRoot "tools\downloads"
$binDir       = Join-Path $InstallRoot "bin"
$scriptsDir   = Join-Path $InstallRoot "scripts"
$docsDir      = Join-Path $InstallRoot "docs"
$sysBinDir    = "D:\bin"

$targetDirs = @($toolsDir, $downloadsDir, $binDir, $scriptsDir, $docsDir, $sysBinDir)
foreach ($dir in $targetDirs) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  + Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  . Exists:  $dir" -ForegroundColor Gray
    }
}

# ------------------------------------------------------------------------------
# 2. Godot Engine 4.3 Stable Acquisition
# ------------------------------------------------------------------------------
Write-Host "`n[2/6] Verifying Godot Engine ($GodotVersion)..." -ForegroundColor Yellow
$godotConsoleExe = Join-Path $toolsDir "Godot_v$($GodotVersion)_win64_console.exe"
$godotGuiExe     = Join-Path $toolsDir "Godot_v$($GodotVersion)_win64.exe"
$godotZipName    = "Godot_v$($GodotVersion)_win64.exe.zip"
$godotZipPath    = Join-Path $downloadsDir $godotZipName
$godotUrl        = "https://github.com/godotengine/godot/releases/download/$GodotVersion/$godotZipName"

$needDownload = $Force -or (-not (Test-Path -LiteralPath $godotConsoleExe))

if ($needDownload) {
    Write-Host "  Downloading Godot $GodotVersion archive..." -ForegroundColor Cyan
    Write-Host "  URL: $godotUrl" -ForegroundColor Gray
    
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
    Invoke-WebRequest -Uri $godotUrl -OutFile $godotZipPath -UseBasicParsing
    Write-Host "  Downloaded: $godotZipPath" -ForegroundColor Green

    Write-Host "  Extracting to $toolsDir..." -ForegroundColor Cyan
    Expand-Archive -Path $godotZipPath -DestinationPath $toolsDir -Force
    Write-Host "  Extraction complete." -ForegroundColor Green
} else {
    Write-Host "  Godot 4.3 executables already present in $toolsDir." -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 3. CLI Wrapper Deployment to D:\vr_game_dev\bin and D:\bin
# ------------------------------------------------------------------------------
Write-Host "`n[3/6] Deploying CLI launchers and wrappers..." -ForegroundColor Yellow

$cmdWrapperContent = @'
@echo off
setlocal

:: -----------------------------------------------------------------------------
:: Godot 4 CLI Launcher for Windows
:: Targets Godot_v4.3-stable_win64_console.exe for terminal I/O and exit codes
:: -----------------------------------------------------------------------------

:: 1. Check explicit environment variable override
if defined GODOT_BIN (
    if exist "%GODOT_BIN%" (
        set "TARGET_EXE=%GODOT_BIN%"
        goto :execute
    )
)

:: 2. Check relative path when placed in D:\vr_game_dev\bin\
set "CANDIDATE_REL=%~dp0..\tools\godot\Godot_v4.3-stable_win64_console.exe"
if exist "%CANDIDATE_REL%" (
    set "TARGET_EXE=%CANDIDATE_REL%"
    goto :execute
)

:: 3. Check relative path when placed in D:\bin\
set "CANDIDATE_SIBLING=%~dp0..\vr_game_dev\tools\godot\Godot_v4.3-stable_win64_console.exe"
if exist "%CANDIDATE_SIBLING%" (
    set "TARGET_EXE=%CANDIDATE_SIBLING%"
    goto :execute
)

:: 4. Check canonical absolute path
set "CANDIDATE_CANONICAL=D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64_console.exe"
if exist "%CANDIDATE_CANONICAL%" (
    set "TARGET_EXE=%CANDIDATE_CANONICAL%"
    goto :execute
)

:: 5. Fallback: check non-console GUI executable if console binary is missing
set "CANDIDATE_GUI=D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64.exe"
if exist "%CANDIDATE_GUI%" (
    set "TARGET_EXE=%CANDIDATE_GUI%"
    goto :execute
)

:: Error reporting
echo [ERROR] Godot executable could not be found! >&2
echo Checked locations: >&2
echo   - %CANDIDATE_REL% >&2
echo   - %CANDIDATE_SIBLING% >&2
echo   - %CANDIDATE_CANONICAL% >&2
echo Please run setup_environment.ps1 or verify Godot 4.3 in D:\vr_game_dev\tools\godot\ >&2
exit /b 1

:execute
"%TARGET_EXE%" %*
exit /b %ERRORLEVEL%
'@

$ps1WrapperContent = @'
<#
.SYNOPSIS
    Godot 4 Engine CLI Launcher for Windows PowerShell.
.DESCRIPTION
    Launches Godot 4.3 Console binary (Godot_v4.3-stable_win64_console.exe)
    for terminal stdout/stderr streaming and accurate exit code propagation.
.NOTES
    Target directory: D:\vr_game_dev\tools\godot\
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GodotArgs
)

$targetExe = $null

# 1. Environment variable override
if ($env:GODOT_BIN -and (Test-Path -LiteralPath $env:GODOT_BIN)) {
    $targetExe = $env:GODOT_BIN
}

# 2. Relative console binary (from D:\vr_game_dev\bin)
if (-not $targetExe) {
    $relConsole = Join-Path $PSScriptRoot "..\tools\godot\Godot_v4.3-stable_win64_console.exe"
    if (Test-Path -LiteralPath $relConsole) {
        $targetExe = (Resolve-Path -LiteralPath $relConsole).Path
    }
}

# 3. Sibling relative console binary (from D:\bin)
if (-not $targetExe) {
    $siblingConsole = Join-Path $PSScriptRoot "..\vr_game_dev\tools\godot\Godot_v4.3-stable_win64_console.exe"
    if (Test-Path -LiteralPath $siblingConsole) {
        $targetExe = (Resolve-Path -LiteralPath $siblingConsole).Path
    }
}

# 4. Canonical console binary
if (-not $targetExe) {
    $canonicalConsole = "D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64_console.exe"
    if (Test-Path -LiteralPath $canonicalConsole) {
        $targetExe = $canonicalConsole
    }
}

# 5. Non-console fallback
if (-not $targetExe) {
    $canonicalGui = "D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64.exe"
    if (Test-Path -LiteralPath $canonicalGui) {
        $targetExe = $canonicalGui
    }
}

# Error reporting
if (-not $targetExe) {
    [Console]::Error.WriteLine("[ERROR] Godot executable could not be found in D:\vr_game_dev\tools\godot\.")
    [Console]::Error.WriteLine("Please run setup_environment.ps1 or verify Godot 4.3 installation.")
    exit 1
}

# Execute target binary forwarding all arguments verbatim
if ($GodotArgs -and $GodotArgs.Count -gt 0) {
    & $targetExe @GodotArgs
} else {
    & $targetExe
}

exit $LASTEXITCODE
'@

$bashWrapperContent = @'
#!/usr/bin/env bash
# Godot 4 CLI Launcher for Git Bash / MSYS2 / WSL
if [ -n "$GODOT_BIN" ] && [ -f "$GODOT_BIN" ]; then
    TARGET="$GODOT_BIN"
elif [ -f "$(dirname "$0")/../tools/godot/Godot_v4.3-stable_win64_console.exe" ]; then
    TARGET="$(dirname "$0")/../tools/godot/Godot_v4.3-stable_win64_console.exe"
elif [ -f "D:/vr_game_dev/tools/godot/Godot_v4.3-stable_win64_console.exe" ]; then
    TARGET="D:/vr_game_dev/tools/godot/Godot_v4.3-stable_win64_console.exe"
elif [ -f "D:/vr_game_dev/tools/godot/Godot_v4.3-stable_win64.exe" ]; then
    TARGET="D:/vr_game_dev/tools/godot/Godot_v4.3-stable_win64.exe"
else
    echo "[ERROR] Godot executable not found in D:/vr_game_dev/tools/godot/" >&2
    exit 1
fi

exec "$TARGET" "$@"
'@

function Write-WrapperSet([string]$destDir) {
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Set-Content -LiteralPath (Join-Path $destDir "godot.cmd") -Value $cmdWrapperContent -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $destDir "godot.ps1") -Value $ps1WrapperContent -Encoding UTF8
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $posixBashContent = $bashWrapperContent.Replace("`r`n", "`n") + "`n"
    [System.IO.File]::WriteAllText((Join-Path $destDir "godot"), $posixBashContent, $utf8NoBom)
    Write-Host "  Deployed wrappers (cmd, ps1, sh) to $destDir" -ForegroundColor Green
}

Write-WrapperSet $binDir
if (Test-Path -LiteralPath "D:\") {
    try {
        Write-WrapperSet $sysBinDir
    } catch {
        Write-Host "  Notice: Could not write to $sysBinDir (optional): $_" -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------------------------
# 4. User PATH Configuration (HKCU:\Environment\Path - REG_EXPAND_SZ)
# ------------------------------------------------------------------------------
Write-Host "`n[4/6] Registering User PATH environment variable..." -ForegroundColor Yellow

$regKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment", $true)
try {
    $currentPathVal = $regKey.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    $pathEntries = ($currentPathVal -split ';') | Where-Object { $_ -ne "" }

    if ($pathEntries -notcontains $binDir) {
        $newPathVal = ($pathEntries + $binDir) -join ';'
        $regKey.SetValue("Path", $newPathVal, [Microsoft.Win32.RegistryValueKind]::ExpandString)
        Write-Host "  Successfully added '$binDir' to HKCU:\Environment\Path (REG_EXPAND_SZ)." -ForegroundColor Green

        # Broadcast WM_SETTINGCHANGE message to top-level windows
        try {
            Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd,
    uint Msg,
    UIntPtr wParam,
    string lParam,
    uint fuFlags,
    uint uTimeout,
    out UIntPtr lpdwResult);
"@ -ErrorAction SilentlyContinue

            $HWND_BROADCAST = [IntPtr]0xffff
            $WM_SETTINGCHANGE = 0x001A
            $SMTO_ABORTIFHUNG = 0x0002
            $result = [UIntPtr]::Zero
            [Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "Environment", $SMTO_ABORTIFHUNG, 2000, [ref]$result) | Out-Null
            Write-Host "  Notified Windows shell of environment update (WM_SETTINGCHANGE)." -ForegroundColor Gray
        } catch {
            Write-Host "  Notice: Shell broadcast skipped ($($_))." -ForegroundColor Gray
        }
    } else {
        Write-Host "  '$binDir' is already registered in HKCU:\Environment\Path." -ForegroundColor Green
    }
} finally {
    $regKey.Close()
}

# Update current PowerShell process PATH immediately
if ($env:PATH -notlike "*$binDir*") {
    $env:PATH = "$binDir;$env:PATH"
    Write-Host "  Synchronized current process PATH." -ForegroundColor Gray
}

# ------------------------------------------------------------------------------
# 5. Restore WebXR Project Dependencies
# ------------------------------------------------------------------------------
Write-Host "`n[5/6] Restoring WebXR project dependencies and Godot caches..." -ForegroundColor Yellow
$webxrDir = Join-Path $InstallRoot "projects\webxr_hello_world"
if (Test-Path -LiteralPath (Join-Path $webxrDir "package.json")) {
    Write-Host "  Running npm install in $webxrDir..." -ForegroundColor Cyan
    & npm --prefix "$webxrDir" install --prefer-offline --no-audit --no-fund
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  npm dependencies restored successfully." -ForegroundColor Green
    } else {
        Write-Host "  Warning: npm install reported exit code $LASTEXITCODE." -ForegroundColor Yellow
    }
} else {
    Write-Host "  projects/webxr_hello_world/package.json not found, skipping npm restore." -ForegroundColor Gray
}

# Pre-import Godot VR sample cache
$godotProjDir = Join-Path $InstallRoot "projects\vr_hello_world"
if (Test-Path -LiteralPath (Join-Path $godotProjDir "project.godot")) {
    Write-Host "  Pre-initializing Godot VR sample import cache..." -ForegroundColor Cyan
    $activeGodotLauncher = Join-Path $binDir "godot.cmd"
    if (Test-Path -LiteralPath $activeGodotLauncher) {
        & "$activeGodotLauncher" --headless --path "$godotProjDir" --editor --quit | Out-Null
        Write-Host "  Godot project cache initialized." -ForegroundColor Green
    }
}

# ------------------------------------------------------------------------------
# 6. Verification via check_environment.ps1
# ------------------------------------------------------------------------------
Write-Host "`n[6/6] Executing health-check verification..." -ForegroundColor Yellow
if (-not $SkipCheck) {
    $checkScript = Join-Path $scriptsDir "check_environment.ps1"
    if (-not (Test-Path -LiteralPath $checkScript)) {
        # Fallback to local script relative to current script directory
        $checkScript = Join-Path $PSScriptRoot "check_environment.ps1"
    }

    if (Test-Path -LiteralPath $checkScript) {
        Write-Host "  Invoking: $checkScript`n" -ForegroundColor Cyan
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$checkScript"
        $checkExit = $LASTEXITCODE

        if ($checkExit -eq 0) {
            Write-Host "`n================================================================================" -ForegroundColor Green
            Write-Host "  PROVISIONING & VERIFICATION COMPLETED WITH 100% SUCCESS (EXIT CODE 0)        " -ForegroundColor Green
            Write-Host "================================================================================`n" -ForegroundColor Green
            exit 0
        } else {
            Write-Host "`n================================================================================" -ForegroundColor Red
            Write-Host "  PROVISIONING FINISHED BUT HEALTH-CHECK REPORTED FAILURES (EXIT CODE 1)        " -ForegroundColor Red
            Write-Host "================================================================================`n" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  Health-check script not yet deployed at $checkScript." -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "  Verification skipped via -SkipCheck switch." -ForegroundColor Gray
    exit 0
}
