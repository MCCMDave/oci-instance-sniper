# OCI Instance Sniper 🎯

Automatically creates ARM instances (VM.Standard.A1.Flex) in Oracle Cloud Infrastructure when capacity becomes available.

**English Version** | [Deutsche Version](README.de.md)

## 🚀 Quick Start

### Option 1: Interactive Control Menu (Recommended)
```powershell
# 1. Setup (one time)
.\setup.ps1

# 2. Run Control Menu
.\control-menu.ps1
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

## ⚡ What `setup.ps1` Does

1. ✅ Checks/installs Python
2. ✅ Installs OCI CLI
3. ✅ Guides you through OCI credential setup
4. ✅ Automatically fetches all required OCIDs
5. ✅ Configures the Python script for you

No manual configuration needed!

## 🎯 Features

### Core Features
- ✅ **Smart Retry**: Attempts every 60 seconds for 24 hours
- ✅ **Multi-AZ**: Tests all 3 Availability Domains
- ✅ **Instance Status Monitoring**: Waits for RUNNING state automatically
- ✅ **Auto Public IP Retrieval**: Shows IP immediately when ready
- ✅ **SSH Config Generator**: Creates ready-to-use SSH config
- ✅ **Reserved IP Support**: Optional static IP (recommended!)
- 🔔 **Email Notifications**: Get notified when instance is ready *(Optional)*
- 📊 **Comprehensive Logging**: Everything logged to `oci-sniper.log`

### Control Menu Features (NEW!)
- 🎮 **Interactive Menu**: Easy-to-use control interface
- 🖥️ **Foreground Mode**: See live output in terminal
- 🔄 **Background Mode**: Runs hidden until PC shutdown
- 📅 **Task Scheduler Mode**: Survives system reboots
- 📊 **Status Check**: See what's running at a glance
- 📜 **Live Log Viewer**: Monitor progress in real-time
- 🛑 **Stop Control**: Safely stop all running instances
- 🌍 **Bilingual**: Full English and German support

## 🆕 What's New in v1.2

### **Instance Status Monitoring**
No more manual checking! The script now:
- Waits automatically until instance reaches RUNNING state
- Shows progress: PROVISIONING → STARTING → RUNNING
- Displays Public IP immediately
- Generates ready-to-copy SSH command

**Before (v1.1):**
```
✅ Instance created!
Next steps: Go to OCI Console and get IP...
```

**Now (v1.2):**
```
✅ Instance created!
⏳ Waiting for RUNNING state...
⏳ Instance state: PROVISIONING (30s)
⏳ Instance state: STARTING (60s)
✅ Instance is now RUNNING!

🌐 SSH CONNECTION INFO
Public IP: 123.45.67.89
SSH Command: ssh ubuntu@123.45.67.89

📝 SSH config generated: ssh-config-oci.txt
```

### **Reserved Public IP (Optional)**
Keep the same IP even after instance stop/start!

**Benefits:**
- ✅ IP stays the same forever
- ✅ Perfect for SSH config (`~/.ssh/config`)
- ✅ Easy to remember
- ✅ Free in Oracle Free Tier

**You'll be asked when running the script:**
```
Do you want to create a RESERVED Public IP? (y/n):
```

### **SSH Config Generator**
Automatically creates `ssh-config-oci.txt`:
```ssh
Host oci
    HostName 123.45.67.89
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking accept-new
```

Just copy to `~/.ssh/config` and use: `ssh oci`

### **Email Notifications (Optional)**

Get notified when your instance is ready!

**Perfect for:**
- 🛌 Running script overnight
- 📱 Getting phone notification (Gmail app)
- 💼 Running on remote machine

**Setup (2 minutes):**

1. **Get Gmail App Password:**
   ```
   Google Account → Security → 2-Step Verification (enable)
   → App passwords → Generate
   → Copy 16-character password
   ```

2. **Edit `oci-instance-sniper.py`:**
   ```python
   EMAIL_NOTIFICATIONS_ENABLED = True
   EMAIL_FROM = "your@gmail.com"
   EMAIL_TO = "your@gmail.com"
   EMAIL_PASSWORD = "your-16-char-app-password"
   ```

3. **Done!** Email will be sent automatically when instance is ready.

**Email includes:**
- ✅ Instance details (Name, Shape, Region, AD)
- ✅ Public IP address
- ✅ Ready-to-copy SSH command
- ✅ Next steps guide

**Don't want emails?** Just leave `EMAIL_NOTIFICATIONS_ENABLED = False` (default)

**Alternative email providers:**
- **Outlook:** `smtp.office365.com:587`
- **GMX:** `mail.gmx.net:587`
- **Web.de:** `smtp.web.de:587`

### **Bilingual Support**
Switch between English and German:
```python
LANGUAGE = "EN"  # or "DE" for German
```

All messages, logs, and prompts in your language!

### **Control Menu (v1.3 - NEW!)**

The interactive control menu makes it easy to manage the sniper script!

**Usage:**
```powershell
.\control-menu.ps1
```

**Features:**
1. **Foreground Mode** - Run in terminal, see all output live
2. **Background Job Mode** - Runs hidden in background until PC shutdown
3. **Task Scheduler Mode** - Survives reboots, starts automatically
4. **Status Check** - See what's running instantly
5. **Live Logs** - View logs in real-time (Ctrl+C to exit)
6. **Stop Script** - Safely stops all running instances

**Language Setting:**
Edit `control-menu.ps1` to change language:
```powershell
$LANGUAGE = "EN"  # or "DE" for German
```

**Multiple Instances:**
Yes! You can run multiple instances simultaneously:
- Multiple background jobs on same PC ✅
- Multiple PCs running the script ✅
- Different regions/configurations ✅

## 📊 Configuration (Optional)

Edit `oci-instance-sniper.py` if you want to change:

```python
# Instance Configuration
OCPUS = 2              # Number of OCPUs (max 4 for Free Tier)
MEMORY_IN_GBS = 12     # RAM in GB (max 24 for Free Tier)

# Retry Configuration
RETRY_DELAY_SECONDS = 60    # Wait time between attempts
MAX_ATTEMPTS = 1440         # 24 hours

# Language
LANGUAGE = "EN"  # "EN" or "DE"

# Email Notifications (Optional)
EMAIL_NOTIFICATIONS_ENABLED = False  # Set to True to enable
EMAIL_FROM = "your@gmail.com"
EMAIL_TO = "your@gmail.com"
EMAIL_PASSWORD = "your-app-password"
```

## 💡 Tips for Success

### **Timing Matters**
- 🌙 **Best times**: 2-6 AM UTC (Oracle maintenance window)
- 📅 **Weekends**: Higher success rate on Saturday/Sunday
- 🌍 **Best regions**: eu-frankfurt-1, us-ashburn-1

### **Be Patient**
- ⏱️ ARM instances are highly sought after
- 📊 **Average wait**: 2-8 hours (can vary)
- 🎲 **Max reported**: Up to 3-5 days

### **Multiple Attempts**
- 💻 Run on multiple machines for better odds
- 📱 Keep script running overnight with email notifications

### **Monitor Logs**
```powershell
# Live tail of logs
Get-Content -Path oci-sniper.log -Wait -Tail 20
```

## 🎉 When It Succeeds

```
🎉 INSTANCE SUCCESSFULLY CREATED!
Instance Details:
  - Name: nextcloud-backup-instance
  - OCID: ocid1.instance...
  - Availability Domain: AD-2
  - Shape: VM.Standard.A1.Flex
  - State: RUNNING

🌐 SSH CONNECTION INFO
Public IP: 123.45.67.89
Private IP: 10.0.0.42

SSH Command:
  ssh ubuntu@123.45.67.89

First-time connection (auto-accepts fingerprint):
  ssh -o StrictHostKeyChecking=accept-new ubuntu@123.45.67.89

📝 SSH config generated: ssh-config-oci.txt
📧 Email notification sent to: your@gmail.com

Next steps:
1. SSH into instance using command above
2. Update system: sudo apt update && sudo apt upgrade -y
3. Install Docker: curl -fsSL https://get.docker.com | sh
4. Deploy Nextcloud!
```

## 🔧 Troubleshooting

### **Configuration errors on startup?**
```powershell
# Run setup script to configure OCIDs automatically
.\setup.ps1
```

### **OCI CLI not found after setup?**
```powershell
# Restart PowerShell and try again
```

### **No VCN found during setup?**
```
Create a VCN in OCI Console:
Networking → Virtual Cloud Networks → Create VCN
Use "VCN Wizard" for quickest setup
```

### **Script keeps finding no capacity?**
```
This is normal! ARM instances are very popular.
- Keep it running - it will succeed eventually
- Enable email notifications to get notified overnight
- Try different times (see "Tips for Success" above)
```

### **Email not working?**
```
Common issues:
- Gmail: Make sure you use App Password, not regular password
- 2FA: Must be enabled in Google Account for App Passwords
- Firewall: Check if port 587 is blocked
- Test email manually to verify SMTP settings
```

### **Reserved IP not attached?**
```
The instance will use ephemeral IP during creation.
Reserved IP will be used on next restart/re-creation.
Or manually attach it via OCI Console:
Networking → Public IPs → Attach to Instance
```

## 📄 License

MIT License - Use freely!

## 👤 Author

**Dave Vaupel**
- GitHub: [@MCCMDave](https://github.com/MCCMDave)
- Building expertise in Cloud Infrastructure & Customer Success Engineering

## 🙏 Acknowledgments

- Oracle Cloud Infrastructure for Free Tier ARM instances
- Community feedback for feature requests

---

**Built to beat the "Out of host capacity" error! ☁️**

*Star ⭐ this repo if it helped you get your ARM instance!*
