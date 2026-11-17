$proj = "D:\vr_game_dev\projects\vr_hello_world"
$cmd = "D:\vr_game_dev\bin\godot.cmd"

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $cmd
$psi.Arguments = "--headless --path `"$proj`" -s res://test_runner.gd"
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true

$p = [System.Diagnostics.Process]::Start($psi)
$out = $p.StandardOutput.ReadToEnd()
$err = $p.StandardError.ReadToEnd()
$p.WaitForExit(10000)

Write-Host "Single instance exit code: $($p.ExitCode)"
Write-Host "Stdout length: $($out.Length)"
Write-Host "Stderr length: $($err.Length)"
Write-Host "Stdout content: $out"
