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
