$temp = "D:\vr_game_dev\tests\.parallel_chk_test"
if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
New-Item -ItemType Directory -Path $temp -Force | Out-Null

$script = "D:\vr_game_dev\scripts\check_environment.ps1"
$count = 4
$procs = @()

Write-Host "Launching 4 concurrent check_environment.ps1 -SkipBuild -Json instances..."
for ($i = 0; $i -lt $count; $i++) {
    $out = "$temp\out_$i.json"
    $code = "$temp\code_$i.txt"
    $arg = "/c `"powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$script`" -SkipBuild -Json > `"$out`" 2>&1 & echo %ERRORLEVEL% > `"$code`"`""
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList $arg -PassThru
    $procs += $p
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
while ($sw.ElapsedMilliseconds -lt 25000) {
    $running = $procs | Where-Object { -not $_.HasExited }
    if ($running.Count -eq 0) { break }
    Start-Sleep -Milliseconds 200
}
$sw.Stop()

Write-Host "All processes exited in: $($sw.ElapsedMilliseconds)ms"
for ($i = 0; $i -lt $count; $i++) {
    $c = if (Test-Path "$temp\code_$i.txt") { (Get-Content "$temp\code_$i.txt" -Raw).Trim() } else { "TIMEOUT" }
    $o = if (Test-Path "$temp\out_$i.json") { Get-Content "$temp\out_$i.json" -Raw } else { "" }
    $parsed = $null
    try { $parsed = $o | ConvertFrom-Json } catch {}
    $validJson = ($null -ne $parsed) -and ($parsed.Failed -eq 0)
    Write-Host "Instance $i - Code: $c - ValidJSON: $validJson - PassedChecks: $($parsed.Passed)"
}

Remove-Item $temp -Recurse -Force
