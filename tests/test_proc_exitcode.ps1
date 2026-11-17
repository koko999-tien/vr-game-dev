$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.Arguments = "/c D:\vr_game_dev\bin\godot.cmd --version"
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true

$p = [System.Diagnostics.Process]::Start($psi)
$out = $p.StandardOutput.ReadToEnd()
$p.WaitForExit()
Write-Host "ExitCode: $($p.ExitCode)"
Write-Host "Output: $out"
