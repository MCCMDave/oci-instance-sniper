# OCI Instance Sniper - Control Menu v1.5
# Bilingual PowerShell menu system with configuration management
# Supports: Foreground, Background Jobs, Task Scheduler, Status, Logs, Configuration
#
# Changelog v1.5:
# - Added comprehensive logging to control-menu.log
# - Improved error handling and status reporting
# - Better integration with main Python script

# ============================================================================
# CONFIGURATION
# ============================================================================

# Language: "EN" or "DE"
$LANGUAGE = "EN"

# Script Configuration
$SCRIPT_NAME = "oci-instance-sniper.py"
$SCRIPT_PATH = Join-Path $PSScriptRoot $SCRIPT_NAME
$LOG_FILE = Join-Path $PSScriptRoot "oci-sniper.log"
$CONFIG_FILE = Join-Path $PSScriptRoot "sniper-config.json"
$MENU_LOG_FILE = Join-Path $PSScriptRoot "control-menu.log"
$JOB_NAME = "OCI-Instance-Sniper-Job"
$TASK_NAME = "OCI-Instance-Sniper-Task"

# ============================================================================
# CONFIG FILE FUNCTIONS
# ============================================================================

function Load-Config {
    if (Test-Path $CONFIG_FILE) {
        try {
            return Get-Content $CONFIG_FILE -Raw | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

function Save-Config {
    param($config)
    $json = $config | ConvertTo-Json -Depth 10
    # Write UTF-8 without BOM (PowerShell 5.1 compatible)
    [System.IO.File]::WriteAllLines($CONFIG_FILE, $json)
}

function Get-DefaultConfig {
    return @{
        instance_name = "oci-instance"
        ocpus = 2
        memory_in_gbs = 12
        image = "ubuntu"
        retry_delay_seconds = 60
        max_attempts = 1440
        region = "eu-frankfurt-1"
        language = $LANGUAGE
    }
}

function Ensure-ConfigExists {
    if (-not (Test-Path $CONFIG_FILE)) {
        $defaultConfig = Get-DefaultConfig
        Save-Config $defaultConfig
    }
}

# ============================================================================
# TRANSLATIONS
# ============================================================================

$TRANSLATIONS = @{
    EN = @{
        title = "OCI Instance Sniper - Control Menu v1.4"
        menu_1 = "Start Script (Foreground - see live output)"
        menu_2 = "Start Script (Background - runs hidden until PC off)"
        menu_3 = "Start Script (Task Scheduler - survives reboots)"
        menu_4 = "Check Status"
        menu_5 = "View Live Logs"
        menu_6 = "Stop Script"
        menu_7 = "Configuration"
        menu_0 = "Exit"
        prompt = "Enter choice (1-7, 0=Exit)"
        invalid = "Invalid choice! Please enter 1-7 or 0."

        # Configuration menu
        config_title = "Configuration Menu"
        config_current = "Current Configuration"
        config_1 = "Instance Name"
        config_2 = "CPUs (OCPUs)"
        config_3 = "Memory (GB)"
        config_4 = "Region"
        config_5 = "Retry Interval (seconds)"
        config_6 = "Image Type"
        config_7 = "Language"
        config_0 = "Back to Main Menu"
        config_prompt = "Enter option to change (0=Back)"
        config_saved = "Configuration saved successfully!"

        # Config prompts
        prompt_instance_name = "Enter instance name"
        prompt_ocpus = "Enter OCPUs (1-4 for Free Tier)"
        prompt_memory = "Enter Memory in GB (1-24 for Free Tier)"
        prompt_region = "Select Region"
        prompt_interval = "Enter retry interval in seconds (30/60/120 recommended)"
        prompt_image = "Select Image"
        prompt_language = "Select Language"

        # Regions
        region_frankfurt = "Frankfurt (eu-frankfurt-1)"
        region_paris = "Paris (eu-paris-1)"
        region_amsterdam = "Amsterdam (eu-amsterdam-1)"
        region_ashburn = "Ashburn USA (us-ashburn-1)"
        region_phoenix = "Phoenix USA (us-phoenix-1)"

        # Images
        image_ubuntu24 = "Ubuntu 24.04 LTS (recommended)"
        image_oracle10 = "Oracle Linux 10 (latest)"
        image_debian = "Debian 12"
        image_more = "More options..."
        image_ubuntu22 = "Ubuntu 22.04 LTS"
        image_ubuntu20 = "Ubuntu 20.04 LTS"
        image_oracle9 = "Oracle Linux 9"
        image_oracle8 = "Oracle Linux 8"
        image_rocky9 = "Rocky Linux 9"
        image_rocky8 = "Rocky Linux 8"
        image_rhel9 = "RHEL 9"
        image_rhel8 = "RHEL 8"

        # Status messages
        starting_fg = "Starting script in foreground..."
        starting_bg = "Starting script as background job..."
        starting_task = "Starting script via Task Scheduler..."
        script_not_found = "ERROR: Script not found at"

        # Status check
        status_title = "Script Status"
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
        title = "OCI Instance Sniper - Kontrollmenue v1.4"
        menu_1 = "Skript starten (Vordergrund - Live-Ausgabe sichtbar)"
        menu_2 = "Skript starten (Hintergrund - laeuft versteckt bis PC aus)"
        menu_3 = "Skript starten (Aufgabenplanung - ueberlebt Neustarts)"
        menu_4 = "Status pruefen"
        menu_5 = "Live-Logs anzeigen"
        menu_6 = "Skript stoppen"
        menu_7 = "Konfiguration"
        menu_0 = "Beenden"
        prompt = "Waehle Option (1-7, 0=Beenden)"
        invalid = "Ungueltige Auswahl! Bitte 1-7 oder 0 eingeben."

        # Configuration menu
        config_title = "Konfigurationsmenue"
        config_current = "Aktuelle Konfiguration"
        config_1 = "Instanz-Name"
        config_2 = "CPUs (OCPUs)"
        config_3 = "Arbeitsspeicher (GB)"
        config_4 = "Region"
        config_5 = "Wiederholungsintervall (Sekunden)"
        config_6 = "Image-Typ"
        config_7 = "Sprache"
        config_0 = "Zurueck zum Hauptmenue"
        config_prompt = "Option zum Aendern waehlen (0=Zurueck)"
        config_saved = "Konfiguration erfolgreich gespeichert!"

        # Config prompts
        prompt_instance_name = "Instanz-Name eingeben"
        prompt_ocpus = "OCPUs eingeben (1-4 fuer Free Tier)"
        prompt_memory = "Arbeitsspeicher in GB eingeben (1-24 fuer Free Tier)"
        prompt_region = "Region auswaehlen"
        prompt_interval = "Wiederholungsintervall in Sekunden (30/60/120 empfohlen)"
        prompt_image = "Image auswaehlen"
        prompt_language = "Sprache auswaehlen"

        # Regions
        region_frankfurt = "Frankfurt (eu-frankfurt-1)"
        region_paris = "Paris (eu-paris-1)"
        region_amsterdam = "Amsterdam (eu-amsterdam-1)"
        region_ashburn = "Ashburn USA (us-ashburn-1)"
        region_phoenix = "Phoenix USA (us-phoenix-1)"

        # Images
        image_ubuntu24 = "Ubuntu 24.04 LTS (recommended)"
        image_oracle10 = "Oracle Linux 10 (latest)"
        image_debian = "Debian 12"
        image_more = "More options..."
        image_ubuntu22 = "Ubuntu 22.04 LTS"
        image_ubuntu20 = "Ubuntu 20.04 LTS"
        image_oracle9 = "Oracle Linux 9"
        image_oracle8 = "Oracle Linux 8"
        image_rocky9 = "Rocky Linux 9"
        image_rocky8 = "Rocky Linux 8"
        image_rhel9 = "RHEL 9"
        image_rhel8 = "RHEL 8"

        # Status messages
        starting_fg = "Starte Skript im Vordergrund..."
        starting_bg = "Starte Skript als Hintergrund-Job..."
        starting_task = "Starte Skript via Aufgabenplanung..."
        script_not_found = "FEHLER: Skript nicht gefunden unter"

        # Status check
        status_title = "Skript-Status"
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

function Write-MenuLog {
    param(
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $level - $message"
    Add-Content -Path $MENU_LOG_FILE -Value $logMessage -Encoding UTF8
}

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
    Write-Host "  7. $(Get-Translation 'menu_7')" -ForegroundColor White
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
# CONFIGURATION MENU
# ============================================================================

function Show-ConfigMenu {
    while ($true) {
        Ensure-ConfigExists
        $config = Load-Config

        Clear-Host
        Write-Host "================================================================" -ForegroundColor White
        Write-Host "  $(Get-Translation 'config_title')" -ForegroundColor White
        Write-Host "================================================================" -ForegroundColor White
        Write-Host ""
        Write-Host "  $(Get-Translation 'config_current'):" -ForegroundColor Cyan
        Write-Host "  - Instance Name: $($config.instance_name)" -ForegroundColor Gray
        Write-Host "  - CPUs: $($config.ocpus)" -ForegroundColor Gray
        Write-Host "  - Memory: $($config.memory_in_gbs) GB" -ForegroundColor Gray
        Write-Host "  - Region: $($config.region)" -ForegroundColor Gray
        Write-Host "  - Retry Interval: $($config.retry_delay_seconds)s" -ForegroundColor Gray
        Write-Host "  - Image: $($config.image)" -ForegroundColor Gray
        Write-Host "  - Language: $($config.language)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  1. $(Get-Translation 'config_1')" -ForegroundColor Green
        Write-Host "  2. $(Get-Translation 'config_2')" -ForegroundColor Green
        Write-Host "  3. $(Get-Translation 'config_3')" -ForegroundColor Green
        Write-Host "  4. $(Get-Translation 'config_4')" -ForegroundColor Green
        Write-Host "  5. $(Get-Translation 'config_5')" -ForegroundColor Green
        Write-Host "  6. $(Get-Translation 'config_6')" -ForegroundColor Green
        Write-Host "  7. $(Get-Translation 'config_7')" -ForegroundColor Green
        Write-Host ""
        Write-Host "  0. $(Get-Translation 'config_0')" -ForegroundColor DarkGray
        Write-Host ""

        $choice = Read-Host "$(Get-Translation 'config_prompt')"

        switch ($choice) {
            "1" {
                $newName = Read-Host "$(Get-Translation 'prompt_instance_name') [$($config.instance_name)]"
                if ($newName) { $config.instance_name = $newName }
                Save-Config $config
                Write-Host "$(Get-Translation 'config_saved')" -ForegroundColor Green
                Start-Sleep -Seconds 1
            }
            "2" {
                $newCPU = Read-Host "$(Get-Translation 'prompt_ocpus') [$($config.ocpus)]"
                if ($newCPU -and $newCPU -match '^\d+$' -and [int]$newCPU -ge 1 -and [int]$newCPU -le 4) {
                    $config.ocpus = [int]$newCPU
                    Save-Config $config
                    Write-Host "$(Get-Translation 'config_saved')" -ForegroundColor Green
                    Start-Sleep -Seconds 1
                }
            }
            "3" {
                $newMem = Read-Host "$(Get-Translation 'prompt_memory') [$($config.memory_in_gbs)]"
                if ($newMem -and $newMem -match '^\d+$' -and [int]$newMem -ge 1 -and [int]$newMem -le 24) {
                    $config.memory_in_gbs = [int]$newMem
                    Save-Config $config
                    Write-Host "$(Get-Translation 'config_saved')" -ForegroundColor Green
                    Start-Sleep -Seconds 1
                }
            }
            "4" {
                Clear-Host
                Write-Host "$(Get-Translation 'prompt_region'):" -ForegroundColor Cyan
                Write-Host "  1. $(Get-Translation 'region_frankfurt')"
                Write-Host "  2. $(Get-Translation 'region_paris')"
                Write-Host "  3. $(Get-Translation 'region_amsterdam')"
                Write-Host "  4. $(Get-Translation 'region_ashburn')"
                Write-Host "  5. $(Get-Translation 'region_phoenix')"
                $regionChoice = Read-Host "Choice (1-5)"
                $regionMap = @{
                    "1" = "eu-frankfurt-1"
                    "2" = "eu-paris-1"
                    "3" = "eu-amsterdam-1"
                    "4" = "us-ashburn-1"
                    "5" = "us-phoenix-1"
                }
                if ($regionMap.ContainsKey($regionChoice)) {
                    $config.region = $regionMap[$regionChoice]
                    Save-Config $config
                    Write-Host "$(Get-Translation 'config_saved')" -ForegroundColor Green
                    Start-Sleep -Seconds 1
                }
            }
            "5" {
                $newInterval = Read-Host "$(Get-Translation 'prompt_interval') [$($config.retry_delay_seconds)]"
                if ($newInterval -and $newInterval -match '^\d+$' -and [int]$newInterval -ge 10) {
                    $config.retry_delay_seconds = [int]$newInterval
                    Save-Config $config
                    Write-Host "$(Get-Translation 'config_saved')" -ForegroundColor Green
                    Start-Sleep -Seconds 1
                }
            }
            "6" {
                Clear-Host
                Write-Host "$(Get-Translation 'prompt_image'):" -ForegroundColor Cyan
                Write-Host "  1. $(Get-Translation 'image_ubuntu24')"
                Write-Host "  2. $(Get-Translation 'image_oracle10')"
                Write-Host "  3. $(Get-Translation 'image_debian')"
                Write-Host "  4. $(Get-Translation 'image_more')"
                $imageChoice = Read-Host "Choice (1-4)"

                if ($imageChoice -eq "1") { $config.image = "ubuntu24" }
                elseif ($imageChoice -eq "2") { $config.image = "oracle10" }
                elseif ($imageChoice -eq "3") { $config.image = "debian12" }
                elseif ($imageChoice -eq "4") {
                    # More options submenu
                    Clear-Host
                    Write-Host "$(Get-Translation 'image_more')" -ForegroundColor Cyan
                    Write-Host "  1. $(Get-Translation 'image_ubuntu22')"
                    Write-Host "  2. $(Get-Translation 'image_ubuntu20')"
                    Write-Host "  3. $(Get-Translation 'image_oracle9')"
                    Write-Host "  4. $(Get-Translation 'image_oracle8')"
                    Write-Host "  5. $(Get-Translation 'image_rocky9')"
                    Write-Host "  6. $(Get-Translation 'image_rocky8')"
                    Write-Host "  7. $(Get-Translation 'image_rhel9')"
                    Write-Host "  8. $(Get-Translation 'image_rhel8')"
                    $moreChoice = Read-Host "Choice (1-8)"

                    switch ($moreChoice) {
                        "1" { $config.image = "ubuntu22" }
                        "2" { $config.image = "ubuntu20" }
                        "3" { $config.image = "oracle9" }
                        "4" { $config.image = "oracle8" }
                        "5" { $config.image = "rocky9" }
                        "6" { $config.image = "rocky8" }
                        "7" { $config.image = "rhel9" }
                        "8" { $config.image = "rhel8" }
                    }
                    $imageChoice = $moreChoice  # For validation below
                }

                if ($imageChoice -in @("1","2","3","4","5","6","7","8")) {
                    Save-Config $config
                    Write-Host "$(Get-Translation 'config_saved')" -ForegroundColor Green
                    Start-Sleep -Seconds 1
                }
            }
            "7" {
                Clear-Host
                Write-Host "$(Get-Translation 'prompt_language'):" -ForegroundColor Cyan
                Write-Host "  1. English"
                Write-Host "  2. Deutsch"
                $langChoice = Read-Host "Choice (1-2)"
                if ($langChoice -eq "1") {
                    $config.language = "EN"
                    $script:LANGUAGE = "EN"
                }
                elseif ($langChoice -eq "2") {
                    $config.language = "DE"
                    $script:LANGUAGE = "DE"
                }
                if ($langChoice -in @("1","2")) {
                    Save-Config $config
                    Write-Host "$(Get-Translation 'config_saved')" -ForegroundColor Green
                    Start-Sleep -Seconds 1
                }
            }
            "0" { return }
        }
    }
}

# ============================================================================
# EXECUTION FUNCTIONS
# ============================================================================

function Start-Foreground {
    if (-not (Check-ScriptExists)) { return }

    Write-MenuLog "Starting script in foreground mode"
    Write-Host "$(Get-Translation 'starting_fg')" -ForegroundColor Green
    Write-Host ""

    # Run Python script directly
    python $SCRIPT_PATH

    Write-MenuLog "Foreground script execution completed"
    Write-Host ""
    Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
    Read-Host
}

function Start-BackgroundJob {
    if (-not (Check-ScriptExists)) { return }

    # Check if job already running
    $existingJob = Get-Job -Name $JOB_NAME -ErrorAction SilentlyContinue
    if ($existingJob) {
        Write-MenuLog "Background job already running - skipping start" -level "WARNING"
        Write-Host "$(Get-Translation 'job_exists')" -ForegroundColor Yellow
        Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
        Read-Host
        return
    }

    Write-MenuLog "Starting background job"
    Write-Host "$(Get-Translation 'starting_bg')" -ForegroundColor Yellow

    # Start as PowerShell background job
    Start-Job -Name $JOB_NAME -ScriptBlock {
        param($scriptPath)
        python $scriptPath
    } -ArgumentList $SCRIPT_PATH | Out-Null

    Start-Sleep -Seconds 2

    Write-MenuLog "Background job started successfully (Job ID: $JOB_NAME)"
    Write-Host "$(Get-Translation 'job_started')" -ForegroundColor Green
    Write-Host ""
    Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
    Read-Host
}

function Start-TaskScheduler {
    if (-not (Check-ScriptExists)) { return }

    Write-MenuLog "Starting Task Scheduler setup"
    Write-Host "$(Get-Translation 'starting_task')" -ForegroundColor Magenta

    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $TASK_NAME -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-MenuLog "Removing existing task: $TASK_NAME" -level "WARNING"
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

        Write-MenuLog "Task Scheduler task created and started successfully"
        Write-Host "$(Get-Translation 'task_created')" -ForegroundColor Green
        Write-Host "$(Get-Translation 'task_started')" -ForegroundColor Green
    }
    catch {
        Write-MenuLog "Task Scheduler creation failed: $_" -level "ERROR"
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

    # Show current config
    Ensure-ConfigExists
    $config = Load-Config
    Write-Host ""
    Write-Host "  [i]  Current Config: $($config.region), $($config.ocpus) CPUs, $($config.memory_in_gbs)GB, $($config.retry_delay_seconds)s" -ForegroundColor Cyan

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

    Write-MenuLog "Stopping all running script instances"
    $stoppedAny = $false

    # Stop Background Job
    $job = Get-Job -Name $JOB_NAME -ErrorAction SilentlyContinue
    if ($job) {
        Write-Host "$(Get-Translation 'stop_bg')" -ForegroundColor Yellow
        Stop-Job -Name $JOB_NAME
        Remove-Job -Name $JOB_NAME -Force
        Write-MenuLog "Background job stopped"
        Write-Host "$(Get-Translation 'job_stopped')" -ForegroundColor Green
        $stoppedAny = $true
    }

    # Stop Task Scheduler
    $task = Get-ScheduledTask -TaskName $TASK_NAME -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "$(Get-Translation 'stop_task')" -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $TASK_NAME -ErrorAction SilentlyContinue
        Write-MenuLog "Task Scheduler task stopped"
        Write-Host "$(Get-Translation 'stop_success')" -ForegroundColor Green
        $stoppedAny = $true
    }

    if (-not $stoppedAny) {
        Write-MenuLog "No running instances found to stop"
        Write-Host "$(Get-Translation 'stop_nothing')" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
    Read-Host
}

# ============================================================================
# MAIN LOOP
# ============================================================================

# Ensure config exists on startup
Ensure-ConfigExists

# Log menu startup
Write-MenuLog "Control Menu started (Language: $LANGUAGE)"

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
        "7" {
            Write-MenuLog "Configuration menu accessed"
            Show-ConfigMenu
        }
        "0" {
            Write-MenuLog "Control Menu exited by user"
            Clear-Host
            exit
        }
        default {
            Write-MenuLog "Invalid menu choice: $choice" -level "WARNING"
            Write-Host ""
            Write-Host "$(Get-Translation 'invalid')" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}
