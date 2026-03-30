@echo off
title OpenCode Context Menu Installer

echo ========================================
echo   OpenCode Context Menu Installer
echo ========================================
echo.

echo Installing OpenCode Context Menu...
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0install.ps1"

if %errorlevel% neq 0 (
    echo.
    echo Installation failed. See log file in %TEMP%
) else (
    echo.
    echo Installation complete!
)

pause
