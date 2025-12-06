# OCI Instance Sniper - Multi-Instance Manager
# Start, stop, and monitor multiple instance configurations

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Start,

    [Parameter(Mandatory=$false)]
    [string]$Stop,

    [Parameter(Mandatory=$false)]
    [string]$Logs,

    [Parameter(Mandatory=$false)]
    [switch]$Status,

    [Parameter(Mandatory=$false)]
    [switch]$StopAll,

    [Parameter(Mandatory=$false)]
    [switch]$Interactive,

    [Parameter(Mandatory=$false)]
    [switch]$DebugMode
)

$ErrorActionPreference = "Stop"

# ============================================================================
# DEBUG LOGGING
# ============================================================================

function Write-DebugLog($message, $color = "Gray") {
    if ($DebugMode) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp DEBUG] $message" -ForegroundColor $color
    }
}

# ============================================================================
# LANGUAGE SELECTION
# ============================================================================

function Select-Language {
    Clear-Host
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "OCI Instance Sniper - Instance Manager" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select Language / Sprache wählen:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. English" -ForegroundColor White
    Write-Host "  2. Deutsch" -ForegroundColor White
    Write-Host ""
    Write-Host "Choice / Wahl: " -NoNewline -ForegroundColor White

    # Single-keypress input
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $choice = $key.Character

    Write-Host $choice
    Write-Host ""

    switch ($choice) {
        "1" { return "EN" }
        "2" { return "DE" }
        default { return "EN" }
    }
}

# Only ask for language in interactive mode
if ($Interactive -or (-not $Start -and -not $Stop -and -not $Logs -and -not $Status -and -not $StopAll)) {
    $LANGUAGE = Select-Language
} else {
    $LANGUAGE = "EN"  # Default for CLI commands
}

# ============================================================================
# TRANSLATIONS
# ============================================================================

$translations = @{
    EN = @{
        title = "OCI Instance Sniper - Instance Manager"
        no_instances = "No instances found. Run setup-instance.ps1 first."
        status_title = "Instance Status"
        running = "RUNNING"
        stopped = "STOPPED"
        instance = "Instance"
        region = "Region"
        process_id = "Process ID"
        started = "Started"
        log_file = "Log File"
        menu_title = "Instance Manager - Interactive Mode"
        menu_start = "Start Instance"
        menu_stop = "Stop Instance"
        menu_status = "Show Status"
        menu_logs = "View Logs"
        menu_stopall = "Stop All Instances"
        menu_exit = "Exit"
        select_instance = "Select instance to {0}"
        starting = "Starting instance '{0}'..."
        started_success = "Instance '{0}' started successfully!"
        started_pid = "Process ID: {0}"
        stopping = "Stopping instance '{0}'..."
        stopped_success = "Instance '{0}' stopped."
        not_running = "Instance '{0}' is not running."
        stopping_all = "Stopping all instances..."
        viewing_logs = "Viewing logs for '{0}' (Press Ctrl+C to exit)..."
        no_logs = "No logs found for '{0}'."
        press_enter = "Press any key to continue..."
    }
    DE = @{
        title = "OCI Instance Sniper - Instance Manager"
        no_instances = "Keine Instances gefunden. Führe zuerst setup-instance.ps1 aus."
        status_title = "Instance Status"
        running = "LÄUFT"
        stopped = "GESTOPPT"
        instance = "Instance"
        region = "Region"
        process_id = "Prozess-ID"
        started = "Gestartet"
        log_file = "Log-Datei"
        menu_title = "Instance Manager - Interaktiver Modus"
        menu_start = "Instance starten"
        menu_stop = "Instance stoppen"
        menu_status = "Status anzeigen"
        menu_logs = "Logs ansehen"
        menu_stopall = "Alle Instances stoppen"
        menu_exit = "Beenden"
        select_instance = "Instance zum {0} auswählen"
        starting = "Starte Instance '{0}'..."
        started_success = "Instance '{0}' erfolgreich gestartet!"
        started_pid = "Prozess-ID: {0}"
        stopping = "Stoppe Instance '{0}'..."
        stopped_success = "Instance '{0}' gestoppt."
        not_running = "Instance '{0}' läuft nicht."
        stopping_all = "Stoppe alle Instances..."
        viewing_logs = "Zeige Logs für '{0}' (Strg+C zum Beenden)..."
        no_logs = "Keine Logs gefunden für '{0}'."
        press_enter = "Beliebige Taste drücken..."
    }
}

function t($key) {
    return $translations[$LANGUAGE][$key]
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Read-SingleKey {
    param([string]$Prompt)
    Write-Host $Prompt -NoNewline -ForegroundColor White
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $choice = $key.Character
    Write-Host $choice
    return $choice
}

# ============================================================================
# PROJECT PATHS
# ============================================================================

$scriptsDir = Split-Path -Parent $PSScriptRoot
$projectRoot = Split-Path -Parent $scriptsDir
$instancesDir = Join-Path $projectRoot "instances"
$scriptPath = Join-Path $scriptsDir "oci-instance-sniper.py"
$stateFile = Join-Path $projectRoot "instances\.state.json"

# Check if instances exist
if (-not (Test-Path $instancesDir)) {
    Write-Host (t "no_instances") -ForegroundColor Red
    exit 1
}

# ============================================================================
# INSTANCE MANAGEMENT FUNCTIONS
# ============================================================================

function Get-Instances {
    $instances = @()
    Get-ChildItem -Path $instancesDir -Directory | ForEach-Object {
        $configPath = Join-Path $_.FullName "config\sniper-config.json"
        if (Test-Path $configPath) {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            $instances += @{
                Name = $_.Name
                Path = $_.FullName
                Config = $config
                ConfigPath = $configPath
                LogDir = Join-Path $_.FullName "logs"
            }
        }
    }
    return $instances
}

function Get-InstanceState {
    if (Test-Path $stateFile) {
        return Get-Content $stateFile -Raw | ConvertFrom-Json
    }
    return @{}
}

function Save-InstanceState($state) {
    $state | ConvertTo-Json | Set-Content -Path $stateFile -Encoding UTF8
}

function Test-InstanceRunning($instanceName) {
    $state = Get-InstanceState
    if ($state.PSObject.Properties.Name -contains $instanceName) {
        $processId = $state.$instanceName.pid
        try {
            $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
            return $process -ne $null
        } catch {
            return $false
        }
    }
    return $false
}

function Start-Instance($instance) {
    Write-Host ((t "starting") -f $instance.Name) -ForegroundColor Yellow
    Write-DebugLog "Instance Name: $($instance.Name)" "Cyan"
    Write-DebugLog "Config Path: $($instance.ConfigPath)" "Cyan"
    Write-DebugLog "Log Dir: $($instance.LogDir)" "Cyan"

    # Set environment variable for config path
    $env:SNIPER_CONFIG_PATH = $instance.ConfigPath
    Write-DebugLog "Set SNIPER_CONFIG_PATH: $($instance.ConfigPath)" "Green"

    # Create log file path
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $logFile = Join-Path $instance.LogDir "sniper_$timestamp.log"
    Write-DebugLog "Log File: $logFile" "Cyan"

    # Check if Python is available
    $pythonCheck = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCheck) {
        Write-Host "ERROR: Python not found in PATH!" -ForegroundColor Red
        Write-DebugLog "Python command not found" "Red"
        return
    }
    Write-DebugLog "Python found: $($pythonCheck.Source)" "Green"

    # Check if script exists
    if (-not (Test-Path $scriptPath)) {
        Write-Host "ERROR: Script not found: $scriptPath" -ForegroundColor Red
        Write-DebugLog "Script path invalid: $scriptPath" "Red"
        return
    }
    Write-DebugLog "Script found: $scriptPath" "Green"

    # Check if config exists
    if (-not (Test-Path $instance.ConfigPath)) {
        Write-Host "ERROR: Config not found: $($instance.ConfigPath)" -ForegroundColor Red
        Write-DebugLog "Config path invalid: $($instance.ConfigPath)" "Red"
        return
    }
    Write-DebugLog "Config found: $($instance.ConfigPath)" "Green"

    # Create log directory if needed
    if (-not (Test-Path $instance.LogDir)) {
        New-Item -ItemType Directory -Path $instance.LogDir -Force | Out-Null
        Write-DebugLog "Created log directory: $($instance.LogDir)" "Yellow"
    }

    # Start Python script in background with Start-Process (more reliable than Register-ObjectEvent)
    Write-DebugLog "Creating process with Start-Process..." "Cyan"
    Write-DebugLog "Command: python `"$scriptPath`"" "Cyan"
    Write-DebugLog "Working Dir: $projectRoot" "Cyan"
    Write-DebugLog "Config: $($instance.ConfigPath)" "Cyan"
    Write-DebugLog "Log: $logFile" "Cyan"

    # Set environment variable for this session (inherited by child process)
    $env:SNIPER_CONFIG_PATH = $instance.ConfigPath
    Write-DebugLog "Set SNIPER_CONFIG_PATH environment variable" "Green"

    try {
        # Create a dummy stdin file for non-interactive mode
        $dummyStdin = Join-Path $instance.LogDir "stdin.txt"
        "" | Out-File -FilePath $dummyStdin -Force

        # Start process and redirect output (including stdin to prevent TTY detection)
        $process = Start-Process -FilePath "python" `
            -ArgumentList "-u `"$scriptPath`"" `
            -WorkingDirectory $projectRoot `
            -WindowStyle Hidden `
            -PassThru `
            -RedirectStandardInput $dummyStdin `
            -RedirectStandardOutput $logFile `
            -RedirectStandardError "$logFile.error"

        Write-DebugLog "Process started successfully!" "Green"
        Write-DebugLog "Process ID: $($process.Id)" "Green"

        # Wait a moment to check if process is stable
        Start-Sleep -Milliseconds 500

        if ($process.HasExited) {
            Write-Host "ERROR: Process exited immediately (Exit Code: $($process.ExitCode))" -ForegroundColor Red
            Write-DebugLog "Process crashed immediately!" "Red"

            # Try to read error log
            if (Test-Path "$logFile.error") {
                $errorContent = Get-Content "$logFile.error" -Raw
                if ($errorContent) {
                    Write-Host "Error output:" -ForegroundColor Red
                    Write-Host $errorContent -ForegroundColor Red
                }
            }
            return
        }

        Write-DebugLog "Process is running stable" "Green"
    } catch {
        Write-Host "ERROR: Failed to start process: $_" -ForegroundColor Red
        Write-DebugLog "Exception: $_" "Red"
        return
    }

    # Save state
    $state = Get-InstanceState
    if (-not $state) { $state = @{} }
    $state | Add-Member -NotePropertyName $instance.Name -NotePropertyValue @{
        pid = $process.Id
        started = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        logFile = $logFile
        region = $instance.Config.region
    } -Force
    Save-InstanceState $state

    Write-Host ((t "started_success") -f $instance.Name) -ForegroundColor Green
    Write-Host ((t "started_pid") -f $process.Id) -ForegroundColor Gray
    Write-Host "Log: $logFile" -ForegroundColor Gray
}

function Stop-Instance($instanceName) {
    Write-Host ((t "stopping") -f $instanceName) -ForegroundColor Yellow

    $state = Get-InstanceState
    if ($state.PSObject.Properties.Name -contains $instanceName) {
        $processId = $state.$instanceName.pid
        try {
            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
            Write-Host ((t "stopped_success") -f $instanceName) -ForegroundColor Green

            # Remove from state
            $state.PSObject.Properties.Remove($instanceName)
            Save-InstanceState $state
        } catch {
            Write-Host ((t "not_running") -f $instanceName) -ForegroundColor Yellow
        }
    } else {
        Write-Host ((t "not_running") -f $instanceName) -ForegroundColor Yellow
    }
}

function Show-Status {
    Clear-Host
    Write-Host ""
    Write-Host ("=" * 100) -ForegroundColor Cyan
    Write-Host (t "status_title") -ForegroundColor Cyan
    Write-Host ("=" * 100) -ForegroundColor Cyan
    Write-Host ""

    $instances = Get-Instances
    $state = Get-InstanceState

    $statusTable = @()
    foreach ($instance in $instances) {
        $isRunning = Test-InstanceRunning $instance.Name
        $statusObj = [PSCustomObject]@{
            (t "instance") = $instance.Name
            (t "region") = $instance.Config.region
            "Status" = if ($isRunning) { (t "running") } else { (t "stopped") }
            (t "process_id") = if ($isRunning) { $state.($instance.Name).pid } else { "-" }
            (t "started") = if ($isRunning) { $state.($instance.Name).started } else { "-" }
        }
        $statusTable += $statusObj
    }

    $statusTable | Format-Table -AutoSize

    Write-Host ("=" * 100) -ForegroundColor Cyan
    Write-Host ""
}

function Show-Logs($instanceName) {
    $instances = Get-Instances
    $instance = $instances | Where-Object { $_.Name -eq $instanceName }

    if (-not $instance) {
        Write-Host "Instance '$instanceName' not found." -ForegroundColor Red
        return
    }

    $state = Get-InstanceState
    if ($state.PSObject.Properties.Name -contains $instanceName) {
        $logFile = $state.$instanceName.logFile
        if (Test-Path $logFile) {
            Write-Host ((t "viewing_logs") -f $instanceName) -ForegroundColor Yellow
            Get-Content -Path $logFile -Wait -Tail 20
        } else {
            Write-Host ((t "no_logs") -f $instanceName) -ForegroundColor Red
        }
    } else {
        Write-Host ((t "no_logs") -f $instanceName) -ForegroundColor Red
    }
}

# ============================================================================
# INTERACTIVE MENU
# ============================================================================

function Show-InteractiveMenu {
    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host ("=" * 80) -ForegroundColor Cyan
        Write-Host (t "menu_title") -ForegroundColor Cyan
        Write-Host ("=" * 80) -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  1. " (t "menu_start") -ForegroundColor White
        Write-Host "  2. " (t "menu_stop") -ForegroundColor White
        Write-Host "  3. " (t "menu_status") -ForegroundColor White
        Write-Host "  4. " (t "menu_logs") -ForegroundColor White
        Write-Host "  5. " (t "menu_stopall") -ForegroundColor White
        Write-Host "  0. " (t "menu_exit") -ForegroundColor White
        Write-Host ""

        $choice = Read-SingleKey "Choice: "

        switch ($choice) {
            "1" {
                # Start instance
                $instances = Get-Instances
                Write-Host ""
                Write-Host ""
                Write-Host ((t "select_instance") -f "starten") -ForegroundColor Yellow
                for ($i = 0; $i -lt $instances.Count; $i++) {
                    Write-Host "  $($i + 1). $($instances[$i].Name) - $($instances[$i].Config.region)" -ForegroundColor White
                }
                Write-Host ""
                $selection = Read-SingleKey "Choice: "
                if ($selection -match '^[1-9]$' -and [int]$selection -le $instances.Count) {
                    $instance = $instances[[int]$selection - 1]
                    Write-Host ""
                    Start-Instance $instance
                    Write-Host ""
                    Write-Host (t "press_enter") -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
            "2" {
                # Stop instance
                $instances = Get-Instances
                Write-Host ""
                Write-Host ""
                Write-Host ((t "select_instance") -f "stoppen") -ForegroundColor Yellow
                for ($i = 0; $i -lt $instances.Count; $i++) {
                    Write-Host "  $($i + 1). $($instances[$i].Name)" -ForegroundColor White
                }
                Write-Host ""
                $selection = Read-SingleKey "Choice: "
                if ($selection -match '^[1-9]$' -and [int]$selection -le $instances.Count) {
                    Write-Host ""
                    Stop-Instance $instances[[int]$selection - 1].Name
                    Write-Host ""
                    Write-Host (t "press_enter") -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
            "3" {
                # Show status
                Show-Status
                Write-Host (t "press_enter") -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" {
                # View logs
                $instances = Get-Instances
                Write-Host ""
                Write-Host ""
                Write-Host ((t "select_instance") -f "Logs anzeigen") -ForegroundColor Yellow
                for ($i = 0; $i -lt $instances.Count; $i++) {
                    Write-Host "  $($i + 1). $($instances[$i].Name)" -ForegroundColor White
                }
                Write-Host ""
                $selection = Read-SingleKey "Choice: "
                if ($selection -match '^[1-9]$' -and [int]$selection -le $instances.Count) {
                    Write-Host ""
                    Show-Logs $instances[[int]$selection - 1].Name
                }
            }
            "5" {
                # Stop all
                Write-Host ""
                Write-Host ""
                Write-Host (t "stopping_all") -ForegroundColor Yellow
                $instances = Get-Instances
                foreach ($instance in $instances) {
                    Stop-Instance $instance.Name
                }
                Write-Host ""
                Write-Host (t "press_enter") -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "0" {
                return
            }
        }
    }
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

if ($Interactive) {
    Show-InteractiveMenu
} elseif ($Start) {
    $instances = Get-Instances
    $instance = $instances | Where-Object { $_.Name -eq $Start }
    if ($instance) {
        Start-Instance $instance
    } else {
        Write-Host "Instance '$Start' not found." -ForegroundColor Red
    }
} elseif ($Stop) {
    Stop-Instance $Stop
} elseif ($StopAll) {
    $instances = Get-Instances
    foreach ($instance in $instances) {
        Stop-Instance $instance.Name
    }
} elseif ($Logs) {
    Show-Logs $Logs
} elseif ($Status) {
    Show-Status
} else {
    # Default: Show interactive menu
    Show-InteractiveMenu
}
