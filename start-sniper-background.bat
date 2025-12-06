@echo off
REM OCI Instance Sniper - Background Start (Hidden Window)
REM Runs the Python script in background without visible window

REM Get script directory
set SCRIPT_DIR=%~dp0

REM Start Python script hidden (no window)
start /min "" pythonw "%SCRIPT_DIR%scripts\oci-instance-sniper.py"

echo OCI Sniper started in background (hidden window)
echo Check oci-sniper.log for output
timeout /t 3
