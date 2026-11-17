$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "D:\vr_game_dev\bin\godot.cmd"
$psi.Arguments = "--headless --version"
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.WaitForExit()
Write-Host "HasExited: $($p.HasExited) ExitCode: $($p.ExitCode)"
