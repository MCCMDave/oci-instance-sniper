@echo off
REM OCI Instance Sniper - Multi-Instance Manager (Interactive Mode)
REM Manages multiple regions (Frankfurt, Paris, etc.) simultaneously

echo ====================================================================
echo   OCI Instance Sniper - Multi-Instance Manager
echo ====================================================================
echo.

REM Get script directory
set SCRIPT_DIR=%~dp0

REM Run PowerShell multi-instance manager in interactive mode
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\multi\manage-instances.ps1" -Interactive

REM Keep window open if error occurred
if errorlevel 1 (
    echo.
    echo ====================================================================
    echo   Script exited with error code %errorlevel%
    echo ====================================================================
    pause
)
