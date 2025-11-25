#!/usr/bin/env python3
"""
OCI Instance Sniper v1.1
Automatically attempts to create an ARM instance in OCI when capacity becomes available.

Author: Dave Vaupel
Date: 2025-11-24

Changelog v1.1:
- Fixed UTF-8 encoding for Windows console (emoji support)
- Added configuration validation on startup
- Added SSH key validation
- Added OCID format validation
"""

import oci
import time
import logging
from datetime import datetime
import sys

# ============================================================================
# CONFIGURATION - CUSTOMIZE THESE VALUES
# ============================================================================

# OCI Configuration (will be loaded from ~/.oci/config)
CONFIG_PROFILE = "DEFAULT"

# Instance Configuration
COMPARTMENT_ID = "ocid1.tenancy.oc1..your_compartment_id_here"  # Your compartment OCID
AVAILABILITY_DOMAINS = ["AD-1", "AD-2", "AD-3"]  # Try all ADs
SHAPE = "VM.Standard.A1.Flex"
OCPUS = 2
MEMORY_IN_GBS = 12

# Image Configuration (Ubuntu 24.04)
IMAGE_ID = "ocid1.image.oc1.eu-frankfurt-1.your_image_id_here"  # Ubuntu 24.04 image OCID

# Networking Configuration
SUBNET_ID = "ocid1.subnet.oc1.eu-frankfurt-1.your_subnet_id_here"  # Your subnet OCID
ASSIGN_PUBLIC_IP = True

# SSH Key (paste your public key here)
SSH_PUBLIC_KEY = """your_ssh_public_key_here"""

# Retry Configuration
RETRY_DELAY_SECONDS = 60  # Wait 60 seconds between attempts
MAX_ATTEMPTS = 1440  # Try for 24 hours (1440 * 60 seconds)

# Instance Name
INSTANCE_NAME = "nextcloud-backup-instance"

# ============================================================================
# LOGGING SETUP
# ============================================================================

# Configure UTF-8 encoding for Windows console
if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('oci-sniper.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

def create_instance_config(availability_domain):
    """Create instance configuration for the given availability domain."""
    
    instance_details = oci.core.models.LaunchInstanceDetails(
        availability_domain=availability_domain,
        compartment_id=COMPARTMENT_ID,
        display_name=INSTANCE_NAME,
        shape=SHAPE,
        shape_config=oci.core.models.LaunchInstanceShapeConfigDetails(
            ocpus=OCPUS,
            memory_in_gbs=MEMORY_IN_GBS
        ),
        create_vnic_details=oci.core.models.CreateVnicDetails(
            subnet_id=SUBNET_ID,
            assign_public_ip=ASSIGN_PUBLIC_IP
        ),
        metadata={
            'ssh_authorized_keys': SSH_PUBLIC_KEY
        },
        source_details=oci.core.models.InstanceSourceViaImageDetails(
            image_id=IMAGE_ID,
            source_type="image"
        )
    )
    
    return instance_details


def try_create_instance(compute_client, availability_domain):
    """Attempt to create an instance in the specified availability domain."""
    
    try:
        instance_details = create_instance_config(availability_domain)
        
        logger.info(f"Attempting to create instance in {availability_domain}...")
        
        response = compute_client.launch_instance(instance_details)
        
        logger.info(f"✅ SUCCESS! Instance created in {availability_domain}!")
        logger.info(f"Instance OCID: {response.data.id}")
        logger.info(f"Instance State: {response.data.lifecycle_state}")
        
        return True, response.data
        
    except oci.exceptions.ServiceError as e:
        if e.status == 500 and "Out of host capacity" in e.message:
            logger.warning(f"⏳ No capacity in {availability_domain}: {e.message}")
            return False, None
        else:
            logger.error(f"❌ Error in {availability_domain}: {e.message}")
            return False, None
            
    except Exception as e:
        logger.error(f"❌ Unexpected error in {availability_domain}: {str(e)}")
        return False, None


def validate_configuration():
    """Validate all required configuration values before starting."""
    errors = []

    # Check OCIDs
    if "your_compartment_id_here" in COMPARTMENT_ID:
        errors.append("COMPARTMENT_ID is not configured")

    if "your_image_id_here" in IMAGE_ID:
        errors.append("IMAGE_ID is not configured")

    if "your_subnet_id_here" in SUBNET_ID:
        errors.append("SUBNET_ID is not configured")

    # Check SSH key
    if "your_ssh_public_key_here" in SSH_PUBLIC_KEY or len(SSH_PUBLIC_KEY.strip()) < 100:
        errors.append("SSH_PUBLIC_KEY is not configured")

    # Validate OCID format
    if not COMPARTMENT_ID.startswith("ocid1."):
        errors.append("COMPARTMENT_ID has invalid format (must start with 'ocid1.')")

    if not IMAGE_ID.startswith("ocid1.image"):
        errors.append("IMAGE_ID has invalid format (must start with 'ocid1.image')")

    if not SUBNET_ID.startswith("ocid1.subnet"):
        errors.append("SUBNET_ID has invalid format (must start with 'ocid1.subnet')")

    if errors:
        logger.error("❌ Configuration errors found:")
        for error in errors:
            logger.error(f"   - {error}")
        logger.error("")
        logger.error("Please run setup.ps1 first or manually configure the script:")
        logger.error("   powershell -ExecutionPolicy Bypass -File setup.ps1")
        return False

    return True


def main():
    """Main function to continuously attempt instance creation."""

    logger.info("=" * 80)
    logger.info("OCI Instance Sniper v1.1 - Starting")
    logger.info("=" * 80)

    # Validate configuration
    if not validate_configuration():
        sys.exit(1)

    logger.info(f"Target Shape: {SHAPE}")
    logger.info(f"Target Config: {OCPUS} OCPUs, {MEMORY_IN_GBS} GB RAM")
    logger.info(f"Availability Domains: {', '.join(AVAILABILITY_DOMAINS)}")
    logger.info(f"Retry Delay: {RETRY_DELAY_SECONDS} seconds")
    logger.info(f"Max Attempts: {MAX_ATTEMPTS}")
    logger.info("=" * 80)

    # Initialize OCI config and compute client
    try:
        config = oci.config.from_file("~/.oci/config", CONFIG_PROFILE)
        compute_client = oci.core.ComputeClient(config)
        logger.info("✅ OCI SDK initialized successfully")
    except Exception as e:
        logger.error(f"❌ Failed to initialize OCI SDK: {str(e)}")
        logger.error("Please run: oci setup config")
        sys.exit(1)
    
    # Get full availability domain names
    identity_client = oci.identity.IdentityClient(config)
    try:
        compartment = config["tenancy"]
        list_ads = identity_client.list_availability_domains(compartment)
        full_ad_names = [ad.name for ad in list_ads.data]
        logger.info(f"Available ADs: {', '.join(full_ad_names)}")
    except Exception as e:
        logger.warning(f"Could not fetch AD names: {str(e)}")
        full_ad_names = AVAILABILITY_DOMAINS
    
    # Main retry loop
    attempt = 0
    while attempt < MAX_ATTEMPTS:
        attempt += 1
        logger.info(f"\n{'='*80}")
        logger.info(f"Attempt {attempt}/{MAX_ATTEMPTS} - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        logger.info(f"{'='*80}")
        
        # Try each availability domain
        for ad in full_ad_names:
            success, instance = try_create_instance(compute_client, ad)
            
            if success:
                logger.info("\n" + "="*80)
                logger.info("🎉 INSTANCE SUCCESSFULLY CREATED!")
                logger.info("="*80)
                logger.info(f"Instance Name: {instance.display_name}")
                logger.info(f"Instance OCID: {instance.id}")
                logger.info(f"Availability Domain: {instance.availability_domain}")
                logger.info(f"Shape: {instance.shape}")
                logger.info(f"State: {instance.lifecycle_state}")
                logger.info("="*80)
                logger.info("\nNext steps:")
                logger.info("1. Wait for instance to reach 'RUNNING' state")
                logger.info("2. Get public IP from OCI console")
                logger.info("3. SSH into instance: ssh ubuntu@<PUBLIC_IP>")
                logger.info("4. Install Docker and Nextcloud")
                logger.info("="*80)
                return 0
            
            # Small delay between AD attempts
            time.sleep(2)
        
        # Wait before next attempt
        if attempt < MAX_ATTEMPTS:
            logger.info(f"⏰ Waiting {RETRY_DELAY_SECONDS} seconds before next attempt...")
            time.sleep(RETRY_DELAY_SECONDS)
    
    logger.warning(f"\n❌ Max attempts ({MAX_ATTEMPTS}) reached. No capacity found.")
    logger.info("The script can be restarted at any time to continue trying.")
    return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        logger.info("\n\n⚠️  Script interrupted by user (Ctrl+C)")
        logger.info("You can restart the script at any time.")
        sys.exit(0)
    except Exception as e:
        logger.error(f"\n❌ Fatal error: {str(e)}")
        sys.exit(1)
