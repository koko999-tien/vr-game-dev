# Test flags and exit code behavior
$p1 = Start-Process -FilePath "D:\vr_game_dev\bin\godot.cmd" -ArgumentList "--headless --nonexistent-flag --quit" -NoNewWindow -Wait -PassThru
Write-Host "Test 1 (--headless --nonexistent-flag --quit) ExitCode: $($p1.ExitCode)"

$p2 = Start-Process -FilePath "D:\vr_game_dev\bin\godot.cmd" -ArgumentList "--headless -s non_existent_file.gd" -NoNewWindow -Wait -PassThru
Write-Host "Test 2 (--headless -s non_existent_file.gd) ExitCode: $($p2.ExitCode)"

$p3 = Start-Process -FilePath "D:\vr_game_dev\bin\godot.cmd" -ArgumentList "--version" -NoNewWindow -Wait -PassThru
Write-Host "Test 3 (--version) ExitCode: $($p3.ExitCode)"
