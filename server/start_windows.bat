@echo off
cd /d "%~dp0"
if not exist .env (echo Missing server\.env. Run setup_windows.bat first.& pause & exit /b 1)
npm run dev
pause
