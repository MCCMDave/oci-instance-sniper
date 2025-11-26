#Requires -Version 5.1
<#
.SYNOPSIS
    OCI Instance Sniper - Complete Setup Script
.DESCRIPTION
    Installs OCI CLI, configures credentials, fetches OCIDs, and updates the Python script
    Everything you need in ONE file!
.NOTES
    Author: Dave Vaupel
    Date: 2025-11-24
    
.EXAMPLE
    .\setup.ps1
    
    Runs the complete setup process
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================================
# LANGUAGE SELECTION
# ============================================================================

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "      OCI INSTANCE SNIPER - SETUP" -ForegroundColor Cyan
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
        Write-Host "Exiting in 5 seconds... / Wird in 5 Sekunden beendet..." -ForegroundColor Yellow
        for ($i = 5; $i -gt 0; $i--) {
            Write-Host "  $i..." -ForegroundColor Gray
            Start-Sleep -Seconds 1
        }
        exit 0
    }
}

Clear-Host

# ============================================================================
# LANGUAGE CONFIGURATION
# ============================================================================

# Language strings
$strings = @{
    EN = @{
        title = "OCI INSTANCE SNIPER - COMPLETE SETUP"
        steps_title = "This script will:"
        step1 = "Check/Install Python"
        step2 = "Install OCI CLI"
        step3 = "Configure OCI API credentials"
        step4 = "Fetch your OCIDs automatically"
        step5 = "Configure the Python script"
        continue_prompt = "Press ENTER to continue or Ctrl+C to cancel..."
        quick_mode = "Quick setup mode - updating OCIDs..."
        checking_python = "Checking Python installation..."
        python_found = "Python found:"
        python_warning = "Python not found"
        installing_python = "Installing Python..."
        python_installed = "Python installed!"
        python_error = "Could not install Python automatically"
        python_manual = "Please install Python manually from: https://www.python.org/downloads/"
        python_path_note = "Make sure to check 'Add Python to PATH' during installation!"
        upgrading_pip = "Upgrading pip..."
        installing_oci = "Installing OCI CLI..."
        oci_installed = "OCI CLI already installed:"
        oci_installing = "Installing OCI CLI (this may take 1-2 minutes)..."
        oci_success = "OCI CLI installed:"
        oci_error = "OCI CLI installation failed"
        restart_prompt = "Please restart PowerShell and try again"
        config_credentials = "Configuring OCI credentials..."
        config_exists = "Using existing OCI configuration"
        config_wizard = "Starting OCI setup wizard..."
        config_need = "You will need:"
        config_user = "User OCID (cloud.oracle.com -> User Icon -> My Profile)"
        config_tenancy = "Tenancy OCID (User Icon -> Tenancy: [Name])"
        config_region = "Region (e.g., eu-frankfurt-1)"
        config_error = "OCI config was not created"
        config_manual = "Please run 'oci setup config' manually"
        key_upload_title = "IMPORTANT: Upload your PUBLIC KEY to OCI Console!"
        key_upload_1 = "Go to: https://cloud.oracle.com"
        key_upload_2 = "User Icon -> My Profile -> API Keys -> Add API Key"
        key_upload_3 = "Select 'Paste Public Key'"
        key_upload_4 = "Paste the key below:"
        key_begin = "--- BEGIN PUBLIC KEY ---"
        key_end = "--- END PUBLIC KEY ---"
        key_copied = "Public key copied to clipboard!"
        key_prompt = "Press ENTER after you've uploaded the key to OCI Console..."
        credentials_ok = "OCI credentials configured"
        fetching_ocids = "Fetching OCIDs from your OCI account..."
        tenancy_ok = "Tenancy OCID:"
        fetching_vcn = "Fetching VCN..."
        vcn_found = "VCN found"
        vcn_error = "No VCN found in your OCI account"
        vcn_create = "Please create a VCN first:"
        vcn_step1 = "Go to OCI Console -> Networking -> Virtual Cloud Networks"
        vcn_step2 = "Click 'Create VCN'"
        vcn_step3 = "Use 'VCN Wizard' for quick setup"
        vcn_rerun = "Then run this script again."
        fetching_subnet = "Fetching Subnet..."
        subnet_ok = "Subnet OCID:"
        subnet_error = "No Subnet found"
        subnet_create = "Please create a Subnet in your VCN first"
        fetching_image = "Fetching Ubuntu 24.04 Image..."
        image_ok = "Image OCID:"
        image_warning = "Could not fetch Ubuntu 24.04 image automatically"
        image_manual = "Please enter the Image OCID manually:"
        image_step1 = "Go to OCI Console -> Compute -> Instances -> Create Instance"
        image_step2 = "Change Image -> Canonical Ubuntu -> 24.04"
        image_step3 = "Copy the Image OCID"
        image_prompt = "Paste Image OCID here"
        image_error = "No Image OCID provided"
        updating_script = "Updating Python script..."
        script_error = "Python script not found:"
        script_location = "Please make sure oci-instance-sniper.py is in the same folder as this script"
        backup_created = "Backup created:"
        script_updated = "Python script updated"
        script_update_error = "Failed to update Python script"
        setup_complete = "SETUP COMPLETE!"
        config_summary = "Configuration Summary:"
        compartment = "Compartment:"
        subnet = "Subnet:"
        image = "Image:"
        ssh_key = "SSH Key:"
        configured = "Configured [OK]"
        next_steps = "NEXT STEPS:"
        run_sniper = "Start the Control Menu:"
        monitor_log = "Monitor the log:"
        important = "IMPORTANT: Finding an ARM instance can take hours or days!"
        best_times = "Best success rates: overnight and on weekends"
        good_luck = "Good luck!"
        press_close = "Press ENTER to close..."
    }
    DE = @{
        title = "OCI INSTANCE SNIPER - KOMPLETTES SETUP"
        steps_title = "Dieses Script wird:"
        step1 = "Python prüfen/installieren"
        step2 = "OCI CLI installieren"
        step3 = "OCI API-Zugangsdaten konfigurieren"
        step4 = "Deine OCIDs automatisch abrufen"
        step5 = "Das Python-Script konfigurieren"
        continue_prompt = "Drücke ENTER zum Fortfahren oder Strg+C zum Abbrechen..."
        quick_mode = "Schnell-Setup-Modus - Aktualisiere OCIDs..."
        checking_python = "Prüfe Python-Installation..."
        python_found = "Python gefunden:"
        python_warning = "Python nicht gefunden"
        installing_python = "Installiere Python..."
        python_installed = "Python installiert!"
        python_error = "Konnte Python nicht automatisch installieren"
        python_manual = "Bitte installiere Python manuell von: https://www.python.org/downloads/"
        python_path_note = "Stelle sicher, dass 'Add Python to PATH' während der Installation aktiviert ist!"
        upgrading_pip = "Aktualisiere pip..."
        installing_oci = "Installiere OCI CLI..."
        oci_installed = "OCI CLI bereits installiert:"
        oci_installing = "Installiere OCI CLI (dauert ca. 1-2 Minuten)..."
        oci_success = "OCI CLI installiert:"
        oci_error = "OCI CLI Installation fehlgeschlagen"
        restart_prompt = "Bitte starte PowerShell neu und versuche es erneut"
        config_credentials = "Konfiguriere OCI-Zugangsdaten..."
        config_exists = "Verwende existierende OCI-Konfiguration"
        config_wizard = "Starte OCI Setup-Wizard..."
        config_need = "Du benötigst:"
        config_user = "User OCID (cloud.oracle.com -> Benutzer-Symbol -> Mein Profil)"
        config_tenancy = "Tenancy OCID (Benutzer-Symbol -> Tenancy: [Name])"
        config_region = "Region (z.B. eu-frankfurt-1)"
        config_error = "OCI-Konfiguration wurde nicht erstellt"
        config_manual = "Bitte führe 'oci setup config' manuell aus"
        key_upload_title = "WICHTIG: Lade deinen ÖFFENTLICHEN SCHLÜSSEL in die OCI Console hoch!"
        key_upload_1 = "Gehe zu: https://cloud.oracle.com"
        key_upload_2 = "Benutzer-Symbol -> Mein Profil -> API Keys -> API Key hinzufügen"
        key_upload_3 = "Wähle 'Öffentlichen Schlüssel einfügen'"
        key_upload_4 = "Füge den folgenden Schlüssel ein:"
        key_begin = "--- ANFANG ÖFFENTLICHER SCHLÜSSEL ---"
        key_end = "--- ENDE ÖFFENTLICHER SCHLÜSSEL ---"
        key_copied = "Öffentlicher Schlüssel in Zwischenablage kopiert!"
        key_prompt = "Drücke ENTER nachdem du den Schlüssel in die OCI Console hochgeladen hast..."
        credentials_ok = "OCI-Zugangsdaten konfiguriert"
        fetching_ocids = "Rufe OCIDs von deinem OCI-Account ab..."
        tenancy_ok = "Tenancy OCID:"
        fetching_vcn = "Rufe VCN ab..."
        vcn_found = "VCN gefunden"
        vcn_error = "Kein VCN in deinem OCI-Account gefunden"
        vcn_create = "Bitte erstelle zuerst ein VCN:"
        vcn_step1 = "Gehe zur OCI Console -> Networking -> Virtual Cloud Networks"
        vcn_step2 = "Klicke 'VCN erstellen'"
        vcn_step3 = "Nutze den 'VCN Wizard' für schnelles Setup"
        vcn_rerun = "Führe dann dieses Script erneut aus."
        fetching_subnet = "Rufe Subnet ab..."
        subnet_ok = "Subnet OCID:"
        subnet_error = "Kein Subnet gefunden"
        subnet_create = "Bitte erstelle zuerst ein Subnet in deinem VCN"
        fetching_image = "Rufe Ubuntu 24.04 Image ab..."
        image_ok = "Image OCID:"
        image_warning = "Konnte Ubuntu 24.04 Image nicht automatisch abrufen"
        image_manual = "Bitte gib die Image OCID manuell ein:"
        image_step1 = "Gehe zur OCI Console -> Compute -> Instances -> Instance erstellen"
        image_step2 = "Ändere Image -> Canonical Ubuntu -> 24.04"
        image_step3 = "Kopiere die Image OCID"
        image_prompt = "Füge Image OCID hier ein"
        image_error = "Keine Image OCID angegeben"
        updating_script = "Aktualisiere Python-Script..."
        script_error = "Python-Script nicht gefunden:"
        script_location = "Stelle sicher, dass oci-instance-sniper.py im gleichen Ordner wie dieses Script liegt"
        backup_created = "Backup erstellt:"
        script_updated = "Python-Script aktualisiert"
        script_update_error = "Fehler beim Aktualisieren des Python-Scripts"
        setup_complete = "SETUP ABGESCHLOSSEN!"
        config_summary = "Konfigurations-Übersicht:"
        compartment = "Compartment:"
        subnet = "Subnet:"
        image = "Image:"
        ssh_key = "SSH Key:"
        configured = "Konfiguriert [OK]"
        next_steps = "NÄCHSTE SCHRITTE:"
        run_sniper = "Starte das Kontrollmenü:"
        monitor_log = "Log überwachen:"
        important = "WICHTIG: Eine ARM-Instanz zu finden kann Stunden oder Tage dauern!"
        best_times = "Beste Erfolgsraten: nachts und am Wochenende"
        good_luck = "Viel Erfolg!"
        press_close = "Drücke ENTER zum Schließen..."
    }
}

$s = $strings[$LANGUAGE]

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "      $($s.title)" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Detect if this is first-time setup
$isFirstRun = $false
$configPath = "$env:USERPROFILE\.oci\config"

try {
    $pythonVersion = python --version 2>&1
    $hasPython = $true
} catch {
    $hasPython = $false
    $isFirstRun = $true
}

try {
    $ociVersion = oci --version 2>&1
    $hasOCI = $true
} catch {
    $hasOCI = $false
    $isFirstRun = $true
}

$hasConfig = Test-Path $configPath

if (-not $hasConfig) {
    $isFirstRun = $true
}

if ($isFirstRun) {
    Write-Host "$($s.steps_title)" -ForegroundColor Yellow
    Write-Host "  1. $($s.step1)" -ForegroundColor White
    Write-Host "  2. $($s.step2)" -ForegroundColor White
    Write-Host "  3. $($s.step3)" -ForegroundColor White
    Write-Host "  4. $($s.step4)" -ForegroundColor White
    Write-Host "  5. $($s.step5)" -ForegroundColor White
    Write-Host ""
    Write-Host "$($s.continue_prompt)" -ForegroundColor Yellow
    Read-Host
} else {
    Write-Host "$($s.quick_mode)" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# STEP 1: CHECK PYTHON
# ============================================================================

Write-Host "`n[1/5] $($s.checking_python)" -ForegroundColor Cyan

try {
    $pythonVersion = python --version 2>&1
    Write-Host "  [OK] $($s.python_found) $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "  [WARNING] $($s.python_warning)" -ForegroundColor Yellow
    Write-Host "  $($s.installing_python)" -ForegroundColor Yellow
    
    try {
        winget --version | Out-Null
        winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Host "  [OK] $($s.python_installed)" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] $($s.python_error)" -ForegroundColor Red
        Write-Host "  $($s.python_manual)" -ForegroundColor Yellow
        Write-Host "  $($s.python_path_note)" -ForegroundColor Yellow
        exit 1
    }
}

# Upgrade pip
Write-Host "  $($s.upgrading_pip)" -ForegroundColor Gray
python -m pip install --upgrade pip --quiet 2>&1 | Out-Null

# ============================================================================
# STEP 2: INSTALL OCI CLI
# ============================================================================

Write-Host "`n[2/5] $($s.installing_oci)" -ForegroundColor Cyan

try {
    $ociVersion = oci --version 2>&1
    Write-Host "  [OK] $($s.oci_installed) $ociVersion" -ForegroundColor Green
}
catch {
    Write-Host "  $($s.oci_installing)" -ForegroundColor Yellow
    pip install oci-cli

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    try {
        $ociVersion = oci --version 2>&1
        Write-Host "  [OK] $($s.oci_success) $ociVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] $($s.oci_error)" -ForegroundColor Red
        Write-Host "  $($s.restart_prompt)" -ForegroundColor Yellow
        exit 1
    }
}

# ============================================================================
# STEP 3: CONFIGURE OCI CREDENTIALS
# ============================================================================

Write-Host "`n[3/5] $($s.config_credentials)" -ForegroundColor Cyan

$configPath = "$env:USERPROFILE\.oci\config"

if (Test-Path $configPath) {
    Write-Host "  [OK] $($s.config_exists)" -ForegroundColor Green
    $skipKeyPrompt = $true
}
else {
    Write-Host ""
    Write-Host "  $($s.config_wizard)" -ForegroundColor Yellow
    Write-Host "  $($s.config_need)" -ForegroundColor Yellow
    Write-Host "    - $($s.config_user)" -ForegroundColor White
    Write-Host "    - $($s.config_tenancy)" -ForegroundColor White
    Write-Host "    - $($s.config_region)" -ForegroundColor White
    Write-Host ""

    oci setup config
}

# Verify config was created
if (-not (Test-Path $configPath)) {
    Write-Host "  [ERROR] $($s.config_error)" -ForegroundColor Red
    Write-Host "  $($s.config_manual)" -ForegroundColor Yellow
    exit 1
}

# Display public key (only for new configs)
$publicKeyPath = "$env:USERPROFILE\.oci\oci_api_key_public.pem"
if ((Test-Path $publicKeyPath) -and (-not $skipKeyPrompt)) {
    Write-Host ""
    Write-Host "  ============================================================================" -ForegroundColor Yellow
    Write-Host "  $($s.key_upload_title)" -ForegroundColor Yellow
    Write-Host "  ============================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. $($s.key_upload_1)" -ForegroundColor White
    Write-Host "  2. $($s.key_upload_2)" -ForegroundColor White
    Write-Host "  3. $($s.key_upload_3)" -ForegroundColor White
    Write-Host "  4. $($s.key_upload_4)" -ForegroundColor White
    Write-Host ""
    Write-Host "  $($s.key_begin)" -ForegroundColor Yellow
    Get-Content $publicKeyPath
    Write-Host "  $($s.key_end)" -ForegroundColor Yellow
    Write-Host ""

    # Copy to clipboard
    Get-Content $publicKeyPath | Set-Clipboard
    Write-Host "  [OK] $($s.key_copied)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  $($s.key_prompt)" -ForegroundColor Yellow
    Read-Host
}

Write-Host "  [OK] $($s.credentials_ok)" -ForegroundColor Green

# ============================================================================
# STEP 4: FETCH OCIDs
# ============================================================================

Write-Host "`n[4/5] $($s.fetching_ocids)" -ForegroundColor Cyan

# Read tenancy from config
$configContent = Get-Content $configPath
$tenancyLine = $configContent | Select-String "tenancy="
$TENANCY_OCID = ($tenancyLine -split "=")[1].Trim()

Write-Host "  [OK] $($s.tenancy_ok) $TENANCY_OCID" -ForegroundColor Green

# Fetch VCN and Subnet
Write-Host "  $($s.fetching_vcn)" -ForegroundColor Gray
try {
    $vcnId = oci network vcn list `
        --compartment-id $TENANCY_OCID `
        --query "data[0].id" `
        --raw-output 2>&1

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($vcnId)) {
        throw "No VCN found"
    }

    Write-Host "  [OK] $($s.vcn_found)" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] $($s.vcn_error)" -ForegroundColor Red
    Write-Host "  $($s.vcn_create)" -ForegroundColor Yellow
    Write-Host "    1. $($s.vcn_step1)" -ForegroundColor White
    Write-Host "    2. $($s.vcn_step2)" -ForegroundColor White
    Write-Host "    3. $($s.vcn_step3)" -ForegroundColor White
    Write-Host ""
    Write-Host "  $($s.vcn_rerun)" -ForegroundColor Yellow
    exit 1
}

Write-Host "  $($s.fetching_subnet)" -ForegroundColor Gray
try {
    $SUBNET_ID = oci network subnet list `
        --compartment-id $TENANCY_OCID `
        --vcn-id $vcnId `
        --query "data[0].id" `
        --raw-output 2>&1

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($SUBNET_ID)) {
        throw "No Subnet found"
    }

    Write-Host "  [OK] $($s.subnet_ok) $SUBNET_ID" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] $($s.subnet_error)" -ForegroundColor Red
    Write-Host "  $($s.subnet_create)" -ForegroundColor Yellow
    exit 1
}

# Fetch Ubuntu 24.04 Image
Write-Host "  $($s.fetching_image)" -ForegroundColor Gray
try {
    $IMAGE_ID = oci compute image list `
        --compartment-id $TENANCY_OCID `
        --operating-system "Canonical Ubuntu" `
        --operating-system-version "24.04" `
        --shape "VM.Standard.A1.Flex" `
        --query "data[0].id" `
        --raw-output 2>&1

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($IMAGE_ID)) {
        # Fallback: Try without shape filter
        $IMAGE_ID = oci compute image list `
            --compartment-id $TENANCY_OCID `
            --operating-system "Canonical Ubuntu" `
            --operating-system-version "24.04" `
            --query "data[0].id" `
            --raw-output 2>&1
    }

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($IMAGE_ID)) {
        throw "No Ubuntu 24.04 image found"
    }

    Write-Host "  [OK] $($s.image_ok) $IMAGE_ID" -ForegroundColor Green
}
catch {
    Write-Host "  [WARNING] $($s.image_warning)" -ForegroundColor Yellow
    Write-Host "  $($s.image_manual)" -ForegroundColor Yellow
    Write-Host "    1. $($s.image_step1)" -ForegroundColor White
    Write-Host "    2. $($s.image_step2)" -ForegroundColor White
    Write-Host "    3. $($s.image_step3)" -ForegroundColor White
    Write-Host ""
    $IMAGE_ID = Read-Host "  $($s.image_prompt)"

    if ([string]::IsNullOrWhiteSpace($IMAGE_ID)) {
        Write-Host "  [ERROR] $($s.image_error)" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# STEP 5: UPDATE PYTHON SCRIPT
# ============================================================================

Write-Host "`n[5/5] $($s.updating_script)" -ForegroundColor Cyan

$scriptPath = "oci-instance-sniper.py"

if (-not (Test-Path $scriptPath)) {
    Write-Host "  [ERROR] $($s.script_error) $scriptPath" -ForegroundColor Red
    Write-Host "  $($s.script_location)" -ForegroundColor Yellow
    exit 1
}

try {
    # Read script
    $scriptContent = Get-Content $scriptPath -Raw -Encoding UTF8

    # Update OCIDs - Match both placeholder and real OCID formats
    $scriptContent = $scriptContent -replace 'COMPARTMENT_ID = ".*?"', "COMPARTMENT_ID = `"$TENANCY_OCID`""
    $scriptContent = $scriptContent -replace 'IMAGE_ID = ".*?"', "IMAGE_ID = `"$IMAGE_ID`""
    $scriptContent = $scriptContent -replace 'SUBNET_ID = ".*?"', "SUBNET_ID = `"$SUBNET_ID`""

    # Update SSH Public Key - Smart detection
    $sshKeyPath = $null

    # 1. Check for any .pub file in script directory (portable setup)
    $pubFiles = Get-ChildItem -Path "." -Filter "*.pub" -File -ErrorAction SilentlyContinue
    if ($pubFiles) {
        $sshKeyPath = $pubFiles[0].FullName
        Write-Host "  [INFO] Found SSH key: $($pubFiles[0].Name)" -ForegroundColor Cyan
    }

    # 2. Fallback: Standard OCI location
    if (-not $sshKeyPath) {
        $standardPath = "$env:USERPROFILE\.oci\id_rsa.pub"
        if (Test-Path $standardPath) {
            $sshKeyPath = $standardPath
            Write-Host "  [INFO] Found SSH key at standard OCI location" -ForegroundColor Cyan
        }
    }

    # 3. If still not found: Ask user
    if (-not $sshKeyPath) {
        Write-Host ""
        Write-Host "  [INFO] No SSH key found automatically" -ForegroundColor Yellow
        Write-Host "  Options:" -ForegroundColor Yellow
        Write-Host "    1. Enter path to your SSH public key (.pub file)" -ForegroundColor White
        Write-Host "    2. Press ENTER to skip (configure manually later)" -ForegroundColor White
        Write-Host ""
        $userKeyPath = Read-Host "  Path to SSH key (or ENTER to skip)"

        if ($userKeyPath -and (Test-Path $userKeyPath)) {
            $sshKeyPath = $userKeyPath
        }
        elseif ($userKeyPath) {
            Write-Host "  [WARNING] File not found: $userKeyPath" -ForegroundColor Red
            Write-Host "  Continuing without SSH key configuration..." -ForegroundColor Yellow
        }
    }

    # Configure SSH key if found
    if ($sshKeyPath) {
        $sshPublicKey = Get-Content $sshKeyPath -Raw
        $sshPublicKey = $sshPublicKey.Trim()
        $scriptContent = $scriptContent -replace 'SSH_PUBLIC_KEY = """.*?"""', "SSH_PUBLIC_KEY = ```"```"```"$sshPublicKey```"```"```""
        Write-Host "  [OK] SSH Public Key configured from: $sshKeyPath" -ForegroundColor Green
    }
    else {
        Write-Host "  [WARNING] SSH Key not configured" -ForegroundColor Yellow
        Write-Host "  You can manually add it to oci-instance-sniper.py later" -ForegroundColor Yellow
    }

    # Create backup
    $backupPath = "oci-instance-sniper.py.backup"
    Copy-Item $scriptPath $backupPath -Force
    Write-Host "  [OK] $($s.backup_created) $backupPath" -ForegroundColor Green

    # Save updated script
    $scriptContent | Out-File $scriptPath -Encoding UTF8 -NoNewline
    Write-Host "  [OK] $($s.script_updated)" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] $($s.script_update_error)" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "                    $($s.setup_complete)" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "$($s.config_summary)" -ForegroundColor Yellow
Write-Host "  $($s.compartment) $TENANCY_OCID" -ForegroundColor White
Write-Host "  $($s.subnet)      $SUBNET_ID" -ForegroundColor White
Write-Host "  $($s.image)       $IMAGE_ID" -ForegroundColor White
Write-Host "  $($s.ssh_key)     $($s.configured)" -ForegroundColor Green
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "$($s.next_steps)" -ForegroundColor Yellow
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "$($s.run_sniper)" -ForegroundColor Yellow
Write-Host "  .\control-menu.ps1" -ForegroundColor White
Write-Host ""
Write-Host "$($s.monitor_log)" -ForegroundColor Yellow
Write-Host "  Get-Content -Path oci-sniper.log -Wait -Tail 20" -ForegroundColor White
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[!] $($s.important)" -ForegroundColor Yellow
Write-Host "    $($s.best_times)" -ForegroundColor Yellow
Write-Host ""
Write-Host "$($s.good_luck)" -ForegroundColor Green
Write-Host ""
Write-Host "$($s.press_close)" -ForegroundColor Yellow
Read-Host
