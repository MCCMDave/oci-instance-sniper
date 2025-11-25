# OCI Instance Sniper - Control Menu
# Bilingual PowerShell menu system for managing the sniper script
# Supports: Foreground, Background Jobs, Task Scheduler, Status, Logs

# ============================================================================
# CONFIGURATION
# ============================================================================

# Language: "EN" or "DE"
$LANGUAGE = "EN"

# Script Configuration
$SCRIPT_NAME = "oci-instance-sniper.py"
$SCRIPT_PATH = Join-Path $PSScriptRoot $SCRIPT_NAME
$LOG_FILE = Join-Path $PSScriptRoot "oci-sniper.log"
$JOB_NAME = "OCI-Instance-Sniper-Job"
$TASK_NAME = "OCI-Instance-Sniper-Task"

# ============================================================================
# TRANSLATIONS
# ============================================================================

$TRANSLATIONS = @{
    EN = @{
        title = "OCI Instance Sniper - Control Menu"
        menu_1 = "Start Script (Foreground - see live output)"
        menu_2 = "Start Script (Background - runs hidden until PC off)"
        menu_3 = "Start Script (Task Scheduler - survives reboots)"
        menu_4 = "Check Status"
        menu_5 = "View Live Logs"
        menu_6 = "Stop Script"
        menu_0 = "Exit"
        prompt = "Enter choice (1-6, 0=Exit)"
        invalid = "Invalid choice! Please enter 1-6 or 0."

        # Status messages
        starting_fg = "Starting script in foreground..."
        starting_bg = "Starting script as background job..."
        starting_task = "Starting script via Task Scheduler..."
        script_not_found = "ERROR: Script not found at"

        # Status check
        status_title = "Script Status"
        status_fg_running = "Foreground: Not detectable (check terminal)"
        status_bg_running = "Background Job: RUNNING"
        status_bg_stopped = "Background Job: NOT RUNNING"
        status_task_running = "Task Scheduler: RUNNING"
        status_task_stopped = "Task Scheduler: NOT RUNNING"
        status_task_notfound = "Task Scheduler: NOT CONFIGURED"

        # Logs
        log_title = "Live Logs (Press Ctrl+C to stop)"
        log_not_found = "Log file not found. Script may not have started yet."

        # Stop
        stop_title = "Stopping Script"
        stop_bg = "Stopping background job..."
        stop_task = "Stopping task scheduler task..."
        stop_success = "Script stopped successfully!"
        stop_nothing = "No running instances found."

        # Task Scheduler
        task_exists = "Task already exists. Removing old task..."
        task_created = "Task Scheduler task created successfully!"
        task_started = "Task started! Check status with option 4."
        task_create_error = "Error creating task. Make sure PowerShell runs as Administrator!"

        # Background Job
        job_exists = "Background job already running!"
        job_started = "Background job started successfully!"
        job_stopped = "Background job stopped."
        job_notfound = "No background job found."

        press_enter = "Press Enter to continue..."
    }
    DE = @{
        title = "OCI Instance Sniper - Kontrollmenue"
        menu_1 = "Skript starten (Vordergrund - Live-Ausgabe sichtbar)"
        menu_2 = "Skript starten (Hintergrund - laeuft versteckt bis PC aus)"
        menu_3 = "Skript starten (Aufgabenplanung - ueberlebt Neustarts)"
        menu_4 = "Status pruefen"
        menu_5 = "Live-Logs anzeigen"
        menu_6 = "Skript stoppen"
        menu_0 = "Beenden"
        prompt = "Waehle Option (1-6, 0=Beenden)"
        invalid = "Ungueltige Auswahl! Bitte 1-6 oder 0 eingeben."

        # Status messages
        starting_fg = "Starte Skript im Vordergrund..."
        starting_bg = "Starte Skript als Hintergrund-Job..."
        starting_task = "Starte Skript via Aufgabenplanung..."
        script_not_found = "FEHLER: Skript nicht gefunden unter"

        # Status check
        status_title = "Skript-Status"
        status_fg_running = "Vordergrund: Nicht erkennbar (pruefe Terminal)"
        status_bg_running = "Hintergrund-Job: LAEUFT"
        status_bg_stopped = "Hintergrund-Job: LAEUFT NICHT"
        status_task_running = "Aufgabenplanung: LAEUFT"
        status_task_stopped = "Aufgabenplanung: LAEUFT NICHT"
        status_task_notfound = "Aufgabenplanung: NICHT KONFIGURIERT"

        # Logs
        log_title = "Live-Logs (Strg+C zum Stoppen)"
        log_not_found = "Log-Datei nicht gefunden. Skript moeglicherweise noch nicht gestartet."

        # Stop
        stop_title = "Stoppe Skript"
        stop_bg = "Stoppe Hintergrund-Job..."
        stop_task = "Stoppe Aufgabenplanungs-Task..."
        stop_success = "Skript erfolgreich gestoppt!"
        stop_nothing = "Keine laufenden Instanzen gefunden."

        # Task Scheduler
        task_exists = "Task existiert bereits. Entferne alten Task..."
        task_created = "Aufgabenplanungs-Task erfolgreich erstellt!"
        task_started = "Task gestartet! Pruefe Status mit Option 4."
        task_create_error = "Fehler beim Erstellen des Tasks. PowerShell als Administrator ausfuehren!"

        # Background Job
        job_exists = "Hintergrund-Job laeuft bereits!"
        job_started = "Hintergrund-Job erfolgreich gestartet!"
        job_stopped = "Hintergrund-Job gestoppt."
        job_notfound = "Kein Hintergrund-Job gefunden."

        press_enter = "Enter druecken zum Fortfahren..."
    }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Get-Translation {
    param([string]$key)
    return $TRANSLATIONS[$LANGUAGE][$key]
}

function Show-Menu {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  $(Get-Translation 'title')" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. $(Get-Translation 'menu_1')" -ForegroundColor Green
    Write-Host "  2. $(Get-Translation 'menu_2')" -ForegroundColor Yellow
    Write-Host "  3. $(Get-Translation 'menu_3')" -ForegroundColor Magenta
    Write-Host "  4. $(Get-Translation 'menu_4')" -ForegroundColor Cyan
    Write-Host "  5. $(Get-Translation 'menu_5')" -ForegroundColor Blue
    Write-Host "  6. $(Get-Translation 'menu_6')" -ForegroundColor Red
    Write-Host ""
    Write-Host "  0. $(Get-Translation 'menu_0')" -ForegroundColor DarkGray
    Write-Host ""
}

function Check-ScriptExists {
    if (-not (Test-Path $SCRIPT_PATH)) {
        Write-Host "$(Get-Translation 'script_not_found'): $SCRIPT_PATH" -ForegroundColor Red
        Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
        Read-Host
        return $false
    }
    return $true
}

# ============================================================================
# EXECUTION FUNCTIONS
# ============================================================================

function Start-Foreground {
    if (-not (Check-ScriptExists)) { return }

    Write-Host "$(Get-Translation 'starting_fg')" -ForegroundColor Green
    Write-Host ""

    # Run Python script directly
    python $SCRIPT_PATH

    Write-Host ""
    Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
    Read-Host
}

function Start-BackgroundJob {
    if (-not (Check-ScriptExists)) { return }

    # Check if job already running
    $existingJob = Get-Job -Name $JOB_NAME -ErrorAction SilentlyContinue
    if ($existingJob) {
        Write-Host "$(Get-Translation 'job_exists')" -ForegroundColor Yellow
        Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
        Read-Host
        return
    }

    Write-Host "$(Get-Translation 'starting_bg')" -ForegroundColor Yellow

    # Start as PowerShell background job
    Start-Job -Name $JOB_NAME -ScriptBlock {
        param($scriptPath)
        python $scriptPath
    } -ArgumentList $SCRIPT_PATH | Out-Null

    Start-Sleep -Seconds 2

    Write-Host "$(Get-Translation 'job_started')" -ForegroundColor Green
    Write-Host ""
    Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
    Read-Host
}

function Start-TaskScheduler {
    if (-not (Check-ScriptExists)) { return }

    Write-Host "$(Get-Translation 'starting_task')" -ForegroundColor Magenta

    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $TASK_NAME -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "$(Get-Translation 'task_exists')" -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TASK_NAME -Confirm:$false
    }

    try {
        # Get Python path
        $pythonPath = (Get-Command python).Source

        # Create action
        $action = New-ScheduledTaskAction -Execute $pythonPath -Argument $SCRIPT_PATH -WorkingDirectory $PSScriptRoot

        # Create settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        # Register task
        Register-ScheduledTask -TaskName $TASK_NAME -Action $action -Settings $settings -Force | Out-Null

        # Start task
        Start-ScheduledTask -TaskName $TASK_NAME

        Write-Host "$(Get-Translation 'task_created')" -ForegroundColor Green
        Write-Host "$(Get-Translation 'task_started')" -ForegroundColor Green
    }
    catch {
        Write-Host "$(Get-Translation 'task_create_error')" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
    Read-Host
}

function Show-Status {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  $(Get-Translation 'status_title')" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    # Check Background Job
    $job = Get-Job -Name $JOB_NAME -ErrorAction SilentlyContinue
    if ($job -and $job.State -eq "Running") {
        Write-Host "  [OK] $(Get-Translation 'status_bg_running')" -ForegroundColor Green
    } else {
        Write-Host "  [X]  $(Get-Translation 'status_bg_stopped')" -ForegroundColor Red
    }

    # Check Task Scheduler
    $task = Get-ScheduledTask -TaskName $TASK_NAME -ErrorAction SilentlyContinue
    if ($task) {
        $taskInfo = Get-ScheduledTaskInfo -TaskName $TASK_NAME -ErrorAction SilentlyContinue
        if ($taskInfo.LastTaskResult -eq 267009) {
            Write-Host "  [OK] $(Get-Translation 'status_task_running')" -ForegroundColor Green
        } else {
            Write-Host "  [!]  $(Get-Translation 'status_task_stopped')" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [X]  $(Get-Translation 'status_task_notfound')" -ForegroundColor Red
    }

    # Check Log file
    if (Test-Path $LOG_FILE) {
        $logSize = (Get-Item $LOG_FILE).Length / 1KB
        Write-Host ""
        Write-Host "  [i]  Log File: $([math]::Round($logSize, 2)) KB" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
    Read-Host
}

function Show-LiveLogs {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Blue
    Write-Host "  $(Get-Translation 'log_title')" -ForegroundColor Blue
    Write-Host "================================================================" -ForegroundColor Blue
    Write-Host ""

    if (-not (Test-Path $LOG_FILE)) {
        Write-Host "$(Get-Translation 'log_not_found')" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
        Read-Host
        return
    }

    # Show last 50 lines and follow
    Get-Content -Path $LOG_FILE -Tail 50 -Wait
}

function Stop-Script {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "  $(Get-Translation 'stop_title')" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host ""

    $stoppedAny = $false

    # Stop Background Job
    $job = Get-Job -Name $JOB_NAME -ErrorAction SilentlyContinue
    if ($job) {
        Write-Host "$(Get-Translation 'stop_bg')" -ForegroundColor Yellow
        Stop-Job -Name $JOB_NAME
        Remove-Job -Name $JOB_NAME -Force
        Write-Host "$(Get-Translation 'job_stopped')" -ForegroundColor Green
        $stoppedAny = $true
    }

    # Stop Task Scheduler
    $task = Get-ScheduledTask -TaskName $TASK_NAME -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "$(Get-Translation 'stop_task')" -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $TASK_NAME -ErrorAction SilentlyContinue
        Write-Host "$(Get-Translation 'stop_success')" -ForegroundColor Green
        $stoppedAny = $true
    }

    if (-not $stoppedAny) {
        Write-Host "$(Get-Translation 'stop_nothing')" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
    Read-Host
}

# ============================================================================
# MAIN LOOP
# ============================================================================

while ($true) {
    Show-Menu

    $choice = Read-Host "$(Get-Translation 'prompt')"

    switch ($choice) {
        "1" { Start-Foreground }
        "2" { Start-BackgroundJob }
        "3" { Start-TaskScheduler }
        "4" { Show-Status }
        "5" { Show-LiveLogs }
        "6" { Stop-Script }
        "0" {
            Clear-Host
            exit
        }
        default {
            Write-Host ""
            Write-Host "$(Get-Translation 'invalid')" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}
