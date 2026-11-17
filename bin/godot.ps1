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
