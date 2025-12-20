# OCI Instance Sniper - Start Menu
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Config laden
$configFile = Join-Path $ProjectRoot "config\sniper-config.json"
$regionsFile = Join-Path $ProjectRoot "config\regions.json"
$config = Get-Content $configFile -Raw | ConvertFrom-Json
$regionsData = Get-Content $regionsFile -Raw | ConvertFrom-Json

# ============================================
# HELPER
# ============================================
function Get-Key {
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return $key.Character
}

# ============================================
# SSH KEY CHECK
# ============================================
function Ensure-SshKey {
    # Bereits in Config?
    if ($config.ssh_public_key -and $config.ssh_public_key.Length -gt 100) {
        $env:SSH_PUBLIC_KEY = $config.ssh_public_key
        return $true
    }

    # Standard SSH-Key Pfade pruefen
    $sshPaths = @(
        (Join-Path $env:USERPROFILE ".ssh\oracle-ssh.pub"),
        (Join-Path $env:USERPROFILE ".ssh\id_rsa.pub"),
        (Join-Path $env:USERPROFILE ".ssh\id_ed25519.pub"),
        (Join-Path $env:USERPROFILE ".ssh\id_ecdsa.pub")
    )

    foreach ($path in $sshPaths) {
        if (Test-Path $path) {
            $key = (Get-Content $path -Raw).Trim()
            if ($key.Length -gt 100) {
                # In Config speichern
                $config | Add-Member -NotePropertyName "ssh_public_key" -NotePropertyValue $key -Force
                $config | ConvertTo-Json -Depth 3 | Set-Content $configFile -Encoding UTF8
                $env:SSH_PUBLIC_KEY = $key
                Write-Host "  [OK] SSH-Key geladen: $path" -ForegroundColor Green
                Start-Sleep -Seconds 1
                return $true
            }
        }
    }

    # Kein Key gefunden - interaktiv abfragen
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Yellow
    Write-Host "    SSH Public Key nicht gefunden!" -ForegroundColor Yellow
    Write-Host "  ============================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Key generieren (ssh-keygen)" -ForegroundColor Yellow
    Write-Host "  [2] Key manuell eingeben" -ForegroundColor Yellow
    Write-Host "  [0] Abbrechen" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Auswahl: " -NoNewline

    $choice = Get-Key
    Write-Host $choice

    switch ($choice) {
        "1" {
            $keyPath = Join-Path $env:USERPROFILE ".ssh\id_rsa"
            Write-Host ""
            Write-Host "  Generiere SSH-Key..." -ForegroundColor Cyan
            & ssh-keygen -t rsa -b 4096 -f $keyPath -N '""'

            if (Test-Path "$keyPath.pub") {
                $key = (Get-Content "$keyPath.pub" -Raw).Trim()
                $config | Add-Member -NotePropertyName "ssh_public_key" -NotePropertyValue $key -Force
                $config | ConvertTo-Json -Depth 3 | Set-Content $configFile -Encoding UTF8
                $env:SSH_PUBLIC_KEY = $key
                Write-Host "  [OK] SSH-Key generiert!" -ForegroundColor Green
                Start-Sleep -Seconds 2
                return $true
            }
        }
        "2" {
            Write-Host ""
            Write-Host "  Paste SSH Public Key (ssh-rsa AAAA...):" -ForegroundColor Cyan
            Write-Host ""
            $key = Read-Host "  Key"

            if ($key.Length -gt 100 -and $key -match "^ssh-(rsa|ed25519)|^ecdsa-") {
                $config | Add-Member -NotePropertyName "ssh_public_key" -NotePropertyValue $key -Force
                $config | ConvertTo-Json -Depth 3 | Set-Content $configFile -Encoding UTF8
                $env:SSH_PUBLIC_KEY = $key
                Write-Host "  [OK] SSH-Key gespeichert!" -ForegroundColor Green
                Start-Sleep -Seconds 2
                return $true
            } else {
                Write-Host "  [FEHLER] Ungueltiger Key!" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }

    return $false
}

# ============================================
# SPRACHAUSWAHL
# ============================================
function Ensure-Language {
    # Bereits in Config?
    if ($config.language -and $config.language -ne "") {
        return
    }

    Clear-Host
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host "    LANGUAGE / SPRACHE" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] English" -ForegroundColor Yellow
    Write-Host "  [2] Deutsch" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Auswahl: " -NoNewline

    $choice = Get-Key
    Write-Host $choice

    $lang = if ($choice -eq "2") { "DE" } else { "EN" }

    $config | Add-Member -NotePropertyName "language" -NotePropertyValue $lang -Force
    $config | ConvertTo-Json -Depth 3 | Set-Content $configFile -Encoding UTF8

    Write-Host ""
    $msg = if ($lang -eq "DE") { "Deutsch gewaehlt" } else { "English selected" }
    Write-Host "  [OK] $msg" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

# Konfigurierte Regionen als Array
$configuredRegions = @()
foreach ($prop in $regionsData.PSObject.Properties) {
    if ($prop.Value.subnet_id -and $prop.Value.subnet_id -ne "") {
        $configuredRegions += [PSCustomObject]@{
            id = $prop.Name
            name = $prop.Value.name
            image_id = $prop.Value.image_id
            subnet_id = $prop.Value.subnet_id
            compartment_id = $prop.Value.compartment_id
        }
    }
}

function Show-MainMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host "    OCI Instance Sniper" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ""

    # Regionen anzeigen
    for ($i = 0; $i -lt $configuredRegions.Count; $i++) {
        $num = $i + 1
        Write-Host "  [$num] $($configuredRegions[$i].name)" -ForegroundColor Yellow -NoNewline
        Write-Host " - $($configuredRegions[$i].id)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [8] Logs anzeigen" -ForegroundColor Yellow
    Write-Host "  [9] Setup neue Region" -ForegroundColor Yellow
    Write-Host "  [0] Beenden" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Auswahl: " -NoNewline
}

function Start-Sniper {
    param($Region, [switch]$Background)

    $pythonScript = Join-Path $ScriptDir "oci-instance-sniper.py"
    $logsDir = Join-Path $ProjectRoot "logs"
    if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir | Out-Null }

    $logFile = Join-Path $logsDir "$($Region.id)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

    $env:OCI_REGION = $Region.id
    $env:OCI_IMAGE_ID = $Region.image_id
    $env:OCI_SUBNET_ID = $Region.subnet_id
    $env:OCI_COMPARTMENT_ID = $Region.compartment_id

    Write-Host ""
    Write-Host "  Starte $($Region.name)..." -ForegroundColor Green
    Write-Host "  Log: $logFile" -ForegroundColor DarkGray

    if ($Background) {
        Start-Process -FilePath "python" -ArgumentList $pythonScript -WindowStyle Hidden -RedirectStandardOutput $logFile -RedirectStandardError "$logFile.err"
        Write-Host "  [OK] Im Hintergrund gestartet" -ForegroundColor Green
        Write-Host "`n  Taste druecken..." -ForegroundColor DarkGray
        $null = Get-Key
    } else {
        & python $pythonScript 2>&1 | Tee-Object -FilePath $logFile
    }
}

function Show-ModeMenu {
    param($Region)
    Write-Host ""
    Write-Host "  [1] Vordergrund (sichtbar)" -ForegroundColor Yellow
    Write-Host "  [2] Hintergrund (versteckt)" -ForegroundColor Yellow
    Write-Host "  [0] Abbrechen" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Auswahl: " -NoNewline

    $mode = Get-Key
    Write-Host $mode

    switch ($mode) {
        "1" { Start-Sniper -Region $Region }
        "2" { Start-Sniper -Region $Region -Background }
    }
}

function Show-Logs {
    Clear-Host
    Write-Host ""
    Write-Host "  === Logs ===" -ForegroundColor Cyan
    Write-Host ""

    $logsDir = Join-Path $ProjectRoot "logs"
    if (-not (Test-Path $logsDir)) {
        Write-Host "  Keine Logs vorhanden." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    $logs = @(Get-ChildItem $logsDir -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 9)

    if ($logs.Count -eq 0) {
        Write-Host "  Keine Logs vorhanden." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    for ($i = 0; $i -lt $logs.Count; $i++) {
        $num = $i + 1
        $size = [math]::Round($logs[$i].Length / 1KB, 1)
        Write-Host "  [$num] $($logs[$i].Name)" -ForegroundColor Yellow -NoNewline
        Write-Host " ($size KB)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  [0] Zurueck" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Auswahl: " -NoNewline

    $choice = Get-Key
    Write-Host $choice

    if ($choice -eq "0") { return }

    $idx = [int]::Parse($choice) - 1
    if ($idx -ge 0 -and $idx -lt $logs.Count) {
        Write-Host ""
        Write-Host "  === Letzte 30 Zeilen ===" -ForegroundColor Cyan
        Write-Host ""
        Get-Content $logs[$idx].FullName -Tail 30
        Write-Host ""
        Write-Host "  Taste druecken..." -ForegroundColor DarkGray
        $null = Get-Key
    }
}

function Setup-Region {
    Clear-Host
    Write-Host ""
    Write-Host "  === Neue Region ===" -ForegroundColor Cyan
    Write-Host ""

    $unconfigured = @()
    foreach ($prop in $regionsData.PSObject.Properties) {
        if (-not $prop.Value.subnet_id -or $prop.Value.subnet_id -eq "") {
            $unconfigured += [PSCustomObject]@{ id = $prop.Name; name = $prop.Value.name }
        }
    }

    if ($unconfigured.Count -eq 0) {
        Write-Host "  Alle Regionen konfiguriert!" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    for ($i = 0; $i -lt $unconfigured.Count; $i++) {
        $num = $i + 1
        Write-Host "  [$num] $($unconfigured[$i].name)" -ForegroundColor Yellow -NoNewline
        Write-Host " - $($unconfigured[$i].id)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  [0] Abbrechen" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Auswahl: " -NoNewline

    $choice = Get-Key
    Write-Host $choice

    if ($choice -eq "0") { return }

    $idx = [int]::Parse($choice) - 1
    if ($idx -lt 0 -or $idx -ge $unconfigured.Count) { return }

    $sel = $unconfigured[$idx]

    Write-Host ""
    Write-Host "  Region: $($sel.name)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Aus OCI Console:" -ForegroundColor DarkGray
    Write-Host "  - Compartment OCID"
    Write-Host "  - Subnet OCID"
    Write-Host "  - Image OCID (Ubuntu 24.04 aarch64)"
    Write-Host ""

    $compartment = Read-Host "  Compartment OCID"
    $subnet = Read-Host "  Subnet OCID"
    $image = Read-Host "  Image OCID"

    if ($compartment -eq "" -or $subnet -eq "" -or $image -eq "") {
        Write-Host "  [FEHLER] Alle Felder Pflicht!" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    $regionsData.($sel.id).compartment_id = $compartment
    $regionsData.($sel.id).subnet_id = $subnet
    $regionsData.($sel.id).image_id = $image

    $regionsData | ConvertTo-Json -Depth 3 | Set-Content $regionsFile -Encoding UTF8

    Write-Host ""
    Write-Host "  [OK] $($sel.name) konfiguriert!" -ForegroundColor Green
    Start-Sleep -Seconds 2

    # Reload
    $script:regionsData = Get-Content $regionsFile -Raw | ConvertFrom-Json
    $script:configuredRegions = @()
    foreach ($prop in $regionsData.PSObject.Properties) {
        if ($prop.Value.subnet_id -and $prop.Value.subnet_id -ne "") {
            $script:configuredRegions += [PSCustomObject]@{
                id = $prop.Name
                name = $prop.Value.name
                image_id = $prop.Value.image_id
                subnet_id = $prop.Value.subnet_id
                compartment_id = $prop.Value.compartment_id
            }
        }
    }
}

# SSH-Key pruefen vor Start
if (-not (Ensure-SshKey)) {
    Write-Host "  Kein SSH-Key konfiguriert. Beende." -ForegroundColor Red
    exit 1
}

# Sprache waehlen (einmalig)
Ensure-Language

# Hauptschleife
while ($true) {
    Show-MainMenu
    $choice = Get-Key
    Write-Host $choice

    switch ($choice) {
        "0" { exit }
        "8" { Show-Logs }
        "9" { Setup-Region }
        default {
            $idx = [int]::Parse($choice) - 1
            if ($idx -ge 0 -and $idx -lt $configuredRegions.Count) {
                Show-ModeMenu -Region $configuredRegions[$idx]
            }
        }
    }
}
