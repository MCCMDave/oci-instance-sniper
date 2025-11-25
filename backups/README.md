# Backups & Version History

This folder contains previous versions of the OCI Instance Sniper for reference and rollback purposes.

## Version History

### v1.3 (Current - November 2024)
**Main Script:** `../oci-instance-sniper.py`
**Control Menu:** `../control-menu.ps1`

**Changes:**
- Added automatic retry logic with exponential backoff (tenacity library)
- Implemented GitHub Actions CI/CD pipeline
- Added pre-commit hooks for code validation
- Fixed import ordering bug
- Improved config validation with fallback to defaults
- Enhanced SSH key validation with regex patterns
- Pinned dependency versions for stability
- Updated control-menu to v1.5 with comprehensive logging

**Backup Location:**
- `control-menu-v1.3-backup.ps1`

---

### v1.2 (November 2024)
**Backup Location:** (not saved - v1.1 backup available)

**Changes:**
- Instance status monitoring (waits for RUNNING state)
- Reserved Public IP support
- SSH config generator
- Email notifications (optional)
- Bilingual support (EN/DE)

---

### v1.1 (October 2024)
**Backup Location:**
- `oci-instance-sniper-v1.1-backup.py`

**Changes:**
- Basic instance creation with multi-AZ support
- Smart retry logic (60s interval, 24h max)
- Comprehensive logging
- Control menu for easy management

---

## Usage

To rollback to a previous version:
```powershell
# Example: Rollback to v1.1
cp backups/oci-instance-sniper-v1.1-backup.py oci-instance-sniper.py
```

To compare versions:
```powershell
# Compare current with v1.1
git diff backups/oci-instance-sniper-v1.1-backup.py oci-instance-sniper.py
```

## Backup Policy

- Major version changes are backed up before release
- Backup files follow naming: `{filename}-v{version}-backup.{ext}`
- Only significant releases are backed up (not every commit)
- Backups are tracked in Git for team access
