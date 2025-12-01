# OCI Instance Sniper - Multi-Instance Setup
# Creates and manages multiple instance configurations

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# Language setting
$LANGUAGE = "DE"  # or "EN"

# Translations
$translations = @{
    EN = @{
        title = "OCI Instance Sniper - Multi-Instance Setup"
        welcome = "This script helps you create multiple instance configurations for different regions."
        existing_instances = "Existing Instances"
        no_instances = "No instances configured yet."
        create_new = "Create New Instance"
        instance_name = "Enter instance name (e.g., frankfurt, paris, london)"
        name_invalid = "Invalid name. Use only letters, numbers, and hyphens."
        name_exists = "Instance '{0}' already exists!"
        select_region = "Select Region"
        ocpus = "Number of OCPUs (1-4, Free Tier max: 4 total)"
        memory = "Memory in GB (6-24, Free Tier max: 24 total)"
        retry_delay = "Retry delay in seconds (recommended: 60)"
        max_attempts = "Max attempts (1440 = 24 hours at 60s delay)"
        language_choice = "Language (EN/DE)"
        reserved_ip = "Reserved IP OCID (optional, press Enter to skip)"
        reserved_ip_hint = "Tip: Run 'oci network public-ip list --compartment-id <COMPARTMENT_ID> --scope REGION --all'"
        creating = "Creating instance configuration..."
        success = "Instance '{0}' created successfully!"
        location = "Location: {0}"
        next_steps = "Next Steps"
        step1 = "1. Start instance: .\scripts\manage-instances.ps1 -Start {0}"
        step2 = "2. Check status: .\scripts\manage-instances.ps1 -Status"
        step3 = "3. View logs: .\scripts\manage-instances.ps1 -Logs {0}"
        create_another = "Create another instance? (y/n)"
        goodbye = "Setup complete. Use manage-instances.ps1 to control your instances."
    }
    DE = @{
        title = "OCI Instance Sniper - Multi-Instance Setup"
        welcome = "Dieses Script hilft dir, mehrere Instance-Konfigurationen für verschiedene Regionen zu erstellen."
        existing_instances = "Vorhandene Instances"
        no_instances = "Noch keine Instances konfiguriert."
        create_new = "Neue Instance erstellen"
        instance_name = "Instance-Name eingeben (z.B. frankfurt, paris, london)"
        name_invalid = "Ungültiger Name. Nur Buchstaben, Zahlen und Bindestriche erlaubt."
        name_exists = "Instance '{0}' existiert bereits!"
        select_region = "Region auswählen"
        ocpus = "Anzahl OCPUs (1-4, Free Tier max: 4 gesamt)"
        memory = "Arbeitsspeicher in GB (6-24, Free Tier max: 24 gesamt)"
        retry_delay = "Wiederholungsverzögerung in Sekunden (empfohlen: 60)"
        max_attempts = "Max. Versuche (1440 = 24 Stunden bei 60s Verzögerung)"
        language_choice = "Sprache (EN/DE)"
        reserved_ip = "Reservierte IP OCID (optional, Enter zum Überspringen)"
        reserved_ip_hint = "Tipp: Führe aus 'oci network public-ip list --compartment-id <COMPARTMENT_ID> --scope REGION --all'"
        creating = "Erstelle Instance-Konfiguration..."
        success = "Instance '{0}' erfolgreich erstellt!"
        location = "Speicherort: {0}"
        next_steps = "Nächste Schritte"
        step1 = "1. Instance starten: .\scripts\manage-instances.ps1 -Start {0}"
        step2 = "2. Status prüfen: .\scripts\manage-instances.ps1 -Status"
        step3 = "3. Logs ansehen: .\scripts\manage-instances.ps1 -Logs {0}"
        create_another = "Weitere Instance erstellen? (j/n)"
        goodbye = "Setup abgeschlossen. Nutze manage-instances.ps1 um deine Instances zu steuern."
    }
}

function t($key) {
    return $translations[$LANGUAGE][$key]
}

# Project root
$projectRoot = Split-Path -Parent $PSScriptRoot
$instancesDir = Join-Path $projectRoot "instances"

# Create instances directory if not exists
if (-not (Test-Path $instancesDir)) {
    New-Item -ItemType Directory -Path $instancesDir | Out-Null
}

# Clear screen and show title
Clear-Host
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host (t "title") -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host (t "welcome") -ForegroundColor Yellow
Write-Host ""

# Main loop
while ($true) {
    # List existing instances
    $existingInstances = Get-ChildItem -Path $instancesDir -Directory -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Gray
    Write-Host (t "existing_instances") -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Gray

    if ($existingInstances) {
        foreach ($instance in $existingInstances) {
            $configPath = Join-Path $instance.FullName "config\sniper-config.json"
            if (Test-Path $configPath) {
                $config = Get-Content $configPath -Raw | ConvertFrom-Json
                Write-Host "  ✓ $($instance.Name)" -ForegroundColor Green -NoNewline
                Write-Host " - Region: $($config.region)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "  " (t "no_instances") -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Gray
    Write-Host (t "create_new") -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Gray
    Write-Host ""

    # Get instance name
    do {
        $instanceName = Read-Host (t "instance_name")
        $instanceName = $instanceName.Trim().ToLower()

        if ($instanceName -notmatch '^[a-z0-9\-]+$') {
            Write-Host (t "name_invalid") -ForegroundColor Red
            continue
        }

        $instancePath = Join-Path $instancesDir $instanceName
        if (Test-Path $instancePath) {
            Write-Host ((t "name_exists") -f $instanceName) -ForegroundColor Red
            continue
        }

        break
    } while ($true)

    # Region selection
    Write-Host ""
    Write-Host (t "select_region") -ForegroundColor Cyan
    Write-Host "  1. eu-frankfurt-1 (Frankfurt)"
    Write-Host "  2. eu-paris-1 (Paris)"
    Write-Host "  3. eu-amsterdam-1 (Amsterdam)"
    Write-Host "  4. uk-london-1 (London)"
    Write-Host "  5. us-ashburn-1 (Ashburn)"
    Write-Host "  6. us-phoenix-1 (Phoenix)"

    do {
        $regionChoice = Read-Host "Choice (1-6)"
        $regions = @("eu-frankfurt-1", "eu-paris-1", "eu-amsterdam-1", "uk-london-1", "us-ashburn-1", "us-phoenix-1")
        if ($regionChoice -match '^\d$' -and [int]$regionChoice -ge 1 -and [int]$regionChoice -le 6) {
            $region = $regions[[int]$regionChoice - 1]
            break
        }
    } while ($true)

    # Collect configuration
    Write-Host ""
    $ocpus = Read-Host (t "ocpus")
    if ([string]::IsNullOrWhiteSpace($ocpus)) { $ocpus = 2 }

    $memory = Read-Host (t "memory")
    if ([string]::IsNullOrWhiteSpace($memory)) { $memory = 12 }

    $retryDelay = Read-Host (t "retry_delay")
    if ([string]::IsNullOrWhiteSpace($retryDelay)) { $retryDelay = 60 }

    $maxAttempts = Read-Host (t "max_attempts")
    if ([string]::IsNullOrWhiteSpace($maxAttempts)) { $maxAttempts = 1440 }

    $langChoice = Read-Host (t "language_choice")
    if ([string]::IsNullOrWhiteSpace($langChoice)) { $langChoice = $LANGUAGE }

    Write-Host ""
    Write-Host (t "reserved_ip_hint") -ForegroundColor Gray
    $reservedIpOcid = Read-Host (t "reserved_ip")
    if ([string]::IsNullOrWhiteSpace($reservedIpOcid)) { $reservedIpOcid = "" }

    # Create instance structure
    Write-Host ""
    Write-Host (t "creating") -ForegroundColor Yellow

    $configDir = Join-Path $instancePath "config"
    $logsDir = Join-Path $instancePath "logs"

    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null

    # Create config file
    $config = @{
        instance_name = "oci-$instanceName"
        ocpus = [int]$ocpus
        memory_in_gbs = [int]$memory
        image = "ubuntu24"
        retry_delay_seconds = [int]$retryDelay
        max_attempts = [int]$maxAttempts
        region = $region
        language = $langChoice.ToUpper()
        reserved_public_ip_ocid = $reservedIpOcid
    }

    $configPath = Join-Path $configDir "sniper-config.json"
    $config | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8

    # Success message
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host ((t "success") -f $instanceName) -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host ((t "location") -f $instancePath) -ForegroundColor Gray
    Write-Host ""
    Write-Host (t "next_steps") -ForegroundColor Cyan
    Write-Host ((t "step1") -f $instanceName) -ForegroundColor White
    Write-Host (t "step2") -ForegroundColor White
    Write-Host ((t "step3") -f $instanceName) -ForegroundColor White
    Write-Host ""

    # Ask to create another
    $createAnother = Read-Host (t "create_another")
    if ($createAnother -notmatch '^[yj]') {
        break
    }

    Clear-Host
}

Write-Host ""
Write-Host (t "goodbye") -ForegroundColor Green
Write-Host ""
