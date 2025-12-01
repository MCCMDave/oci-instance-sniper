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
    [switch]$Interactive
)

$ErrorActionPreference = "Stop"

# Language setting
$LANGUAGE = "DE"  # or "EN"

# Translations
$translations = @{
    EN = @{
        title = "OCI Instance Sniper - Instance Manager"
        no_instances = "No instances found. Run setup-instance.ps1 first."
        status_title = "Instance Status"
        running = "RUNNING"
        stopped = "STOPPED"
        instance = "Instance"
        region = "Region"
        pid = "PID"
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
        press_enter = "Press Enter to continue..."
    }
    DE = @{
        title = "OCI Instance Sniper - Instance Manager"
        no_instances = "Keine Instances gefunden. Führe zuerst setup-instance.ps1 aus."
        status_title = "Instance Status"
        running = "LÄUFT"
        stopped = "GESTOPPT"
        instance = "Instance"
        region = "Region"
        pid = "PID"
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
        press_enter = "Enter drücken zum Fortfahren..."
    }
}

function t($key) {
    return $translations[$LANGUAGE][$key]
}

# Project paths
$projectRoot = Split-Path -Parent $PSScriptRoot
$instancesDir = Join-Path $projectRoot "instances"
$scriptPath = Join-Path $projectRoot "scripts\oci-instance-sniper.py"
$stateFile = Join-Path $projectRoot "instances\.state.json"

# Check if instances exist
if (-not (Test-Path $instancesDir)) {
    Write-Host (t "no_instances") -ForegroundColor Red
    exit 1
}

# Get all instances
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

# Get instance state
function Get-InstanceState {
    if (Test-Path $stateFile) {
        return Get-Content $stateFile -Raw | ConvertFrom-Json
    }
    return @{}
}

# Save instance state
function Save-InstanceState($state) {
    $state | ConvertTo-Json | Set-Content -Path $stateFile -Encoding UTF8
}

# Check if instance is running
function Test-InstanceRunning($instanceName) {
    $state = Get-InstanceState
    if ($state.PSObject.Properties.Name -contains $instanceName) {
        $pid = $state.$instanceName.pid
        try {
            $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
            return $process -ne $null
        } catch {
            return $false
        }
    }
    return $false
}

# Start instance
function Start-Instance($instance) {
    Write-Host ((t "starting") -f $instance.Name) -ForegroundColor Yellow

    # Set environment variable for config path
    $env:SNIPER_CONFIG_PATH = $instance.ConfigPath

    # Create log file path
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $logFile = Join-Path $instance.LogDir "sniper_$timestamp.log"

    # Start Python script in background
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "python"
    $startInfo.Arguments = "`"$scriptPath`""
    $startInfo.WorkingDirectory = $projectRoot
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.EnvironmentVariables["SNIPER_CONFIG_PATH"] = $instance.ConfigPath

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo

    # Redirect output to log file
    $outputBuilder = New-Object System.Text.StringBuilder
    $errorBuilder = New-Object System.Text.StringBuilder

    $outputHandler = {
        if (-not [string]::IsNullOrEmpty($EventArgs.Data)) {
            $EventArgs.Data | Out-File -FilePath $using:logFile -Append -Encoding UTF8
        }
    }

    $errorHandler = {
        if (-not [string]::IsNullOrEmpty($EventArgs.Data)) {
            $EventArgs.Data | Out-File -FilePath $using:logFile -Append -Encoding UTF8
        }
    }

    Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action $outputHandler | Out-Null
    Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action $errorHandler | Out-Null

    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()

    # Save state
    $state = Get-InstanceState
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

# Stop instance
function Stop-Instance($instanceName) {
    Write-Host ((t "stopping") -f $instanceName) -ForegroundColor Yellow

    $state = Get-InstanceState
    if ($state.PSObject.Properties.Name -contains $instanceName) {
        $pid = $state.$instanceName.pid
        try {
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
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

# Show status
function Show-Status {
    Clear-Host
    Write-Host ""
    Write-Host "=" * 100 -ForegroundColor Cyan
    Write-Host (t "status_title") -ForegroundColor Cyan
    Write-Host "=" * 100 -ForegroundColor Cyan
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
            (t "pid") = if ($isRunning) { $state.($instance.Name).pid } else { "-" }
            (t "started") = if ($isRunning) { $state.($instance.Name).started } else { "-" }
        }
        $statusTable += $statusObj
    }

    $statusTable | Format-Table -AutoSize

    Write-Host "=" * 100 -ForegroundColor Cyan
    Write-Host ""
}

# View logs
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

# Interactive menu
function Show-InteractiveMenu {
    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "=" * 80 -ForegroundColor Cyan
        Write-Host (t "menu_title") -ForegroundColor Cyan
        Write-Host "=" * 80 -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  1. " (t "menu_start") -ForegroundColor White
        Write-Host "  2. " (t "menu_stop") -ForegroundColor White
        Write-Host "  3. " (t "menu_status") -ForegroundColor White
        Write-Host "  4. " (t "menu_logs") -ForegroundColor White
        Write-Host "  5. " (t "menu_stopall") -ForegroundColor White
        Write-Host "  0. " (t "menu_exit") -ForegroundColor White
        Write-Host ""

        $choice = Read-Host "Choice"

        switch ($choice) {
            "1" {
                # Start instance
                $instances = Get-Instances
                Write-Host ""
                Write-Host ((t "select_instance") -f "starten") -ForegroundColor Yellow
                for ($i = 0; $i -lt $instances.Count; $i++) {
                    Write-Host "  $($i + 1). $($instances[$i].Name) - $($instances[$i].Config.region)"
                }
                $selection = Read-Host "Choice"
                if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $instances.Count) {
                    $instance = $instances[[int]$selection - 1]
                    Start-Instance $instance
                    Read-Host (t "press_enter")
                }
            }
            "2" {
                # Stop instance
                $instances = Get-Instances
                Write-Host ""
                Write-Host ((t "select_instance") -f "stoppen") -ForegroundColor Yellow
                for ($i = 0; $i -lt $instances.Count; $i++) {
                    Write-Host "  $($i + 1). $($instances[$i].Name)"
                }
                $selection = Read-Host "Choice"
                if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $instances.Count) {
                    Stop-Instance $instances[[int]$selection - 1].Name
                    Read-Host (t "press_enter")
                }
            }
            "3" {
                # Show status
                Show-Status
                Read-Host (t "press_enter")
            }
            "4" {
                # View logs
                $instances = Get-Instances
                Write-Host ""
                Write-Host ((t "select_instance") -f "Logs anzeigen") -ForegroundColor Yellow
                for ($i = 0; $i -lt $instances.Count; $i++) {
                    Write-Host "  $($i + 1). $($instances[$i].Name)"
                }
                $selection = Read-Host "Choice"
                if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $instances.Count) {
                    Show-Logs $instances[[int]$selection - 1].Name
                }
            }
            "5" {
                # Stop all
                Write-Host ""
                Write-Host (t "stopping_all") -ForegroundColor Yellow
                $instances = Get-Instances
                foreach ($instance in $instances) {
                    Stop-Instance $instance.Name
                }
                Read-Host (t "press_enter")
            }
            "0" {
                return
            }
        }
    }
}

# Main logic
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
