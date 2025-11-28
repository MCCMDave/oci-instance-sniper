# OCI Instance Sniper - Control Menu v1.6
# Bilingual PowerShell menu system with configuration management
# Supports: Foreground, Background Jobs, Task Scheduler, Status, Logs, Configuration
#
# Changelog v1.6:
# - Consolidated 3 start options into 1 submenu (better UX)
# - Start submenu: Foreground / Background / Task Scheduler
# - Main menu now shows all options (Config reset now visible)
# - Improved menu structure and navigation
#
# Changelog v1.5:
# - Added comprehensive logging to control-menu.log
# - Improved error handling and status reporting
# - Better integration with main Python script

# ============================================================================
# LANGUAGE SELECTION
# ============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "      OCI INSTANCE SNIPER - CONTROL MENU" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Select Language / Sprache wählen:" -ForegroundColor Yellow
Write-Host "  1. English" -ForegroundColor White
Write-Host "  2. Deutsch" -ForegroundColor White
Write-Host "  0. Exit / Beenden" -ForegroundColor White
Write-Host ""
Write-Host "Press 1, 2, or 0 / Drücke 1, 2 oder 0" -ForegroundColor Gray

# Wait for single keypress (no Enter required)
$langChoice = ""
while ($langChoice -notin @("1", "2", "0")) {
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $langChoice = $key.Character
}

Write-Host "Selected / Gewählt: $langChoice" -ForegroundColor Green

switch ($langChoice) {
    "1" { $LANGUAGE = "EN" }
    "2" { $LANGUAGE = "DE" }
    "0" {
        Write-Host ""
        Write-Host "Exiting in 3 seconds... / Wird in 3 Sekunden beendet..." -ForegroundColor Yellow
        for ($i = 3; $i -gt 0; $i--) {
            Write-Host "  $i..." -ForegroundColor Gray
            Start-Sleep -Seconds 1
        }
        exit 0
    }
}

Clear-Host

# ============================================================================
# CONFIGURATION
# ============================================================================

# Script Configuration
$SCRIPT_NAME = "oci-instance-sniper.py"
$projectRoot = Split-Path -Parent $PSScriptRoot
# Always look for the Python script in the same directory as control-menu.ps1
$SCRIPT_PATH = Join-Path $PSScriptRoot $SCRIPT_NAME
$LOG_FILE = Join-Path $projectRoot "oci-sniper.log"
# Config and logs now in scripts/ directory (same as control-menu.ps1)
$CONFIG_FILE = Join-Path $PSScriptRoot "config" "sniper-config.json"
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
    # Ensure config directory exists
    $configDir = Split-Path $CONFIG_FILE -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
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
        title = "OCI Instance Sniper - Control Menu"
        menu_1 = "Start Script"
        menu_2 = "Check Status"
        menu_3 = "View Live Logs"
        menu_4 = "Stop Script"
        menu_5 = "Configuration"
        menu_0 = "Exit"
        prompt = "Enter choice (1-5, 0=Exit)"
        invalid = "Invalid choice! Please enter 1-5 or 0."

        # Start submenu
        start_title = "Start Script - Select Mode"
        start_1 = "Foreground (see live output)"
        start_2 = "Background (runs hidden until PC off)"
        start_3 = "Task Scheduler (survives reboots)"
        start_0 = "Back to Main Menu"
        start_prompt = "Enter choice (1-3, 0=Back)"

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
        config_8 = "Reset OCIDs (reconfigure credentials)"
        config_0 = "Back to Main Menu"
        config_prompt = "Enter option to change (0=Back)"
        config_saved = "Configuration saved successfully!"
        ocid_reset_confirm = "Are you sure you want to reset OCIDs? This will delete ~/.oci/config (Y/N)"
        ocid_reset_success = "OCIDs reset! Please run the Python script to reconfigure."
        ocid_reset_cancelled = "Reset cancelled."

        # Config prompts
        prompt_instance_name = "Enter instance name (ENTER to cancel)"
        prompt_ocpus = "Enter OCPUs 1-4 for Free Tier (ENTER to cancel)"
        prompt_memory = "Enter Memory in GB 1-24 for Free Tier (ENTER to cancel)"
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
        exiting = "Exiting in 3 seconds..."
    }
    DE = @{
        title = "OCI Instance Sniper - Kontrollmenü"
        menu_1 = "Skript starten"
        menu_2 = "Status prüfen"
        menu_3 = "Live-Logs anzeigen"
        menu_4 = "Skript stoppen"
        menu_5 = "Konfiguration"
        menu_0 = "Beenden"
        prompt = "Wähle Option (1-5, 0=Beenden)"
        invalid = "Ungültige Auswahl! Bitte 1-5 oder 0 eingeben."

        # Start submenu
        start_title = "Skript starten - Modus wählen"
        start_1 = "Vordergrund (Live-Ausgabe sichtbar)"
        start_2 = "Hintergrund (läuft versteckt bis PC aus)"
        start_3 = "Aufgabenplanung (überlebt Neustarts)"
        start_0 = "Zurück zum Hauptmenü"
        start_prompt = "Wahl eingeben (1-3, 0=Zurück)"

        # Configuration menu
        config_title = "Konfigurationsmenü"
        config_current = "Aktuelle Konfiguration"
        config_1 = "Instanz-Name"
        config_2 = "CPUs (OCPUs)"
        config_3 = "Arbeitsspeicher (GB)"
        config_4 = "Region"
        config_5 = "Wiederholungsintervall (Sekunden)"
        config_6 = "Image-Typ"
        config_7 = "Sprache"
        config_8 = "OCIDs zurücksetzen (Zugangsdaten neu eingeben)"
        config_0 = "Zurück zum Hauptmenü"
        config_prompt = "Option zum Ändern wählen (0=Zurück)"
        config_saved = "Konfiguration erfolgreich gespeichert!"
        ocid_reset_confirm = "Möchtest du die OCIDs wirklich zurücksetzen? Dies löscht ~/.oci/config (J/N)"
        ocid_reset_success = "OCIDs zurückgesetzt! Bitte führe das Python-Skript aus, um neu zu konfigurieren."
        ocid_reset_cancelled = "Zurücksetzen abgebrochen."

        # Config prompts
        prompt_instance_name = "Instanz-Name eingeben (ENTER zum Abbrechen)"
        prompt_ocpus = "OCPUs eingeben 1-4 für Free Tier (ENTER zum Abbrechen)"
        prompt_memory = "Arbeitsspeicher in GB eingeben 1-24 für Free Tier (ENTER zum Abbrechen)"
        prompt_region = "Region auswählen"
        prompt_interval = "Wiederholungsintervall in Sekunden (30/60/120 empfohlen)"
        prompt_image = "Image auswählen"
        prompt_language = "Sprache auswählen"

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
        status_bg_running = "Hintergrund-Job: LÄUFT"
        status_bg_stopped = "Hintergrund-Job: LÄUFT NICHT"
        status_task_running = "Aufgabenplanung: LÄUFT"
        status_task_stopped = "Aufgabenplanung: LÄUFT NICHT"
        status_task_notfound = "Aufgabenplanung: NICHT KONFIGURIERT"

        # Logs
        log_title = "Live-Logs (Strg+C zum Stoppen)"
        log_not_found = "Log-Datei nicht gefunden. Skript möglicherweise noch nicht gestartet."

        # Stop
        stop_title = "Stoppe Skript"
        stop_bg = "Stoppe Hintergrund-Job..."
        stop_task = "Stoppe Aufgabenplanungs-Task..."
        stop_success = "Skript erfolgreich gestoppt!"
        stop_nothing = "Keine laufenden Instanzen gefunden."

        # Task Scheduler
        task_exists = "Task existiert bereits. Entferne alten Task..."
        task_created = "Aufgabenplanungs-Task erfolgreich erstellt!"
        task_started = "Task gestartet! Prüfe Status mit Option 4."
        task_create_error = "Fehler beim Erstellen des Tasks. PowerShell als Administrator ausführen!"

        # Background Job
        job_exists = "Hintergrund-Job läuft bereits!"
        job_started = "Hintergrund-Job erfolgreich gestartet!"
        job_stopped = "Hintergrund-Job gestoppt."
        job_notfound = "Kein Hintergrund-Job gefunden."

        press_enter = "Enter drücken zum Fortfahren..."
        exiting = "Wird in 3 Sekunden beendet..."
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
    Write-Host "  2. $(Get-Translation 'menu_2')" -ForegroundColor Cyan
    Write-Host "  3. $(Get-Translation 'menu_3')" -ForegroundColor Blue
    Write-Host "  4. $(Get-Translation 'menu_4')" -ForegroundColor Red
    Write-Host "  5. $(Get-Translation 'menu_5')" -ForegroundColor White
    Write-Host ""
    Write-Host "  0. $(Get-Translation 'menu_0')" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-StartMenu {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  $(Get-Translation 'start_title')" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  1. $(Get-Translation 'start_1')" -ForegroundColor Green
    Write-Host "  2. $(Get-Translation 'start_2')" -ForegroundColor Yellow
    Write-Host "  3. $(Get-Translation 'start_3')" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  0. $(Get-Translation 'start_0')" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-StartSubmenu {
    while ($true) {
        Show-StartMenu

        # Wait for single keypress (no Enter required)
        $choice = ""
        while ($choice -notin @("0", "1", "2", "3")) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $choice = $key.Character
        }
        Write-Host "$choice" -ForegroundColor Green

        switch ($choice) {
            "1" { Start-Foreground; return }
            "2" { Start-BackgroundJob; return }
            "3" { Start-TaskScheduler; return }
            "0" { return }
            default {
                Write-Host ""
                Write-Host "$(Get-Translation 'invalid')" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
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
        Write-Host "  $(Get-Translation 'config_current'):" -ForegroundColor Cyan
        Write-Host "  $($config.instance_name) | $($config.ocpus) CPU | $($config.memory_in_gbs)GB | $($config.region) | $($config.retry_delay_seconds)s | $($config.image) | $($config.language)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  1. $(Get-Translation 'config_1')" -ForegroundColor Green
        Write-Host "  2. $(Get-Translation 'config_2')" -ForegroundColor Green
        Write-Host "  3. $(Get-Translation 'config_3')" -ForegroundColor Green
        Write-Host "  4. $(Get-Translation 'config_4')" -ForegroundColor Green
        Write-Host "  5. $(Get-Translation 'config_5')" -ForegroundColor Green
        Write-Host "  6. $(Get-Translation 'config_6')" -ForegroundColor Green
        Write-Host "  7. $(Get-Translation 'config_7')" -ForegroundColor Green
        Write-Host "  8. $(Get-Translation 'config_8')" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  0. $(Get-Translation 'config_0')" -ForegroundColor DarkGray
        Write-Host ""

        # Wait for single keypress for config menu navigation (no Enter required)
        $choice = ""
        while ($choice -notin @("0", "1", "2", "3", "4", "5", "6", "7", "8")) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $choice = $key.Character
        }
        Write-Host "$choice" -ForegroundColor Green

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
                    Write-Host ""
                    Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
                    Read-Host
                }
            }
            "8" {
                Clear-Host
                Write-Host ""
                Write-Host "$(Get-Translation 'ocid_reset_confirm')" -ForegroundColor Yellow
                $confirmation = Read-Host

                if ($confirmation -match '^[YyJj]$') {
                    $ociConfigPath = Join-Path $env:USERPROFILE ".oci\config"

                    if (Test-Path $ociConfigPath) {
                        try {
                            Remove-Item $ociConfigPath -Force
                            Write-Host ""
                            Write-Host "$(Get-Translation 'ocid_reset_success')" -ForegroundColor Green
                        } catch {
                            Write-Host ""
                            Write-Host "Error: $_" -ForegroundColor Red
                        }
                    } else {
                        Write-Host ""
                        Write-Host "~/.oci/config not found (already deleted or never configured)" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host ""
                    Write-Host "$(Get-Translation 'ocid_reset_cancelled')" -ForegroundColor Gray
                }

                Write-Host ""
                Write-Host "$(Get-Translation 'press_enter')" -ForegroundColor DarkGray
                Read-Host
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

    # Wait for single keypress for menu navigation (no Enter required)
    $choice = ""
    while ($choice -notin @("0", "1", "2", "3", "4", "5")) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $choice = $key.Character
    }
    Write-Host "$choice" -ForegroundColor Green

    switch ($choice) {
        "1" {
            Write-MenuLog "Start submenu accessed"
            Show-StartSubmenu
        }
        "2" { Show-Status }
        "3" { Show-LiveLogs }
        "4" { Stop-Script }
        "5" {
            Write-MenuLog "Configuration menu accessed"
            Show-ConfigMenu
        }
        "0" {
            Write-MenuLog "Control Menu exited by user"
            Write-Host ""
            Write-Host "$(Get-Translation 'exiting')" -ForegroundColor Yellow
            for ($i = 3; $i -gt 0; $i--) {
                Write-Host "  $i..." -ForegroundColor Gray
                Start-Sleep -Seconds 1
            }
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
