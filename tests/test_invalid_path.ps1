# Test invalid path with --editor --quit
$p = Start-Process -FilePath "D:\vr_game_dev\bin\godot.cmd" -ArgumentList "--headless --path `"D:\nonexistent_project_123`" --editor --quit" -NoNewWindow -Wait -PassThru
Write-Host "Test Invalid Path ExitCode: $($p.ExitCode)"

# Test godot.ps1 with invalid script
$pPs1 = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& 'D:\vr_game_dev\bin\godot.ps1' --headless -s non_existent.gd; exit `$LASTEXITCODE`"" -NoNewWindow -Wait -PassThru
Write-Host "Test godot.ps1 Invalid Script ExitCode: $($pPs1.ExitCode)"
