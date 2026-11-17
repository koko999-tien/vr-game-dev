@echo off
title CHAY WEBXR TREN TRINH DUYET WEB
color 0E
cls
echo ========================================================
echo       DANG KHOI DONG WEBXR (THUC TE AO TREN WEB)
echo ========================================================
echo.
echo Dang khoi dong Web server tai D:\vr_game_dev\projects\webxr_hello_world...
echo.
cd /d "D:\vr_game_dev\projects\webxr_hello_world"
start "" http://localhost:5173
npm run dev
pause
