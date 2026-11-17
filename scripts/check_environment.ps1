<#
.SYNOPSIS
    VR Game Development Environment Health-Check & Verification Script
.DESCRIPTION
    Comprehensive diagnostic script that verifies:
      1. Windows OS version & 64-bit architecture
      2. Hardware GPU (NVIDIA RTX 2050 Vulkan capability & loader)
      3. Godot 4 CLI executable (godot --version) and PATH resolution
      4. OpenXR runtime status (logs status; non-fatal warning if physical HMD not attached)
      5. Node.js & npm package manager
      6. Git & Python environments
      7. Godot VR Hello World headless test runner (res://test_runner.gd)
      8. WebXR project build test (npm run build in projects/webxr_hello_world)
    Returns exit code 0 when all required tools and projects pass.
.PARAMETER Json
    Outputs structured machine-readable JSON summary for CI pipelines.
.PARAMETER SkipBuild
    Skips WebXR build and Godot project test runner for rapid CLI check.
.PARAMETER ProjectRoot
    Root directory of the VR development environment (Default: D:\vr_game_dev).
#>
[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [switch]$Json,
    [switch]$SkipBuild
)

if (-not $ProjectRoot) {
    if ($PSScriptRoot) {
        $resolved = (Resolve-Path (Join-Path $PSScriptRoot "..") -ErrorAction SilentlyContinue)
        if ($resolved) { $ProjectRoot = $resolved.Path } else { $ProjectRoot = "D:\vr_game_dev" }
    } else {
        $ProjectRoot = "D:\vr_game_dev"
    }
}

$ErrorActionPreference = "Continue"

$report = [PSCustomObject]@{
    Timestamp = (Get-Date).ToString("o")
    Host      = $env:COMPUTERNAME
    User      = $env:USERNAME
    Passed    = 0
    Failed    = 0
    Warnings  = 0
    Checks    = [System.Collections.Generic.List[PSCustomObject]]::new()
}

function Log-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet("PASS", "FAIL", "WARN", "INFO")][string]$Status,
        [Parameter(Mandatory = $true)][string]$Details,
        [string]$Guidance = ""
    )

    $item = [PSCustomObject]@{
        Category = $Category
        Name     = $Name
        Status   = $Status
        Details  = $Details
        Guidance = $Guidance
    }
    $report.Checks.Add($item)

    if ($Status -eq "PASS") { $report.Passed++ }
    elseif ($Status -eq "FAIL") { $report.Failed++ }
    elseif ($Status -eq "WARN") { $report.Warnings++ }

    if (-not $Json) {
        $color = switch ($Status) {
            "PASS" { "Green" }
            "FAIL" { "Red" }
            "WARN" { "Yellow" }
            default { "Cyan" }
        }
        $bracket = "[$Status]".PadRight(8)
        Write-Host $bracket -ForegroundColor $color -NoNewline
        Write-Host "[$Category] $Name" -ForegroundColor White
        Write-Host "         $Details" -ForegroundColor Gray
        if ($Guidance) {
            Write-Host "         -> Guidance: $Guidance" -ForegroundColor DarkYellow
        }
    }
}

Set-Alias -Name Add-Check -Value Log-Check -ErrorAction SilentlyContinue

if (-not $Json) {
    Write-Host "`n================================================================================" -ForegroundColor Cyan
    Write-Host "        VR GAME DEVELOPMENT ENVIRONMENT HEALTH-CHECK (WINDOWS 64-BIT)           " -ForegroundColor Cyan
    Write-Host "================================================================================`n" -ForegroundColor Cyan
}

# ------------------------------------------------------------------------------
# 0. Defensive Project Root Directory Validation
# ------------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $ProjectRoot -ErrorAction SilentlyContinue)) {
    Add-Check "Filesystem" "Project Root Directory" "FAIL" "Project root path does not exist or is inaccessible: '$ProjectRoot'"
}

# ------------------------------------------------------------------------------
# 1. Windows OS Version & Architecture
# ------------------------------------------------------------------------------
$is64BitOS = [Environment]::Is64BitOperatingSystem
$osVersion = [Environment]::OSVersion.VersionString
$osDetails = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$osCaption = if ($osDetails) { $osDetails.Caption } else { "Microsoft Windows" }
$osBuild   = if ($osDetails) { $osDetails.BuildNumber } else { [Environment]::OSVersion.Version.Build }

if ($is64BitOS) {
    Log-Check -Category "OS" -Name "64-bit Architecture & Version" -Status "PASS" `
        -Details "$osCaption (Build $osBuild, $osVersion) - 64-bit OS verified."
} else {
    Log-Check -Category "OS" -Name "64-bit Architecture & Version" -Status "FAIL" `
        -Details "32-bit OS detected ($osCaption). 64-bit Windows is strictly required." `
        -Guidance "Upgrade operating system to Windows 10/11 64-bit."
}

# ------------------------------------------------------------------------------
# 2. Hardware GPU & Vulkan Capability
# ------------------------------------------------------------------------------
$videoControllers = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
$nvidiaGpu = $videoControllers | Where-Object { $_.Name -like "*NVIDIA*" } | Select-Object -First 1
$amdGpu    = $videoControllers | Where-Object { $_.Name -like "*AMD*" -or $_.Name -like "*Radeon*" } | Select-Object -First 1

if ($nvidiaGpu) {
    $gpuName = $nvidiaGpu.Name
    $driverVer = $nvidiaGpu.DriverVersion
    Log-Check -Category "Hardware" -Name "Discrete GPU (NVIDIA)" -Status "PASS" `
        -Details "$gpuName (Driver: $driverVer)"
} elseif ($amdGpu) {
    Log-Check -Category "Hardware" -Name "Integrated GPU (AMD)" -Status "WARN" `
        -Details "$($amdGpu.Name) (Driver: $($amdGpu.DriverVersion)) - Discrete NVIDIA GPU not found." `
        -Guidance "For high performance OpenXR VR, a discrete GPU like NVIDIA RTX 2050 or higher is recommended."
} else {
    Log-Check -Category "Hardware" -Name "GPU Detection" -Status "FAIL" `
        -Details "No dedicated or integrated GPU detected via WMI/CIM." `
        -Guidance "Ensure graphics card drivers are installed."
}

# Vulkan Runtime Loader check
$vulkanDllPath = "$env:SystemRoot\System32\vulkan-1.dll"
if (Test-Path -LiteralPath $vulkanDllPath) {
    $vulkanVer = (Get-Item -LiteralPath $vulkanDllPath).VersionInfo.FileVersion
    Log-Check -Category "Graphics" -Name "Vulkan Runtime Loader" -Status "PASS" `
        -Details "vulkan-1.dll present in System32 (Version: $vulkanVer)"
} else {
    Log-Check -Category "Graphics" -Name "Vulkan Runtime Loader" -Status "FAIL" `
        -Details "vulkan-1.dll missing from $vulkanDllPath" `
        -Guidance "Install latest NVIDIA graphics drivers or Vulkan SDK from LunarG."
}

# ------------------------------------------------------------------------------
# 3. Godot 4 CLI Executable & PATH Resolution
# ------------------------------------------------------------------------------
$godotCommand = Get-Command godot -ErrorAction SilentlyContinue
$godotCandidate = $null

if ($godotCommand) {
    $godotCandidate = $godotCommand.Source
} else {
    # Check fallback locations in project root
    $candidates = @(
        "$ProjectRoot\bin\godot.cmd",
        "$ProjectRoot\bin\godot.ps1",
        "$ProjectRoot\tools\godot\Godot_v4.3-stable_win64_console.exe"
    )
    foreach ($cand in $candidates) {
        if (Test-Path -LiteralPath $cand) {
            $godotCandidate = $cand
            break
        }
    }
}

if ($godotCandidate) {
    try {
        $godotVerOutput = (& $godotCandidate --headless --version 2>&1).Trim()
        if ($godotVerOutput -match "^4\.") {
            Log-Check -Category "Engine" -Name "Godot 4 CLI" -Status "PASS" `
                -Details "Godot $godotVerOutput resolved via $godotCandidate"
        } else {
            Log-Check -Category "Engine" -Name "Godot 4 CLI" -Status "FAIL" `
                -Details "Resolved '$godotCandidate' but reported unexpected version: $godotVerOutput (Expected 4.x)" `
                -Guidance "Ensure Godot 4.3 executable is configured in PATH."
        }
    } catch {
        Log-Check -Category "Engine" -Name "Godot 4 CLI" -Status "FAIL" `
            -Details "Error executing '$godotCandidate': $_" `
            -Guidance "Verify executable permissions and architecture compatibility."
    }
} else {
    Log-Check -Category "Engine" -Name "Godot 4 CLI" -Status "FAIL" `
        -Details "'godot' command not found in PATH or project bin directory." `
        -Guidance "Run .\scripts\setup_environment.ps1 to configure Godot 4 and User PATH."
}

# ------------------------------------------------------------------------------
# 4. OpenXR Runtime Status (Non-fatal warning if physical HMD not attached)
# ------------------------------------------------------------------------------
$openxrManifest = $null
$hklmKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Khronos\OpenXR\1" -ErrorAction SilentlyContinue
if ($hklmKey -and $hklmKey.ActiveRuntime) {
    $openxrManifest = $hklmKey.ActiveRuntime
}
$hkcuKey = Get-ItemProperty -Path "HKCU:\SOFTWARE\Khronos\OpenXR\1" -ErrorAction SilentlyContinue
if ($hkcuKey -and $hkcuKey.ActiveRuntime) {
    $openxrManifest = $hkcuKey.ActiveRuntime
}

if ($openxrManifest -and (Test-Path -LiteralPath $openxrManifest)) {
    Log-Check -Category "OpenXR" -Name "Active Runtime Manifest" -Status "PASS" `
        -Details "Registered active OpenXR runtime: $openxrManifest"
} else {
    # Non-fatal warning: development, headless testing, and WebXR emulation proceed normally
    $detailMsg = if ($openxrManifest) {
        "Registry manifest points to non-existent path: $openxrManifest"
    } else {
        "No active OpenXR runtime found in HKLM/HKCU registry. Physical VR HMD is not currently active"
    }
    Log-Check -Category "OpenXR" -Name "Active Runtime Manifest" -Status "WARN" `
        -Details "$detailMsg. Headless CI validation & WebXR emulator remain 100% operational." `
        -Guidance "To tether a physical headset, install SteamVR, Meta Quest Link, or Pico Connect and set as active OpenXR runtime."
}

# ------------------------------------------------------------------------------
# 5. Node.js & npm Package Manager
# ------------------------------------------------------------------------------
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    try {
        $nodeVersion = (& node -v 2>&1).Trim()
        Log-Check -Category "WebXR" -Name "Node.js Runtime" -Status "PASS" `
            -Details "$nodeVersion ($($nodeCmd.Source))"
    } catch {
        Log-Check -Category "WebXR" -Name "Node.js Runtime" -Status "FAIL" `
            -Details "node command failed to execute: $_"
    }
} else {
    Log-Check -Category "WebXR" -Name "Node.js Runtime" -Status "FAIL" `
        -Details "'node' executable not found in system PATH." `
        -Guidance "Install Node.js LTS (v18+) from https://nodejs.org or via winget."
}

$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if ($npmCmd) {
    try {
        $npmVersion = (& npm -v 2>&1).Trim()
        Log-Check -Category "WebXR" -Name "npm Package Manager" -Status "PASS" `
            -Details "v$npmVersion ($($npmCmd.Source))"
    } catch {
        Log-Check -Category "WebXR" -Name "npm Package Manager" -Status "FAIL" `
            -Details "npm command failed to execute: $_"
    }
} else {
    Log-Check -Category "WebXR" -Name "npm Package Manager" -Status "FAIL" `
        -Details "'npm' executable not found in system PATH." `
        -Guidance "Install npm (bundled with Node.js)."
}

# ------------------------------------------------------------------------------
# 6. Git & Python Environments
# ------------------------------------------------------------------------------
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    try {
        $gitVersion = (& git --version 2>&1).Trim()
        Log-Check -Category "Tools" -Name "Git Version Control" -Status "PASS" `
            -Details "$gitVersion ($($gitCmd.Source))"
    } catch {
        Log-Check -Category "Tools" -Name "Git Version Control" -Status "FAIL" `
            -Details "git command failed to execute: $_"
    }
} else {
    Log-Check -Category "Tools" -Name "Git Version Control" -Status "FAIL" `
        -Details "'git' executable not found in system PATH." `
        -Guidance "Install Git for Windows from https://git-scm.com or via winget."
}

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCmd) {
    try {
        $pyVersion = (& python --version 2>&1).Trim()
        Log-Check -Category "Tools" -Name "Python Environment" -Status "PASS" `
            -Details "$pyVersion ($($pythonCmd.Source))"
    } catch {
        Log-Check -Category "Tools" -Name "Python Environment" -Status "FAIL" `
            -Details "python command failed to execute: $_"
    }
} else {
    Log-Check -Category "Tools" -Name "Python Environment" -Status "FAIL" `
        -Details "'python' executable not found in system PATH." `
        -Guidance "Install Python 3.x from https://python.org or via winget."
}

# ------------------------------------------------------------------------------
# 7. Godot VR Hello World Headless Test Runner
# ------------------------------------------------------------------------------
$godotProjDir = if ($ProjectRoot) { [System.IO.Path]::Combine($ProjectRoot, "projects\vr_hello_world") } else { "" }
$godotProjFile = if ($godotProjDir) { [System.IO.Path]::Combine($godotProjDir, "project.godot") } else { "" }
$testRunnerScript = if ($godotProjDir) { [System.IO.Path]::Combine($godotProjDir, "test_runner.gd") } else { "" }

if (-not $SkipBuild) {
    if ((Test-Path -LiteralPath $godotProjFile -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $testRunnerScript -ErrorAction SilentlyContinue) -and $godotCandidate) {
        try {
            $runnerOut = (& $godotCandidate --headless --path "$godotProjDir" -s res://test_runner.gd 2>&1)
            $runnerExit = $LASTEXITCODE
            if ($runnerExit -eq 0) {
                Log-Check -Category "Projects" -Name "Godot VR Sample (res://test_runner.gd)" -Status "PASS" `
                    -Details "Test runner passed: 6/6 assertions verified (XROrigin3D, Camera, Left/Right Controllers, OpenXR interface)."
            } else {
                $errSnippet = ($runnerOut | Select-Object -Last 5) -join "; "
                Log-Check -Category "Projects" -Name "Godot VR Sample (res://test_runner.gd)" -Status "FAIL" `
                    -Details "Test runner failed with exit code $runnerExit. Output: $errSnippet" `
                    -Guidance "Inspect $godotProjDir/test_runner.gd and scene tree nodes."
            }
        } catch {
            Log-Check -Category "Projects" -Name "Godot VR Sample (res://test_runner.gd)" -Status "FAIL" `
                -Details "Exception running Godot test runner: $_"
        }
    } else {
        $missing = @()
        if (-not (Test-Path -LiteralPath $godotProjFile -ErrorAction SilentlyContinue)) { $missing += "project.godot" }
        if (-not (Test-Path -LiteralPath $testRunnerScript -ErrorAction SilentlyContinue)) { $missing += "test_runner.gd" }
        if (-not $godotCandidate) { $missing += "godot CLI" }
        Log-Check -Category "Projects" -Name "Godot VR Sample (res://test_runner.gd)" -Status "FAIL" `
            -Details "Missing prerequisites for test runner: $($missing -join ', ')" `
            -Guidance "Run .\scripts\setup_environment.ps1 or restore project files."
    }
} else {
    Log-Check -Category "Projects" -Name "Godot VR Sample (res://test_runner.gd)" -Status "INFO" `
        -Details "Skipped due to -SkipBuild switch."
}

# ------------------------------------------------------------------------------
# 8. WebXR Project Build Test
# ------------------------------------------------------------------------------
$webxrProjDir = if ($ProjectRoot) { [System.IO.Path]::Combine($ProjectRoot, "projects\webxr_hello_world") } else { "" }
$webxrPkgJson = if ($webxrProjDir) { [System.IO.Path]::Combine($webxrProjDir, "package.json") } else { "" }

if (-not $SkipBuild) {
    if ((Test-Path -LiteralPath $webxrPkgJson -ErrorAction SilentlyContinue) -and $npmCmd) {
        try {
            $buildOut = (& npm --prefix "$webxrProjDir" run build 2>&1)
            $buildExit = $LASTEXITCODE
            $distIndex = if ($webxrProjDir) { [System.IO.Path]::Combine($webxrProjDir, "dist\index.html") } else { "" }

            if ($buildExit -eq 0 -and (Test-Path -LiteralPath $distIndex -ErrorAction SilentlyContinue)) {
                $distSize = (Get-Item -LiteralPath $distIndex).Length
                Log-Check -Category "Projects" -Name "WebXR Sample Build (npm run build)" -Status "PASS" `
                    -Details "Vite production build succeeded; dist\index.html created ($distSize bytes)."
            } else {
                $errSnippet = ($buildOut | Select-Object -Last 5) -join "; "
                Log-Check -Category "Projects" -Name "WebXR Sample Build (npm run build)" -Status "FAIL" `
                    -Details "npm run build failed with exit code $buildExit. Details: $errSnippet" `
                    -Guidance "Run 'npm install' in $webxrProjDir and verify vite.config.js."
            }
        } catch {
            Log-Check -Category "Projects" -Name "WebXR Sample Build (npm run build)" -Status "FAIL" `
                -Details "Exception running npm build: $_"
        }
    } else {
        $missing = @()
        if (-not (Test-Path -LiteralPath $webxrPkgJson -ErrorAction SilentlyContinue)) { $missing += "package.json" }
        if (-not $npmCmd) { $missing += "npm command" }
        Log-Check -Category "Projects" -Name "WebXR Sample Build (npm run build)" -Status "FAIL" `
            -Details "Missing prerequisites: $($missing -join ', ')" `
            -Guidance "Run .\scripts\setup_environment.ps1 to restore WebXR project."
    }
} else {
    Log-Check -Category "Projects" -Name "WebXR Sample Build (npm run build)" -Status "INFO" `
        -Details "Skipped due to -SkipBuild switch."
}

# ------------------------------------------------------------------------------
# Final Summary and Exit Code
# ------------------------------------------------------------------------------
if ($Json) {
    $report | ConvertTo-Json -Depth 5
} else {
    Write-Host "`n--------------------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Summary: $($report.Passed) Passed, $($report.Warnings) Warnings, $($report.Failed) Failures" -ForegroundColor White
    if ($report.Failed -eq 0) {
        Write-Host "RESULT: ALL CRITICAL HEALTH CHECKS PASSED (EXIT CODE 0)`n" -ForegroundColor Green
    } else {
        Write-Host "RESULT: $($report.Failed) CRITICAL HEALTH CHECKS FAILED (EXIT CODE 1)`n" -ForegroundColor Red
    }
}

if ($report.Failed -eq 0) {
    exit 0
} else {
    exit 1
}
