@echo off
REM OCI Instance Sniper - Quick Start Batch File
REM Starts the Python script from any location

echo ====================================================================
echo   OCI Instance Sniper - Starting...
echo ====================================================================
echo.

REM Get script directory
set SCRIPT_DIR=%~dp0

REM Change to scripts directory
cd /d "%SCRIPT_DIR%scripts"

REM Run Python script
python oci-instance-sniper.py

REM Keep window open if error occurred
if errorlevel 1 (
    echo.
    echo ====================================================================
    echo   Script exited with error code %errorlevel%
    echo ====================================================================
    pause
)
