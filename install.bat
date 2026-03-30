@echo off
:: OpenCode Context Menu Installer
:: This batch file wraps the PowerShell installer for easy double-click execution

title OpenCode Context Menu Installer

echo ========================================
echo   OpenCode Context Menu Installer
echo ========================================
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This installer requires administrator privileges.
    echo.
    echo Requesting elevation...
    echo.
    
    :: Re-launch as administrator
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running installer...
echo.

:: Run the PowerShell installer
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*

if %errorlevel% neq 0 (
    echo.
    echo Installation failed. See error message above.
    pause
    exit /b 1
)

echo.
echo Installation complete!
pause
