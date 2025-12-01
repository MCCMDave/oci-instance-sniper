#!/usr/bin/env python3
"""
OCI Instance Sniper v1.4
Automatically attempts to create an ARM instance in OCI when capacity becomes available.

Author: Dave Vaupel
Date: 2025-11-29

Changelog v1.4:
- Added interactive language selection (EN/DE) at startup with single-keypress input
- Language selection skipped if already set in config.json
- Single-keypress uses msvcrt.getch() on Windows (no Enter needed)
- Fallback to standard input() on Linux/Mac

Changelog v1.3:
- Added automatic retry logic with exponential backoff for network errors
- Added tenacity library for robust API calls
- Fixed import ordering bug (json, os, re now properly imported)
- Improved config validation with fallback to defaults
- Enhanced SSH key validation with regex patterns
- Pinned dependency versions (oci==2.133.0, tenacity==8.2.3)
- Added GitHub Actions CI/CD pipeline
- Added pre-commit hooks for code quality
- Added PowerShell control menu logging

Changelog v1.2:
- Added instance status monitoring (waits for RUNNING state)
- Added automatic public IP retrieval
- Added SSH config generator
- Added reserved public IP support (optional)
- Added email notifications (optional)
- Added bilingual support (EN/DE)
- Improved error handling for authentication and bad requests

Changelog v1.1:
- Fixed UTF-8 encoding for Windows console (emoji support)
- Added configuration validation on startup
- Added SSH key validation
- Added OCID format validation
"""

import json
import logging
import os
import re
import smtplib
import subprocess
import sys
import time
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Auto-install dependencies if missing (UX improvement)
try:
    import oci
    from tenacity import (
        retry,
        stop_after_attempt,
        wait_exponential,
        retry_if_exception_type,
        before_sleep_log,
    )
except ImportError as e:
    missing_module = str(e).split("'")[1]
    print(f"Missing dependency: {missing_module}")
    print("Installing required packages...")
    try:
        subprocess.check_call(
            [
                sys.executable,
                "-m",
                "pip",
                "install",
                "-r",
                "requirements.txt",
                "--quiet",
            ]
        )
        print("Dependencies installed successfully!")
        print("Please restart the script.")
        sys.exit(0)
    except subprocess.CalledProcessError:
        print("ERROR: Could not install dependencies automatically.")
        print("Please run manually: pip install -r requirements.txt")
        sys.exit(1)

# ============================================================================
# LANGUAGE SELECTION
# ============================================================================


def load_config_file():
    """Load configuration from config/sniper-config.json if it exists"""
    # Config is one level up from scripts/ directory
    script_dir = os.path.dirname(__file__)
    project_root = os.path.dirname(script_dir)
    config_file = os.path.join(project_root, "config", "sniper-config.json")
    if os.path.exists(config_file):
        try:
            with open(config_file, "r", encoding="utf-8") as f:
                config = json.load(f)
                # Validate config values
                if not isinstance(config, dict):
                    print(
                        "Warning: Config file is not a valid JSON object. Using defaults."
                    )
                    return {}
                # Validate OCPUs (1-4 for Free Tier)
                if "ocpus" in config:
                    if (
                        not isinstance(config["ocpus"], int)
                        or config["ocpus"] < 1
                        or config["ocpus"] > 4
                    ):
                        print(
                            f"Warning: Invalid OCPUs value: {config['ocpus']}. Must be 1-4. Using default: 2"
                        )
                        config["ocpus"] = 2
                # Validate Memory (1-24 GB for Free Tier)
                if "memory_in_gbs" in config:
                    mem = config["memory_in_gbs"]
                    if not isinstance(mem, int) or mem < 1 or mem > 24:
                        print(
                            f"Warning: Invalid Memory: {mem}. Must be 1-24 GB. Using default: 12"
                        )
                        config["memory_in_gbs"] = 12
                # Validate retry delay (minimum 10 seconds)
                if "retry_delay_seconds" in config:
                    delay = config["retry_delay_seconds"]
                    if not isinstance(delay, int) or delay < 10:
                        print(
                            f"Warning: Invalid retry delay: {delay}. Must be >= 10s. Using default: 60"
                        )
                        config["retry_delay_seconds"] = 60
                # Validate max attempts (minimum 1)
                if "max_attempts" in config:
                    attempts = config["max_attempts"]
                    if not isinstance(attempts, int) or attempts < 1:
                        print(
                            f"Warning: Invalid max attempts: {attempts}. Must be >= 1. Using default: 1440"
                        )
                        config["max_attempts"] = 1440
                return config
        except json.JSONDecodeError as e:
            print(f"Error: Config file is corrupted (invalid JSON): {e}")
            print("Using default configuration. Please check config/sniper-config.json")
            return {}
        except Exception as e:
            print(f"Warning: Could not load config file: {e}")
            return {}
    return {}


# Load config file (will override hardcoded values below if present)
CONFIG_FILE = load_config_file()

# Language will be set by select_language() or from config
LANGUAGE = CONFIG_FILE.get("language", None)

# ============================================================================
# CONFIGURATION - CUSTOMIZE THESE VALUES
# ============================================================================

# OCI Configuration (will be loaded from ~/.oci/config)
CONFIG_PROFILE = "DEFAULT"

# Instance Configuration
COMPARTMENT_ID = "ocid1.tenancy.oc1..your_compartment_id_here"  # Your compartment OCID
AVAILABILITY_DOMAINS = ["AD-1", "AD-2", "AD-3"]  # Try all ADs
SHAPE = "VM.Standard.A1.Flex"
OCPUS = CONFIG_FILE.get("ocpus", 2)
MEMORY_IN_GBS = CONFIG_FILE.get("memory_in_gbs", 12)

# Image Configuration (Ubuntu 24.04)
IMAGE_ID = (
    "ocid1.image.oc1.eu-frankfurt-1.your_image_id_here"  # Ubuntu 24.04 image OCID
)

# Networking Configuration
SUBNET_ID = "ocid1.subnet.oc1.eu-frankfurt-1.your_subnet_id_here"  # Your subnet OCID
ASSIGN_PUBLIC_IP = True

# Reserved IP Configuration (NEW in v1.2)
# If True, creates a reserved public IP that persists across instance stops/starts
# If False, uses ephemeral IP (changes on stop/start)
# You will be asked interactively when running the script
RESERVED_PUBLIC_IP = None  # Will be set during runtime

# SSH Key (paste your public key here)
SSH_PUBLIC_KEY = """your_ssh_public_key_here"""

# Retry Configuration
RETRY_DELAY_SECONDS = CONFIG_FILE.get(
    "retry_delay_seconds", 60
)  # Wait 60 seconds between attempts
MAX_ATTEMPTS = CONFIG_FILE.get(
    "max_attempts", 1440
)  # Try for 24 hours (1440 * 60 seconds)

# Instance Name
INSTANCE_NAME = CONFIG_FILE.get("instance_name", "oci-instance")

# ============================================================================
# EMAIL NOTIFICATIONS (OPTIONAL - Disabled by default)
# ============================================================================
# Enable email notifications to get notified when instance is ready
# Requires Gmail App Password or other SMTP credentials
# See README.md for setup instructions

EMAIL_NOTIFICATIONS_ENABLED = False  # Set to True to enable

# Gmail Configuration (only used if EMAIL_NOTIFICATIONS_ENABLED = True)
EMAIL_FROM = "your-email@gmail.com"
EMAIL_TO = "your-email@gmail.com"  # Can be different email
EMAIL_PASSWORD = "your-app-password-here"  # Gmail App Password (16 chars)
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587

# Alternative SMTP providers:
# Outlook: smtp.office365.com:587
# GMX: mail.gmx.net:587
# Web.de: smtp.web.de:587

# ============================================================================
# TRANSLATIONS
# ============================================================================
TRANSLATIONS = {
    "EN": {
        "title": "OCI Instance Sniper - Starting",
        "target_shape": "Target Shape",
        "target_config": "Target Config",
        "availability_domains": "Availability Domains",
        "retry_delay": "Retry Delay",
        "max_attempts": "Max Attempts",
        "oci_init_success": "OCI SDK initialized successfully",
        "oci_init_failed": "Failed to initialize OCI SDK",
        "available_ads": "Available ADs",
        "attempt": "Attempt",
        "attempting_create": "Attempting to create instance in",
        "success": "SUCCESS! Instance created in",
        "instance_ocid": "Instance OCID",
        "instance_state": "Instance State",
        "no_capacity": "No capacity in",
        "error_in_ad": "Error in",
        "unexpected_error": "Unexpected error in",
        "waiting_for_running": "Waiting for instance to reach RUNNING state...",
        "instance_running": "Instance is now RUNNING!",
        "public_ip": "Public IP",
        "private_ip": "Private IP",
        "ssh_command": "SSH Command",
        "ssh_config_generated": "SSH config file generated",
        "email_sent": "Email notification sent to",
        "email_failed": "Failed to send email notification",
        "instance_created_title": "INSTANCE SUCCESSFULLY CREATED!",
        "instance_details": "Instance Details",
        "ssh_connection_info": "SSH CONNECTION INFO",
        "next_steps": "Next steps",
        "step_1": "1. SSH into instance using command above",
        "step_2": "2. Update system: sudo apt update && sudo apt upgrade -y",
        "step_3": "3. Install Docker: curl -fsSL https://get.docker.com | sh",
        "step_4": "4. Deploy Nextcloud!",
        "waiting_before_retry": "Waiting {seconds} seconds before next attempt...",
        "max_attempts_reached": "Max attempts ({attempts}) reached. No capacity found.",
        "script_can_restart": "The script can be restarted at any time to continue trying.",
        "script_interrupted": "Script interrupted by user (Ctrl+C)",
        "fatal_error": "Fatal error",
        "reserved_ip_prompt": "Do you want to create a RESERVED Public IP? (Recommended for SSH config)",
        "reserved_ip_info": "Reserved IP stays the same even after instance stop/start",
        "reserved_ip_yes": "This is recommended if you plan to use SSH config (~/.ssh/config)",
        "reserved_ip_creating": "Creating reserved public IP...",
        "reserved_ip_created": "Reserved IP created",
        "bad_request": "Bad Request - Check your configuration (Shape, Image, Subnet)",
        "auth_failed": "Authentication failed - Run: oci setup config",
        "config_errors_found": "❌ Configuration errors found:",
        "please_run_setup": "Please run setup.ps1 first or manually configure the script:",
        "setup_command": "   powershell -ExecutionPolicy Bypass -File setup.ps1",
    },
    "DE": {
        "title": "OCI Instance Sniper - Startet",
        "target_shape": "Ziel-Shape",
        "target_config": "Ziel-Konfiguration",
        "availability_domains": "Availability Domains",
        "retry_delay": "Wiederholungsverzögerung",
        "max_attempts": "Max. Versuche",
        "oci_init_success": "OCI SDK erfolgreich initialisiert",
        "oci_init_failed": "OCI SDK Initialisierung fehlgeschlagen",
        "available_ads": "Verfügbare ADs",
        "attempt": "Versuch",
        "attempting_create": "Versuche Instanz zu erstellen in",
        "success": "ERFOLG! Instanz erstellt in",
        "instance_ocid": "Instanz OCID",
        "instance_state": "Instanz-Status",
        "no_capacity": "Keine Kapazität in",
        "error_in_ad": "Fehler in",
        "unexpected_error": "Unerwarteter Fehler in",
        "waiting_for_running": "Warte bis Instanz RUNNING Status erreicht...",
        "instance_running": "Instanz läuft jetzt!",
        "public_ip": "Öffentliche IP",
        "private_ip": "Private IP",
        "ssh_command": "SSH Befehl",
        "ssh_config_generated": "SSH Config-Datei generiert",
        "email_sent": "Email-Benachrichtigung gesendet an",
        "email_failed": "Email-Benachrichtigung fehlgeschlagen",
        "instance_created_title": "INSTANZ ERFOLGREICH ERSTELLT!",
        "instance_details": "Instanz-Details",
        "ssh_connection_info": "SSH VERBINDUNGSINFO",
        "next_steps": "Nächste Schritte",
        "step_1": "1. SSH Verbindung mit obigem Befehl",
        "step_2": "2. System aktualisieren: sudo apt update && sudo apt upgrade -y",
        "step_3": "3. Docker installieren: curl -fsSL https://get.docker.com | sh",
        "step_4": "4. Nextcloud deployen!",
        "waiting_before_retry": "Warte {seconds} Sekunden vor nächstem Versuch...",
        "max_attempts_reached": "Max. Versuche ({attempts}) erreicht. Keine Kapazität gefunden.",
        "script_can_restart": "Das Skript kann jederzeit neu gestartet werden.",
        "script_interrupted": "Skript durch Benutzer unterbrochen (Ctrl+C)",
        "fatal_error": "Fataler Fehler",
        "reserved_ip_prompt": "Möchten Sie eine RESERVIERTE öffentliche IP erstellen? (Empfohlen für SSH Config)",
        "reserved_ip_info": "Reservierte IP bleibt gleich auch nach Instanz Stop/Start",
        "reserved_ip_yes": "Empfohlen wenn Sie SSH Config (~/.ssh/config) nutzen möchten",
        "reserved_ip_creating": "Erstelle reservierte öffentliche IP...",
        "reserved_ip_created": "Reservierte IP erstellt",
        "bad_request": "Ungültige Anfrage - Prüfen Sie Ihre Konfiguration (Shape, Image, Subnet)",
        "auth_failed": "Authentifizierung fehlgeschlagen - Führen Sie aus: oci setup config",
        "config_errors_found": "❌ Konfigurationsfehler gefunden:",
        "please_run_setup": "Bitte führen Sie zuerst setup.ps1 aus oder konfigurieren Sie das Script manuell:",
        "setup_command": "   powershell -ExecutionPolicy Bypass -File setup.ps1",
    },
}


def t(key):
    """Get translated string"""
    return TRANSLATIONS.get(LANGUAGE, TRANSLATIONS["EN"]).get(key, key)


def select_language():
    """
    Interactive language selection at startup (if not set in config).
    Uses single-keypress input (no Enter needed).
    """
    global LANGUAGE

    # If language already set in config, skip selection
    if LANGUAGE is not None:
        return

    print()
    print("=" * 80)
    print("  LANGUAGE / SPRACHE")
    print("=" * 80)
    print()
    print("  [1] English")
    print("  [2] Deutsch")
    print()
    print("=" * 80)
    print()
    print("Choice / Wahl: ", end="", flush=True)

    # Single-keypress input (Windows compatible)
    if sys.platform == "win32":
        import msvcrt

        while True:
            key = msvcrt.getch().decode("utf-8")
            if key in ["1", "2"]:
                print(f"{key} ==\n")
                LANGUAGE = "EN" if key == "1" else "DE"
                break
    else:
        # Fallback for Linux/Mac - require Enter
        choice = input()
        LANGUAGE = "EN" if choice == "1" else "DE"


# ============================================================================
# LOGGING SETUP
# ============================================================================

# Configure UTF-8 encoding for Windows console
if sys.platform == "win32":
    import io

    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("oci-sniper.log", encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger(__name__)


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================


def ask_yes_no(question):
    """Ask user a yes/no question"""
    while True:
        response = input(f"{question} (y/n): ").lower().strip()
        if response in ["y", "yes", "ja", "j"]:
            return True
        elif response in ["n", "no", "nein"]:
            return False
        else:
            print("Please answer with 'y' or 'n'")


def send_email_notification(instance_data, public_ip, private_ip):
    """Send email notification when instance is created"""

    if not EMAIL_NOTIFICATIONS_ENABLED:
        return

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = "✅ OCI Instance Successfully Created!"
        msg["From"] = EMAIL_FROM
        msg["To"] = EMAIL_TO

        # Email body
        text = f"""
Your OCI Instance is ready!

Instance Details:
- Name: {instance_data.display_name}
- Shape: {instance_data.shape} ({OCPUS} OCPUs, {MEMORY_IN_GBS} GB RAM)
- Availability Domain: {instance_data.availability_domain}
- Public IP: {public_ip}
- Private IP: {private_ip}

SSH Command:
ssh ubuntu@{public_ip}

Status: RUNNING ✅
Created at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

Next Steps:
1. SSH into your instance
2. Update system: sudo apt update && sudo apt upgrade -y
3. Install Docker: curl -fsSL https://get.docker.com | sh
4. Deploy Nextcloud!

---
Sent by OCI Instance Sniper
        """

        msg.attach(MIMEText(text, "plain"))

        # Send email
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(EMAIL_FROM, EMAIL_PASSWORD)
            server.send_message(msg)

        logger.info(f"📧 {t('email_sent')}: {EMAIL_TO}")

    except Exception as e:
        logger.warning(f"⚠️  {t('email_failed')}: {str(e)}")


def generate_ssh_config(public_ip, instance_name):
    """Generate SSH config file snippet"""

    config_content = f"""# Add this to your ~/.ssh/config file:

Host oci
    HostName {public_ip}
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking accept-new
    ServerAliveInterval 60

# Usage:
# ssh oci
# scp file.txt oci:/home/ubuntu/
"""

    try:
        with open("ssh-config-oci.txt", "w", encoding="utf-8") as f:
            f.write(config_content)
        logger.info(f"📝 {t('ssh_config_generated')}: ssh-config-oci.txt")
    except Exception as e:
        logger.warning(f"⚠️  Could not write SSH config file: {str(e)}")


def wait_for_instance_running(compute_client, instance_id, network_client, timeout=600):
    """Wait for instance to reach RUNNING state and get IP addresses"""

    logger.info(f"⏳ {t('waiting_for_running')}")

    start_time = time.time()
    elapsed = 0

    while time.time() - start_time < timeout:
        try:
            instance = compute_client.get_instance(instance_id).data
            elapsed = int(time.time() - start_time)

            if instance.lifecycle_state == "RUNNING":
                logger.info(f"✅ {t('instance_running')}")

                # Get VNIC info for IP addresses
                try:
                    vnic_attachments = compute_client.list_vnic_attachments(
                        compartment_id=instance.compartment_id, instance_id=instance.id
                    ).data

                    if vnic_attachments:
                        vnic_id = vnic_attachments[0].vnic_id
                        vnic = network_client.get_vnic(vnic_id).data
                        return instance, vnic.public_ip, vnic.private_ip

                except Exception as e:
                    logger.warning(f"Could not get VNIC info: {str(e)}")
                    return instance, None, None

            logger.info(
                f"⏳ {t('instance_state')}: {instance.lifecycle_state} ({elapsed}s)"
            )
            time.sleep(10)

        except Exception as e:
            logger.warning(f"Error checking instance status: {str(e)}")
            time.sleep(10)

    logger.warning(f"⚠️  Timeout waiting for RUNNING state ({timeout}s)")
    return None, None, None


def create_reserved_ip(
    network_client, compartment_id, display_name="nextcloud-reserved-ip"
):
    """Create a reserved public IP"""

    logger.info(f"🔄 {t('reserved_ip_creating')}")

    try:
        reserved_ip_details = oci.core.models.CreatePublicIpDetails(
            compartment_id=compartment_id,
            lifetime="RESERVED",
            display_name=display_name,
        )

        reserved_ip = network_client.create_public_ip(reserved_ip_details).data
        logger.info(f"✅ {t('reserved_ip_created')}: {reserved_ip.ip_address}")
        return reserved_ip

    except Exception as e:
        logger.error(f"❌ Error creating reserved IP: {str(e)}")
        return None


# ============================================================================
# MAIN FUNCTIONS
# ============================================================================


def create_instance_config(availability_domain, reserved_ip_id=None):
    """Create instance configuration for the given availability domain."""

    create_vnic_details = oci.core.models.CreateVnicDetails(
        subnet_id=SUBNET_ID,
        assign_public_ip=ASSIGN_PUBLIC_IP if not reserved_ip_id else False,
        public_ip_id=reserved_ip_id if reserved_ip_id else None,
    )

    instance_details = oci.core.models.LaunchInstanceDetails(
        availability_domain=availability_domain,
        compartment_id=COMPARTMENT_ID,
        display_name=INSTANCE_NAME,
        shape=SHAPE,
        shape_config=oci.core.models.LaunchInstanceShapeConfigDetails(
            ocpus=OCPUS, memory_in_gbs=MEMORY_IN_GBS
        ),
        create_vnic_details=create_vnic_details,
        metadata={"ssh_authorized_keys": SSH_PUBLIC_KEY},
        source_details=oci.core.models.InstanceSourceViaImageDetails(
            image_id=IMAGE_ID, source_type="image"
        ),
    )

    return instance_details


@retry(
    retry=retry_if_exception_type(
        (
            oci.exceptions.RequestException,
            oci.exceptions.ConnectTimeout,
            ConnectionError,
            TimeoutError,
        )
    ),
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    before_sleep=before_sleep_log(logger, logging.WARNING),
    reraise=True,
)
def _launch_instance_with_retry(compute_client, instance_details, availability_domain):
    """Internal function to launch instance with retry logic for network errors."""
    logger.info(f"{t('attempting_create')} {availability_domain}...")
    return compute_client.launch_instance(instance_details)


def try_create_instance(compute_client, availability_domain, reserved_ip_id=None):
    """Attempt to create an instance in the specified availability domain."""

    try:
        instance_details = create_instance_config(availability_domain, reserved_ip_id)

        # Call with retry logic for network errors
        response = _launch_instance_with_retry(
            compute_client, instance_details, availability_domain
        )

        logger.info(f"✅ {t('success')} {availability_domain}!")
        logger.info(f"{t('instance_ocid')}: {response.data.id}")
        logger.info(f"{t('instance_state')}: {response.data.lifecycle_state}")

        return True, response.data

    except oci.exceptions.ServiceError as e:
        if e.status == 500 and "Out of host capacity" in e.message:
            logger.warning(f"⏳ {t('no_capacity')} {availability_domain}: {e.message}")
            return False, None
        elif e.status == 400:
            logger.error(f"❌ {t('bad_request')} {availability_domain}: {e.message}")
            return False, None
        elif e.status == 401:
            logger.error(f"❌ {t('auth_failed')}: {e.message}")
            sys.exit(1)
        else:
            logger.error(f"❌ {t('error_in_ad')} {availability_domain}: {e.message}")
            return False, None

    except (
        oci.exceptions.RequestException,
        oci.exceptions.ConnectTimeout,
        ConnectionError,
        TimeoutError,
    ) as e:
        # Network errors after all retries exhausted
        logger.error(
            f"❌ Network error in {availability_domain} after retries: {str(e)}"
        )
        return False, None

    except Exception as e:
        logger.error(f"❌ {t('unexpected_error')} {availability_domain}: {str(e)}")
        return False, None


def validate_ssh_key(ssh_key):
    """Validate SSH public key format"""
    ssh_key = ssh_key.strip()

    # Check for common SSH key patterns
    valid_patterns = [
        r"^ssh-rsa AAAA[0-9A-Za-z+/]+[=]{0,3}(\s.*)?$",  # RSA
        r"^ssh-ed25519 AAAA[0-9A-Za-z+/]+[=]{0,3}(\s.*)?$",  # Ed25519
        r"^ecdsa-sha2-nistp256 AAAA[0-9A-Za-z+/]+[=]{0,3}(\s.*)?$",  # ECDSA 256
        r"^ecdsa-sha2-nistp384 AAAA[0-9A-Za-z+/]+[=]{0,3}(\s.*)?$",  # ECDSA 384
        r"^ecdsa-sha2-nistp521 AAAA[0-9A-Za-z+/]+[=]{0,3}(\s.*)?$",  # ECDSA 521
    ]

    for pattern in valid_patterns:
        if re.match(pattern, ssh_key):
            return True
    return False


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
    if (
        "your_ssh_public_key_here" in SSH_PUBLIC_KEY
        or len(SSH_PUBLIC_KEY.strip()) < 100
    ):
        errors.append("SSH_PUBLIC_KEY is not configured")
    elif not validate_ssh_key(SSH_PUBLIC_KEY):
        errors.append(
            "SSH_PUBLIC_KEY has invalid format (must be ssh-rsa, ssh-ed25519, or ecdsa-sha2-*)"
        )

    # Validate OCID format
    if not COMPARTMENT_ID.startswith("ocid1."):
        errors.append("COMPARTMENT_ID has invalid format (must start with 'ocid1.')")

    if not IMAGE_ID.startswith("ocid1.image"):
        errors.append("IMAGE_ID has invalid format (must start with 'ocid1.image')")

    if not SUBNET_ID.startswith("ocid1.subnet"):
        errors.append("SUBNET_ID has invalid format (must start with 'ocid1.subnet')")

    if errors:
        logger.error(t("config_errors_found"))
        for error in errors:
            logger.error(f"   - {error}")
        logger.error("")
        logger.error(t("please_run_setup"))
        logger.error(t("setup_command"))
        return False

    return True


def main():
    """Main function to continuously attempt instance creation."""

    global RESERVED_PUBLIC_IP

    logger.info("=" * 80)
    logger.info(t("title"))
    logger.info("=" * 80)

    # Validate configuration
    if not validate_configuration():
        sys.exit(1)

    logger.info(f"{t('target_shape')}: {SHAPE}")
    logger.info(f"{t('target_config')}: {OCPUS} OCPUs, {MEMORY_IN_GBS} GB RAM")
    logger.info(f"{t('availability_domains')}: {', '.join(AVAILABILITY_DOMAINS)}")
    logger.info(f"{t('retry_delay')}: {RETRY_DELAY_SECONDS} seconds")
    logger.info(f"{t('max_attempts')}: {MAX_ATTEMPTS}")
    logger.info("=" * 80)

    # Initialize OCI config and clients
    try:
        config = oci.config.from_file("~/.oci/config", CONFIG_PROFILE)
        compute_client = oci.core.ComputeClient(config)
        network_client = oci.core.VirtualNetworkClient(config)
        identity_client = oci.identity.IdentityClient(config)
        logger.info(f"✅ {t('oci_init_success')}")
    except Exception as e:
        logger.error(f"❌ {t('oci_init_failed')}: {str(e)}")
        if LANGUAGE == "DE":
            logger.error("\n" + "=" * 70)
            logger.error("📋 Du benötigst folgende Informationen:")
            logger.error(
                "   - User OCID (cloud.oracle.com → Benutzer-Symbol → Mein Profil)"
            )
            logger.error("   - Tenancy OCID (Benutzer-Symbol → Tenancy: [Name])")
            logger.error("   - Region (z.B. eu-frankfurt-1)")
            logger.error("=" * 70)
            logger.error("\n🔧 Führe aus: oci setup config")
            logger.error(
                "\nHinweis: Die folgenden Eingabeaufforderungen sind auf Englisch"
            )
            logger.error("(vom OCI SDK). Nutze die Informationen oben.\n")
        else:
            logger.error("Please run: oci setup config")
        sys.exit(1)

    # Get full availability domain names
    try:
        compartment = config["tenancy"]
        list_ads = identity_client.list_availability_domains(compartment)
        full_ad_names = [ad.name for ad in list_ads.data]
        logger.info(f"{t('available_ads')}: {', '.join(full_ad_names)}")
    except Exception as e:
        logger.warning(f"Could not fetch AD names: {str(e)}")
        full_ad_names = AVAILABILITY_DOMAINS

    # Ask about reserved IP
    logger.info("")
    logger.info("=" * 80)
    logger.info(f"ℹ️  {t('reserved_ip_info')}")
    logger.info(f"ℹ️  {t('reserved_ip_yes')}")
    logger.info("=" * 80)

    RESERVED_PUBLIC_IP = ask_yes_no(t("reserved_ip_prompt"))

    reserved_ip_obj = None
    reserved_ip_id = None

    if RESERVED_PUBLIC_IP:
        reserved_ip_obj = create_reserved_ip(network_client, COMPARTMENT_ID)
        if reserved_ip_obj:
            reserved_ip_id = reserved_ip_obj.id

    logger.info("")

    # Main retry loop
    attempt = 0
    while attempt < MAX_ATTEMPTS:
        attempt += 1
        logger.info(f"\n{'='*80}")
        logger.info(
            f"{t('attempt')} {attempt}/{MAX_ATTEMPTS} - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        )
        logger.info(f"{'='*80}")

        # Try each availability domain
        for ad in full_ad_names:
            success, instance = try_create_instance(compute_client, ad, reserved_ip_id)

            if success:
                # Wait for instance to be RUNNING
                instance, public_ip, private_ip = wait_for_instance_running(
                    compute_client, instance.id, network_client
                )

                # If reserved IP was created but no public IP from VNIC, use reserved IP
                if not public_ip and reserved_ip_obj:
                    public_ip = reserved_ip_obj.ip_address

                logger.info("\n" + "=" * 80)
                logger.info(f"🎉 {t('instance_created_title')}")
                logger.info("=" * 80)
                logger.info(f"{t('instance_details')}:")
                logger.info(f"  - Name: {instance.display_name}")
                logger.info(f"  - OCID: {instance.id}")
                logger.info(
                    f"  - {t('availability_domains')}: {instance.availability_domain}"
                )
                logger.info(f"  - Shape: {instance.shape}")
                logger.info(f"  - State: {instance.lifecycle_state}")

                if public_ip:
                    logger.info("")
                    logger.info("=" * 80)
                    logger.info(f"🌐 {t('ssh_connection_info')}")
                    logger.info("=" * 80)
                    logger.info(f"{t('public_ip')}: {public_ip}")
                    if private_ip:
                        logger.info(f"{t('private_ip')}: {private_ip}")
                    logger.info("")
                    logger.info(f"{t('ssh_command')}:")
                    logger.info(f"  ssh ubuntu@{public_ip}")
                    logger.info("")
                    logger.info("First-time connection (auto-accepts fingerprint):")
                    logger.info(
                        f"  ssh -o StrictHostKeyChecking=accept-new ubuntu@{public_ip}"
                    )
                    logger.info("=" * 80)

                    # Generate SSH config
                    generate_ssh_config(public_ip, instance.display_name)

                    # Send email notification
                    send_email_notification(instance, public_ip, private_ip)

                logger.info("")
                logger.info(f"{t('next_steps')}:")
                logger.info(f"{t('step_1')}")
                logger.info(f"{t('step_2')}")
                logger.info(f"{t('step_3')}")
                logger.info(f"{t('step_4')}")
                logger.info("=" * 80)
                return 0

            # Small delay between AD attempts
            time.sleep(2)

        # Wait before next attempt
        if attempt < MAX_ATTEMPTS:
            logger.info(t("waiting_before_retry").format(seconds=RETRY_DELAY_SECONDS))
            time.sleep(RETRY_DELAY_SECONDS)

    logger.warning(f"\n❌ {t('max_attempts_reached').format(attempts=MAX_ATTEMPTS)}")
    logger.info(t("script_can_restart"))
    return 1


if __name__ == "__main__":
    # Select language interactively if not set in config
    select_language()

    try:
        sys.exit(main())
    except KeyboardInterrupt:
        logger.info(f"\n\n⚠️  {t('script_interrupted')}")
        logger.info(t("script_can_restart"))
        sys.exit(0)
    except Exception as e:
        logger.error(f"\n❌ {t('fatal_error')}: {str(e)}")
        sys.exit(1)
