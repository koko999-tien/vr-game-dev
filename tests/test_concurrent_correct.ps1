$temp = "D:\vr_game_dev\tests\.concurrent_godot_test"
if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
New-Item -ItemType Directory -Path $temp -Force | Out-Null

$cmd = "D:\vr_game_dev\bin\godot.cmd"
$proj = "D:\vr_game_dev\projects\vr_hello_world"
$count = 6
$procs = @()

Write-Host "Spawning $count concurrent headless Godot instances using file redirection..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 0; $i -lt $count; $i++) {
    $outFile = "$temp\out_$i.txt"
    $errFile = "$temp\err_$i.txt"
    $p = Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c `"$cmd --headless --path `"$proj`" -s res://test_runner.gd > `"$outFile`" 2> `"$errFile`"`"" `
        -NoNewWindow -PassThru
    $procs += $p
}

while ($sw.ElapsedMilliseconds -lt 25000) {
    $running = $procs | Where-Object { -not $_.HasExited }
    if ($running.Count -eq 0) { break }
    Start-Sleep -Milliseconds 100
}
$sw.Stop()

Write-Host "All $count processes completed in $($sw.ElapsedMilliseconds)ms"

$allPassed = $true
for ($i = 0; $i -lt $count; $i++) {
    $outFile = "$temp\out_$i.txt"
    $outText = if (Test-Path $outFile) { Get-Content $outFile -Raw } else { "" }
    $passed = $outText -match "ALL CI VALIDATION CHECKS PASSED"
    Write-Host "Instance $i - ExitCode: $($procs[$i].ExitCode) - Passed: $passed"
    if (-not $passed) { $allPassed = $false }
}

$lingering = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue
Write-Host "Lingering Godot processes: $(if ($lingering) { $lingering.Count } else { 0 })"

Remove-Item $temp -Recurse -Force
if ($allPassed -and ($null -eq $lingering -or $lingering.Count -eq 0)) {
    Write-Host "CONCURRENCY STRESS TEST PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "CONCURRENCY STRESS TEST FAILED!" -ForegroundColor Red
    exit 1
}
