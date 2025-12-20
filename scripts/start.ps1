# OCI Instance Sniper - Start Menu
# Einfaches Menue zur Region-Auswahl und Start

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Farben
function Write-Header { param($text) Write-Host "`n$('=' * 60)" -ForegroundColor Cyan; Write-Host "  $text" -ForegroundColor Cyan; Write-Host "$('=' * 60)`n" -ForegroundColor Cyan }
function Write-Option { param($num, $text, $info) Write-Host "  [$num] " -NoNewline -ForegroundColor Yellow; Write-Host "$text" -NoNewline; if ($info) { Write-Host " - $info" -ForegroundColor DarkGray } else { Write-Host "" } }

# Single-Key Input
function Get-SingleKey {
    Write-Host "  Auswahl: " -NoNewline -ForegroundColor White
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host $key.Character
    return $key.Character
}

# Regionen laden
$regionsFile = Join-Path $ProjectRoot "config\regions.json"
$regions = Get-Content $regionsFile -Raw | ConvertFrom-Json

# Konfigurierte Regionen filtern (mit subnet_id)
$configuredRegions = @()
foreach ($prop in $regions.PSObject.Properties) {
    if ($prop.Value.subnet_id -ne "") {
        $configuredRegions += @{
            id = $prop.Name
            name = $prop.Value.name
            image_id = $prop.Value.image_id
            subnet_id = $prop.Value.subnet_id
            compartment_id = $prop.Value.compartment_id
        }
    }
}

function Show-Menu {
    Clear-Host
    Write-Header "OCI Instance Sniper"

    Write-Host "  Konfigurierte Regionen:" -ForegroundColor White
    Write-Host ""

    $i = 1
    foreach ($region in $configuredRegions) {
        Write-Option $i $region.name $region.id
        $i++
    }

    Write-Host ""
    Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
    $nextNum = $configuredRegions.Count + 1
    Write-Option $nextNum "Alle Regionen gleichzeitig" "(parallel)"
    Write-Option ($nextNum + 1) "Logs anzeigen"
    Write-Option ($nextNum + 2) "Setup neue Region"
    Write-Option "0" "Beenden"
    Write-Host ""
}

function Start-Sniper {
    param($Region, [switch]$Background)

    $pythonScript = Join-Path $ScriptDir "oci-instance-sniper.py"
    $logFile = Join-Path $ProjectRoot "logs\$($Region.id)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

    # Logs-Ordner erstellen
    $logsDir = Join-Path $ProjectRoot "logs"
    if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir | Out-Null }

    # Umgebungsvariablen setzen
    $env:OCI_REGION = $Region.id
    $env:OCI_IMAGE_ID = $Region.image_id
    $env:OCI_SUBNET_ID = $Region.subnet_id
    $env:OCI_COMPARTMENT_ID = $Region.compartment_id
    $env:SNIPER_LOG_FILE = $logFile

    Write-Host "`n  Starte Sniper fuer $($Region.name)..." -ForegroundColor Green
    Write-Host "  Log: $logFile" -ForegroundColor DarkGray

    if ($Background) {
        Start-Process -FilePath "python" -ArgumentList $pythonScript -WindowStyle Hidden -RedirectStandardOutput $logFile -RedirectStandardError "$logFile.err"
        Write-Host "  [OK] Laeuft im Hintergrund" -ForegroundColor Green
    } else {
        & python $pythonScript 2>&1 | Tee-Object -FilePath $logFile
    }
}

function Start-AllRegions {
    Write-Host "`n  Starte alle konfigurierten Regionen im Hintergrund..." -ForegroundColor Green

    foreach ($region in $configuredRegions) {
        Start-Sniper -Region $region -Background
        Start-Sleep -Milliseconds 500
    }

    Write-Host "`n  [OK] Alle Regionen gestartet!" -ForegroundColor Green
    Write-Host "  Logs in: $ProjectRoot\logs\" -ForegroundColor DarkGray
    Write-Host "`n  Druecke eine Taste..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Logs {
    Write-Header "Logs"

    $logsDir = Join-Path $ProjectRoot "logs"
    if (-not (Test-Path $logsDir)) {
        Write-Host "  Keine Logs vorhanden." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    $logs = Get-ChildItem $logsDir -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 10

    if ($logs.Count -eq 0) {
        Write-Host "  Keine Logs vorhanden." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    $i = 1
    foreach ($log in $logs) {
        $size = [math]::Round($log.Length / 1KB, 1)
        Write-Option $i $log.Name "$($size) KB"
        $i++
    }
    Write-Host ""

    Write-Option "0" "Zurueck"
    $choice = Get-SingleKey
    if ($choice -eq "0") { return }

    $idx = [int]$choice - 1
    if ($idx -ge 0 -and $idx -lt $logs.Count) {
        $selectedLog = $logs[$idx].FullName
        Write-Host ""
        Write-Host "  === Letzte 30 Zeilen ===" -ForegroundColor Cyan
        Get-Content $selectedLog -Tail 30
        Write-Host ""
        Write-Host "  Druecke eine Taste..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Setup-Region {
    Write-Header "Neue Region einrichten"

    # Nicht konfigurierte Regionen zeigen
    $unconfigured = @()
    foreach ($prop in $regions.PSObject.Properties) {
        if ($prop.Value.subnet_id -eq "") {
            $unconfigured += @{ id = $prop.Name; name = $prop.Value.name }
        }
    }

    if ($unconfigured.Count -eq 0) {
        Write-Host "  Alle Regionen sind bereits konfiguriert!" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    $i = 1
    foreach ($r in $unconfigured) {
        Write-Option $i $r.name $r.id
        $i++
    }
    Write-Host ""

    Write-Option "0" "Abbrechen"
    $choice = Get-SingleKey
    if ($choice -eq "0") { return }

    $idx = [int]$choice - 1
    if ($idx -lt 0 -or $idx -ge $unconfigured.Count) { return }

    $selectedRegion = $unconfigured[$idx]

    Write-Host "`n  Region: $($selectedRegion.name) ($($selectedRegion.id))" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Du brauchst aus der OCI Console:" -ForegroundColor Yellow
    Write-Host "  1. Compartment OCID (Tenancy oder Sub-Compartment)"
    Write-Host "  2. Subnet OCID (VCN muss in der Region existieren)"
    Write-Host "  3. Image OCID (Ubuntu 24.04 aarch64)"
    Write-Host ""

    $compartment = Read-Host "  Compartment OCID"
    $subnet = Read-Host "  Subnet OCID"
    $image = Read-Host "  Image OCID"

    if ($compartment -eq "" -or $subnet -eq "" -or $image -eq "") {
        Write-Host "  [FEHLER] Alle Felder sind Pflicht!" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # In regions.json speichern
    $regions.($selectedRegion.id).compartment_id = $compartment
    $regions.($selectedRegion.id).subnet_id = $subnet
    $regions.($selectedRegion.id).image_id = $image

    $regions | ConvertTo-Json -Depth 3 | Set-Content $regionsFile -Encoding UTF8

    Write-Host "`n  [OK] Region $($selectedRegion.name) konfiguriert!" -ForegroundColor Green
    Start-Sleep -Seconds 2

    # Reload
    $script:regions = Get-Content $regionsFile -Raw | ConvertFrom-Json
    $script:configuredRegions = @()
    foreach ($prop in $regions.PSObject.Properties) {
        if ($prop.Value.subnet_id -ne "") {
            $script:configuredRegions += @{
                id = $prop.Name
                name = $prop.Value.name
                image_id = $prop.Value.image_id
                subnet_id = $prop.Value.subnet_id
                compartment_id = $prop.Value.compartment_id
            }
        }
    }
}

# Hauptschleife
while ($true) {
    Show-Menu
    $choice = Get-SingleKey

    $allIdx = $configuredRegions.Count + 1
    $logsIdx = $configuredRegions.Count + 2
    $setupIdx = $configuredRegions.Count + 3

    if ($choice -eq "0") {
        exit
    } elseif ($choice -eq [string]$allIdx) {
        Start-AllRegions
    } elseif ($choice -eq [string]$logsIdx) {
        Show-Logs
    } elseif ($choice -eq [string]$setupIdx) {
        Setup-Region
    } else {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $configuredRegions.Count) {
            $region = $configuredRegions[$idx]
            Write-Host ""
            Write-Option "1" "Vordergrund" "(sichtbar, Ctrl+C zum Stoppen)"
            Write-Option "2" "Hintergrund" "(versteckt, Log-Datei)"
            Write-Option "0" "Abbrechen"
            $mode = Get-SingleKey

            if ($mode -eq "1") {
                Start-Sniper -Region $region
            } elseif ($mode -eq "2") {
                Start-Sniper -Region $region -Background
                Write-Host "`n  Druecke eine Taste..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    }
}
