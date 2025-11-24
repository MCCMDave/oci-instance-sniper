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

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "      OCI INSTANCE SNIPER - COMPLETE SETUP" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "  1. Check/Install Python" -ForegroundColor White
Write-Host "  2. Install OCI CLI" -ForegroundColor White
Write-Host "  3. Configure OCI API credentials" -ForegroundColor White
Write-Host "  4. Fetch your OCIDs automatically" -ForegroundColor White
Write-Host "  5. Configure the Python script" -ForegroundColor White
Write-Host ""
Write-Host "Press ENTER to continue or Ctrl+C to cancel..." -ForegroundColor Yellow
Read-Host

# ============================================================================
# STEP 1: CHECK PYTHON
# ============================================================================

Write-Host "`n[1/5] Checking Python installation..." -ForegroundColor Cyan

try {
    $pythonVersion = python --version 2>&1
    Write-Host "  [OK] Python found: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "  [WARNING] Python not found" -ForegroundColor Yellow
    Write-Host "  Installing Python..." -ForegroundColor Yellow
    
    try {
        winget --version | Out-Null
        winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Host "  [OK] Python installed!" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] Could not install Python automatically" -ForegroundColor Red
        Write-Host "  Please install Python manually from: https://www.python.org/downloads/" -ForegroundColor Yellow
        Write-Host "  Make sure to check 'Add Python to PATH' during installation!" -ForegroundColor Yellow
        exit 1
    }
}

# Upgrade pip
Write-Host "  Upgrading pip..." -ForegroundColor Gray
python -m pip install --upgrade pip --quiet 2>&1 | Out-Null

# ============================================================================
# STEP 2: INSTALL OCI CLI
# ============================================================================

Write-Host "`n[2/5] Installing OCI CLI..." -ForegroundColor Cyan

try {
    $ociVersion = oci --version 2>&1
    Write-Host "  [OK] OCI CLI already installed: $ociVersion" -ForegroundColor Green
    
    $update = Read-Host "  Update to latest version? (y/n)"
    if ($update -eq "y" -or $update -eq "Y") {
        pip install --upgrade oci-cli
        Write-Host "  [OK] OCI CLI updated" -ForegroundColor Green
    }
}
catch {
    Write-Host "  Installing OCI CLI (this may take 1-2 minutes)..." -ForegroundColor Yellow
    pip install oci-cli
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    try {
        $ociVersion = oci --version 2>&1
        Write-Host "  [OK] OCI CLI installed: $ociVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] OCI CLI installation failed" -ForegroundColor Red
        Write-Host "  Please restart PowerShell and try again" -ForegroundColor Yellow
        exit 1
    }
}

# ============================================================================
# STEP 3: CONFIGURE OCI CREDENTIALS
# ============================================================================

Write-Host "`n[3/5] Configuring OCI credentials..." -ForegroundColor Cyan

$configPath = "$env:USERPROFILE\.oci\config"

if (Test-Path $configPath) {
    Write-Host "  [INFO] OCI config already exists: $configPath" -ForegroundColor Yellow
    $reconfigure = Read-Host "  Reconfigure? (y/n)"
    
    if ($reconfigure -ne "y" -and $reconfigure -ne "Y") {
        Write-Host "  [OK] Using existing configuration" -ForegroundColor Green
    }
    else {
        Write-Host ""
        Write-Host "  Starting OCI setup wizard..." -ForegroundColor Yellow
        Write-Host "  You will need:" -ForegroundColor Yellow
        Write-Host "    - User OCID (cloud.oracle.com -> User Icon -> My Profile)" -ForegroundColor White
        Write-Host "    - Tenancy OCID (User Icon -> Tenancy: [Name])" -ForegroundColor White
        Write-Host "    - Region (e.g., eu-frankfurt-1)" -ForegroundColor White
        Write-Host ""
        
        oci setup config
    }
}
else {
    Write-Host ""
    Write-Host "  Starting OCI setup wizard..." -ForegroundColor Yellow
    Write-Host "  You will need:" -ForegroundColor Yellow
    Write-Host "    - User OCID (cloud.oracle.com -> User Icon -> My Profile)" -ForegroundColor White
    Write-Host "    - Tenancy OCID (User Icon -> Tenancy: [Name])" -ForegroundColor White
    Write-Host "    - Region (e.g., eu-frankfurt-1)" -ForegroundColor White
    Write-Host ""
    
    oci setup config
}

# Verify config was created
if (-not (Test-Path $configPath)) {
    Write-Host "  [ERROR] OCI config was not created" -ForegroundColor Red
    Write-Host "  Please run 'oci setup config' manually" -ForegroundColor Yellow
    exit 1
}

# Display public key
$publicKeyPath = "$env:USERPROFILE\.oci\oci_api_key_public.pem"
if (Test-Path $publicKeyPath) {
    Write-Host ""
    Write-Host "  ============================================================================" -ForegroundColor Yellow
    Write-Host "  IMPORTANT: Upload your PUBLIC KEY to OCI Console!" -ForegroundColor Yellow
    Write-Host "  ============================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Go to: https://cloud.oracle.com" -ForegroundColor White
    Write-Host "  2. User Icon -> My Profile -> API Keys -> Add API Key" -ForegroundColor White
    Write-Host "  3. Select 'Paste Public Key'" -ForegroundColor White
    Write-Host "  4. Paste the key below:" -ForegroundColor White
    Write-Host ""
    Write-Host "  --- BEGIN PUBLIC KEY ---" -ForegroundColor Yellow
    Get-Content $publicKeyPath
    Write-Host "  --- END PUBLIC KEY ---" -ForegroundColor Yellow
    Write-Host ""
    
    # Copy to clipboard
    Get-Content $publicKeyPath | Set-Clipboard
    Write-Host "  [OK] Public key copied to clipboard!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Press ENTER after you've uploaded the key to OCI Console..." -ForegroundColor Yellow
    Read-Host
}

Write-Host "  [OK] OCI credentials configured" -ForegroundColor Green

# ============================================================================
# STEP 4: FETCH OCIDs
# ============================================================================

Write-Host "`n[4/5] Fetching OCIDs from your OCI account..." -ForegroundColor Cyan

# Read tenancy from config
$configContent = Get-Content $configPath
$tenancyLine = $configContent | Select-String "tenancy="
$TENANCY_OCID = ($tenancyLine -split "=")[1].Trim()

Write-Host "  [OK] Tenancy OCID: $TENANCY_OCID" -ForegroundColor Green

# Fetch VCN and Subnet
Write-Host "  Fetching VCN..." -ForegroundColor Gray
try {
    $vcnId = oci network vcn list `
        --compartment-id $TENANCY_OCID `
        --query "data[0].id" `
        --raw-output 2>&1
    
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($vcnId)) {
        throw "No VCN found"
    }
    
    Write-Host "  [OK] VCN found" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] No VCN found in your OCI account" -ForegroundColor Red
    Write-Host "  Please create a VCN first:" -ForegroundColor Yellow
    Write-Host "    1. Go to OCI Console -> Networking -> Virtual Cloud Networks" -ForegroundColor White
    Write-Host "    2. Click 'Create VCN'" -ForegroundColor White
    Write-Host "    3. Use 'VCN Wizard' for quick setup" -ForegroundColor White
    Write-Host ""
    Write-Host "  Then run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "  Fetching Subnet..." -ForegroundColor Gray
try {
    $SUBNET_ID = oci network subnet list `
        --compartment-id $TENANCY_OCID `
        --vcn-id $vcnId `
        --query "data[0].id" `
        --raw-output 2>&1
    
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($SUBNET_ID)) {
        throw "No Subnet found"
    }
    
    Write-Host "  [OK] Subnet OCID: $SUBNET_ID" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] No Subnet found" -ForegroundColor Red
    Write-Host "  Please create a Subnet in your VCN first" -ForegroundColor Yellow
    exit 1
}

# Fetch Ubuntu 24.04 Image
Write-Host "  Fetching Ubuntu 24.04 Image..." -ForegroundColor Gray
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
    
    Write-Host "  [OK] Image OCID: $IMAGE_ID" -ForegroundColor Green
}
catch {
    Write-Host "  [WARNING] Could not fetch Ubuntu 24.04 image automatically" -ForegroundColor Yellow
    Write-Host "  Please enter the Image OCID manually:" -ForegroundColor Yellow
    Write-Host "    1. Go to OCI Console -> Compute -> Instances -> Create Instance" -ForegroundColor White
    Write-Host "    2. Change Image -> Canonical Ubuntu -> 24.04" -ForegroundColor White
    Write-Host "    3. Copy the Image OCID" -ForegroundColor White
    Write-Host ""
    $IMAGE_ID = Read-Host "  Paste Image OCID here"
    
    if ([string]::IsNullOrWhiteSpace($IMAGE_ID)) {
        Write-Host "  [ERROR] No Image OCID provided" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# STEP 5: UPDATE PYTHON SCRIPT
# ============================================================================

Write-Host "`n[5/5] Updating Python script..." -ForegroundColor Cyan

$scriptPath = "oci-instance-sniper.py"

if (-not (Test-Path $scriptPath)) {
    Write-Host "  [ERROR] Python script not found: $scriptPath" -ForegroundColor Red
    Write-Host "  Please make sure oci-instance-sniper.py is in the same folder as this script" -ForegroundColor Yellow
    exit 1
}

try {
    # Read script
    $scriptContent = Get-Content $scriptPath -Raw -Encoding UTF8
    
    # Update OCIDs
    $scriptContent = $scriptContent -replace 'COMPARTMENT_ID = "ocid1\.tenancy\.oc1\.\.[a-z0-9]+"', "COMPARTMENT_ID = `"$TENANCY_OCID`""
    $scriptContent = $scriptContent -replace 'IMAGE_ID = "ocid1\.image\.oc1\.[a-z0-9-]+\.[a-z0-9]+"', "IMAGE_ID = `"$IMAGE_ID`""
    $scriptContent = $scriptContent -replace 'SUBNET_ID = "ocid1\.subnet\.oc1\.[a-z0-9-]+\.[a-z0-9]+"', "SUBNET_ID = `"$SUBNET_ID`""
    
    # Create backup
    $backupPath = "oci-instance-sniper.py.backup"
    Copy-Item $scriptPath $backupPath -Force
    Write-Host "  [OK] Backup created: $backupPath" -ForegroundColor Green
    
    # Save updated script
    $scriptContent | Out-File $scriptPath -Encoding UTF8 -NoNewline
    Write-Host "  [OK] Python script updated" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] Failed to update Python script" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "                    SETUP COMPLETE!" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor Yellow
Write-Host "  Compartment: $TENANCY_OCID" -ForegroundColor White
Write-Host "  Subnet:      $SUBNET_ID" -ForegroundColor White
Write-Host "  Image:       $IMAGE_ID" -ForegroundColor White
Write-Host "  SSH Key:     Configured [OK]" -ForegroundColor Green
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run the sniper script:" -ForegroundColor Yellow
Write-Host "  python oci-instance-sniper.py" -ForegroundColor White
Write-Host ""
Write-Host "Or run in background:" -ForegroundColor Yellow
Write-Host "  Start-Process powershell -ArgumentList `"-NoExit`", `"-Command`", `"python oci-instance-sniper.py`"" -ForegroundColor White
Write-Host ""
Write-Host "Monitor the log:" -ForegroundColor Yellow
Write-Host "  Get-Content -Path oci-sniper.log -Wait -Tail 20" -ForegroundColor White
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[!] IMPORTANT: Finding an ARM instance can take hours or days!" -ForegroundColor Yellow
Write-Host "    Best success rates: overnight and on weekends" -ForegroundColor Yellow
Write-Host ""
Write-Host "Good luck! [TARGET]" -ForegroundColor Green
Write-Host ""
