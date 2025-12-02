# OCI Instance Sniper 🎯

Automatically creates ARM instances (VM.Standard.A1.Flex) in Oracle Cloud Infrastructure when capacity becomes available.

**English Version** | [Deutsche Version](docs/README.de.md)

## 🚀 Quick Start

### Option 1: Multi-Instance Mode ⭐ NEW!
Run multiple regions simultaneously for maximum success!

```powershell
# 1. Create instances for different regions
.\scripts\multi\setup-instance.ps1

# 2. Manage all instances
.\scripts\multi\manage-instances.ps1
```

**Perfect for:**
- Testing multiple regions at once (Frankfurt + Paris + London)
- Maximizing your chances of getting an ARM instance
- Independent configs per region (different IPs, resources)

[📖 Multi-Instance Guide](docs/MULTI-INSTANCE.md)

### Option 2: Single Instance Mode
Traditional setup for one region:

```powershell
# 1. Setup (one time)
.\scripts\single\setup.ps1

# 2. Run Control Menu
.\scripts\single\control-menu.ps1
```

The menu lets you:
- Start in foreground (see live output)
- Start in background (runs hidden until PC off)
- Start via Task Scheduler (survives reboots)
- Check status, view logs, stop script

### Option 3: Direct Execution
```powershell
# Run directly in terminal
python scripts\oci-instance-sniper.py
```

The script will run for 24 hours, checking every 60 seconds.

## 📋 What You Need

- Oracle Cloud account (Free Tier works!)
- Windows with PowerShell
- Python 3.8+ (auto-installed if missing)

## 📚 Full Documentation

For complete documentation, troubleshooting, and advanced features, see:
- [**Multi-Instance Setup Guide** ⭐ NEW!](docs/MULTI-INSTANCE.md)
- [**English Documentation**](docs/README.md)
- [**Deutsche Dokumentation**](docs/README.de.md)
- [**Encoding Rules**](docs/ENCODING-RULES.md)

## 📁 Project Structure

```
oci-instance-sniper/
├── docs/                      # Documentation
│   ├── MULTI-INSTANCE.md     # Multi-instance guide ⭐ NEW!
│   ├── README.md             # Full English docs
│   └── README.de.md          # Full German docs
├── scripts/                      # Scripts
│   ├── multi/                   # Multi-instance mode ⭐ NEW!
│   │   ├── manage-instances.ps1 # Instance manager
│   │   └── setup-instance.ps1   # Multi-instance setup
│   ├── single/                  # Single-instance mode
│   │   ├── control-menu.ps1     # Control menu
│   │   └── setup.ps1            # Setup wizard
│   └── oci-instance-sniper.py   # Main Python script (shared)
├── instances/                 # Multi-instance configs ⭐ NEW!
│   ├── frankfurt/
│   ├── paris/
│   └── .../
├── config/                    # Single instance config
└── requirements.txt          # Python dependencies
```

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
