@echo off
cd /d "%~dp0server"
if not exist .env copy .env.example .env
npm start
pause
