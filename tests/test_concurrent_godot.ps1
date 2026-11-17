$proj = "D:\vr_game_dev\projects\vr_hello_world"
$cmd = "D:\vr_game_dev\bin\godot.cmd"

Write-Host "Spawning 4 concurrent headless Godot instances..."
$procs = @()
for ($i = 0; $i -lt 4; $i++) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $cmd
    $psi.Arguments = "--headless --path `"$proj`" -s res://test_runner.gd"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $procs += $p
}

Write-Host "Waiting for all 4 instances to complete..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 0; $i -lt 4; $i++) {
    $p = $procs[$i]
    $out = $p.StandardOutput.ReadToEnd()
    $err = $p.StandardError.ReadToEnd()
    $p.WaitForExit(15000)
    Write-Host "Instance $i - ExitCode: $($p.ExitCode) - Passed: $($out -match 'ALL CI VALIDATION CHECKS PASSED')"
    if ($p.ExitCode -ne 0) {
        Write-Host "  Stdout: $out"
        Write-Host "  Stderr: $err"
    }
}
$sw.Stop()
Write-Host "Total time: $($sw.ElapsedMilliseconds)ms"

$lingering = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue
Write-Host "Lingering Godot processes: $(if ($lingering) { $lingering.Count } else { 0 })"
