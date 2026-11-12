@echo off
cd /d "%~dp0"
where node >nul 2>nul || (echo Can not find Node.js. Install Node.js 20+ first.& pause & exit /b 1)
if not exist .env copy .env.example .env
echo Installing backend dependencies...
npm install
echo.
echo Open server\.env and fill in Supabase values before starting the server.
pause
