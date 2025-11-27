# OCI Instance Sniper 🎯

Automatically creates ARM instances (VM.Standard.A1.Flex) in Oracle Cloud Infrastructure when capacity becomes available.

**English Version** | [Deutsche Version](docs/README.de.md)

## 🚀 Quick Start

### Option 1: Interactive Control Menu (Recommended)
```powershell
# 1. Setup (one time)
.\scripts\setup.ps1

# 2. Run Control Menu
.\scripts\control-menu.ps1
```

The menu lets you:
- Start in foreground (see live output)
- Start in background (runs hidden until PC off)
- Start via Task Scheduler (survives reboots)
- Check status, view logs, stop script

### Option 2: Direct Execution
```powershell
# Run directly in terminal
python oci-instance-sniper.py
```

The script will run for 24 hours, checking every 60 seconds.

## 📋 What You Need

- Oracle Cloud account (Free Tier works!)
- Windows with PowerShell
- Python 3.8+ (auto-installed if missing)

## 📚 Full Documentation

For complete documentation, troubleshooting, and advanced features, see:
- [**English Documentation**](docs/README.md)
- [**Deutsche Dokumentation**](docs/README.de.md)
- [**Encoding Rules**](docs/ENCODING-RULES.md)

## 📁 Project Structure

```
oci-instance-sniper/
├── docs/                      # Documentation
├── scripts/                   # Setup and control scripts
├── config/                    # Configuration files
├── backups/                   # Backup files
├── oci-instance-sniper.py    # Main script
└── requirements.txt          # Python dependencies
```

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
