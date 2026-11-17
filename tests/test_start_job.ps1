$jobs = @()
for ($i = 0; $i -lt 4; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($cmd, $proj)
        $p = Start-Process -FilePath $cmd -ArgumentList "--headless --path `"$proj`" -s res://test_runner.gd" -NoNewWindow -PassThru -Wait
        return [PSCustomObject]@{
            ExitCode = $p.ExitCode
        }
    } -ArgumentList "D:\vr_game_dev\bin\godot.cmd", "D:\vr_game_dev\projects\vr_hello_world"
}

$results = $jobs | Wait-Job -Timeout 20 | Receive-Job
$jobs | Remove-Job -Force

Write-Host "Results count: $($results.Count)"
foreach ($r in $results) {
    Write-Host "ExitCode: $($r.ExitCode)"
}

$lingering = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue
Write-Host "Lingering Godot: $(if ($lingering) { $lingering.Count } else { 0 })"
