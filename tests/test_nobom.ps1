$content = @'
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

# Write WITHOUT BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$testPath = "D:\vr_game_dev\tests\godot_nobom"
[System.IO.File]::WriteAllText($testPath, $content.Replace("`r`n", "`n"), $utf8NoBom)

$p = Start-Process -FilePath "C:\Program Files\Git\bin\bash.exe" `
    -ArgumentList "-c `"/d/vr_game_dev/tests/godot_nobom --version`"" `
    -RedirectStandardOutput "D:\vr_game_dev\tests\nobom_out.txt" `
    -RedirectStandardError "D:\vr_game_dev\tests\nobom_err.txt" -PassThru -Wait

Write-Host "ExitCode: $($p.ExitCode)"
Write-Host "Stderr: '$(Get-Content D:\vr_game_dev\tests\nobom_err.txt)'"
Write-Host "Stdout: '$(Get-Content D:\vr_game_dev\tests\nobom_out.txt)'"

Remove-Item $testPath, "D:\vr_game_dev\tests\nobom_out.txt", "D:\vr_game_dev\tests\nobom_err.txt" -Force
