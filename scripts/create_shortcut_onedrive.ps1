$desk = "C:\Users\TIEN PC\OneDrive\Desktop"
$sh = (New-Object -ComObject WScript.Shell).CreateShortcut("$desk\Lam_Game_VR_Godot.lnk")
$sh.TargetPath = 'D:\vr_game_dev\1_MO_GODOT_LAM_GAME.bat'
$sh.WorkingDirectory = 'D:\vr_game_dev'
$sh.IconLocation = 'D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64.exe,0'
$sh.Save()
Write-Host "SHORTCUT_TRUE_DESKTOP_SUCCESS"
