# OCI Instance Sniper 🎯

Automatically creates ARM instances (VM.Standard.A1.Flex) in Oracle Cloud Infrastructure when capacity becomes available.

## 🚀 Quick Start

```powershell
# 1. Setup (one time)
.\setup.ps1

# 2. Run
python oci-instance-sniper.py
```

That's it! The script will run for 24 hours, checking every 60 seconds.

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

- **Smart Retry**: Attempts every 60 seconds for 24 hours
- **Multi-AZ**: Tests all 3 Availability Domains
- **Comprehensive Logging**: Everything logged to `oci-sniper.log`
- **Zero Config**: Setup script does everything automatically

## 📊 Configuration (Optional)

Edit `oci-instance-sniper.py` if you want to change:

```python
OCPUS = 2              # Number of OCPUs (max 4 for Free Tier)
MEMORY_IN_GBS = 12     # RAM in GB (max 24 for Free Tier)
RETRY_DELAY_SECONDS = 60
MAX_ATTEMPTS = 1440    # 24 hours
```

## 💡 Tips for Success

- **Be patient**: ARM instances are highly sought after. Can take hours/days.
- **Best times**: Run overnight and on weekends
- **Multiple attempts**: Run on multiple machines for better odds
- **Monitor logs**: `Get-Content -Path oci-sniper.log -Wait -Tail 20`

## 🎉 When It Succeeds

```
🎉 INSTANCE SUCCESSFULLY CREATED!
Instance Name: nextcloud-backup-instance
Instance OCID: ocid1.instance...
Availability Domain: AD-2
Shape: VM.Standard.A1.Flex
State: PROVISIONING

Next steps:
1. Wait for instance to reach 'RUNNING' state
2. Get public IP from OCI console
3. SSH into instance: ssh ubuntu@<PUBLIC_IP>
```

## 🔧 Troubleshooting

**OCI CLI not found after setup?**
```powershell
# Restart PowerShell and try again
```

**No VCN found?**
```
Create a VCN in OCI Console:
Networking → Virtual Cloud Networks → Create VCN
```

**Script keeps finding no capacity?**
```
This is normal! ARM instances are very popular.
Keep it running - it will succeed eventually.
```

## 📄 License

MIT License - Use freely!

## 👤 Author

**Dave Vaupel**
- GitHub: [@davidvaupel](https://github.com/davidvaupel)
- Building expertise in Cloud Infrastructure & Customer Success Engineering

---

**Built to beat the "Out of host capacity" error! ☁️**
