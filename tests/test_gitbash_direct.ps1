function Invoke-ProcessRedirect([string]$exe, [string]$cmdArgs) {
    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $p = Start-Process -FilePath $exe -ArgumentList $cmdArgs `
            -RedirectStandardOutput $outFile -RedirectStandardError $errFile `
            -NoNewWindow -PassThru -Wait
        
        $stdout = if (Test-Path $outFile) { [System.IO.File]::ReadAllText($outFile) } else { "" }
        $stderr = if (Test-Path $errFile) { [System.IO.File]::ReadAllText($errFile) } else { "" }
        return [PSCustomObject]@{
            ExitCode = $p.ExitCode
            Stdout   = $stdout
            Stderr   = $stderr
        }
    } finally {
        if (Test-Path $outFile) { Remove-Item $outFile -Force -ErrorAction SilentlyContinue }
        if (Test-Path $errFile) { Remove-Item $errFile -Force -ErrorAction SilentlyContinue }
    }
}

$gitBash = "C:\Program Files\Git\bin\bash.exe"

$res1 = Invoke-ProcessRedirect $gitBash '-c "/d/vr_game_dev/bin/godot --version"'
Write-Host "Res1 (vr_game_dev/bin/godot): ExitCode=$($res1.ExitCode), StderrLen=$($res1.Stderr.Length), Out=$($res1.Stdout.Trim())"

$res2 = Invoke-ProcessRedirect $gitBash '-c "/d/bin/godot --version"'
Write-Host "Res2 (D:/bin/godot):          ExitCode=$($res2.ExitCode), StderrLen=$($res2.Stderr.Length), Out=$($res2.Stdout.Trim())"

$res3 = Invoke-ProcessRedirect $gitBash '-c "godot --version"'
Write-Host "Res3 (naked godot):           ExitCode=$($res3.ExitCode), StderrLen=$($res3.Stderr.Length), Out=$($res3.Stdout.Trim())"

$res4 = Invoke-ProcessRedirect $gitBash '-c "/d/vr_game_dev/bin/godot --headless --path ''/d/vr_game_dev/projects/vr_hello_world'' -s res://test_runner.gd"'
Write-Host "Res4 (VR test runner):        ExitCode=$($res4.ExitCode), StderrLen=$($res4.Stderr.Length), Match=$($res4.Stdout -match 'ALL CI VALIDATION CHECKS PASSED')"
