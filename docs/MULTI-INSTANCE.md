# Multi-Instance Setup Guide 🚀

Run multiple OCI Instance Snipers simultaneously for different regions!

**English Version** | [Deutsche Version](#deutsche-version)

---

## 🎯 What is Multi-Instance Mode?

Multi-Instance mode allows you to:
- ✅ Run multiple snipers for **different regions** simultaneously (Frankfurt + Paris + London...)
- ✅ Each instance has its **own configuration** (OCPUs, memory, reserved IP)
- ✅ **Independent logging** for each instance
- ✅ **Central management** through interactive menu
- ✅ Start/stop instances individually or all at once

## 🚀 Quick Start

### 1. Create Your First Instance

```powershell
.\scripts\multi\setup-instance.ps1
```

The script will ask you:
- **Instance Name**: e.g., "frankfurt", "paris", "london"
- **Region**: Select from 6 available regions
- **Resources**: OCPUs (1-4), Memory (6-24GB)
- **Reserved IP** (optional): Enter existing IP OCID or leave empty

### 2. Create More Instances

After creating the first instance, you'll be asked:
```
Create another instance? (y/n):
```

Answer **y** to create more instances for different regions!

### 3. Manage Your Instances

```powershell
# Interactive menu (recommended)
.\scripts\multi\manage-instances.ps1

# Or use direct commands:
.\scripts\multi\manage-instances.ps1 -Start frankfurt
.\scripts\multi\manage-instances.ps1 -Status
.\scripts\multi\manage-instances.ps1 -Logs frankfurt
.\scripts\multi\manage-instances.ps1 -Stop frankfurt
.\scripts\multi\manage-instances.ps1 -StopAll
```

## 📁 Directory Structure

```
oci-instance-sniper/
├── instances/
│   ├── frankfurt/              # Instance 1
│   │   ├── config/
│   │   │   └── sniper-config.json
│   │   └── logs/
│   │       ├── sniper_20250101_120000.log
│   │       └── sniper_20250101_130000.log
│   ├── paris/                  # Instance 2
│   │   ├── config/
│   │   │   └── sniper-config.json
│   │   └── logs/
│   └── london/                 # Instance 3
│       ├── config/
│       └── logs/
├── scripts/
│   ├── multi/
│   │   ├── setup-instance.ps1      # Create new instances
│   │   └── manage-instances.ps1    # Control instances
│   └── oci-instance-sniper.py
```

## 🎮 Interactive Manager Menu

```
============================================================
Instance Manager - Interactive Mode
============================================================

  1. Start Instance
  2. Stop Instance
  3. Show Status
  4. View Logs
  5. Stop All Instances
  0. Exit
```

## 📊 Example Multi-Region Setup

### Strategy: Maximize Your Chances

Free Tier allows **4 OCPUs and 24GB RAM total**. Here's a smart distribution:

**Option 1: Balanced (3 Regions)**
```
Frankfurt:  2 OCPUs, 12GB RAM  (Primary)
Paris:      1 OCPU,  6GB RAM   (Secondary)
London:     1 OCPU,  6GB RAM   (Tertiary)
```

**Option 2: Wide Coverage (4 Regions)**
```
Frankfurt:  1 OCPU,  6GB RAM
Paris:      1 OCPU,  6GB RAM
London:     1 OCPU,  6GB RAM
Amsterdam:  1 OCPU,  6GB RAM
```

**Option 3: Focus (2 Regions)**
```
Frankfurt:  2 OCPUs, 12GB RAM
Paris:      2 OCPUs, 12GB RAM
```

## 💡 Reserved IP Best Practices

Free Tier allows **2 reserved IPs** across all regions.

### Smart IP Allocation:

1. **Frankfurt** (most popular): Reserved IP
2. **Paris** (second choice): Reserved IP
3. **Other regions**: Ephemeral IPs (leave `reserved_public_ip_ocid` empty)

### How to Get Your Reserved IP OCID:

```bash
# List all reserved IPs
oci network public-ip list \
  --compartment-id <YOUR_COMPARTMENT_ID> \
  --scope REGION \
  --all

# Copy the "id" field from the output
```

### Config Example with Reserved IP:

```json
{
  "instance_name": "oci-frankfurt",
  "region": "eu-frankfurt-1",
  "reserved_public_ip_ocid": "ocid1.publicip.oc1.eu-frankfurt-1.ama..."
}
```

## 🔍 Status Monitoring

```powershell
.\scripts\multi\manage-instances.ps1 -Status
```

Output:
```
==================================================================================================
Instance Status
==================================================================================================

Instance   Region            Status    PID     Started
--------   ------            ------    ---     -------
frankfurt  eu-frankfurt-1    RUNNING   12345   2025-01-01 12:00:00
paris      eu-paris-1        RUNNING   12346   2025-01-01 12:05:00
london     uk-london-1       STOPPED   -       -

==================================================================================================
```

## 📜 Log Management

Each instance has its own log directory:

```powershell
# View live logs for specific instance
.\scripts\multi\manage-instances.ps1 -Logs frankfurt

# Or directly with PowerShell
Get-Content instances\frankfurt\logs\sniper_*.log -Wait -Tail 20
```

## 🎯 Command Reference

### setup-instance.ps1
Creates new instance configurations.

```powershell
# Interactive setup
.\scripts\multi\setup-instance.ps1

# The script will guide you through:
# 1. Instance name
# 2. Region selection
# 3. Resource allocation (OCPUs, Memory)
# 4. Optional reserved IP
```

### manage-instances.ps1

Manage all your instances from one place.

```powershell
# Interactive menu
.\scripts\multi\manage-instances.ps1
.\scripts\multi\manage-instances.ps1 -Interactive

# Start instance
.\scripts\multi\manage-instances.ps1 -Start frankfurt

# Stop instance
.\scripts\multi\manage-instances.ps1 -Stop frankfurt

# Stop all instances
.\scripts\multi\manage-instances.ps1 -StopAll

# Show status
.\scripts\multi\manage-instances.ps1 -Status

# View logs (live tail)
.\scripts\multi\manage-instances.ps1 -Logs frankfurt
```

## 🚀 Real-World Example

Let's create a 3-region setup:

```powershell
# Step 1: Create Frankfurt instance
.\scripts\multi\setup-instance.ps1

# Inputs:
# Name: frankfurt
# Region: 1 (eu-frankfurt-1)
# OCPUs: 2
# Memory: 12
# Reserved IP: ocid1.publicip....(your existing IP)

# Answer "y" to create another instance

# Step 2: Create Paris instance
# Name: paris
# Region: 2 (eu-paris-1)
# OCPUs: 1
# Memory: 6
# Reserved IP: ocid1.publicip....(your second IP)

# Answer "y" to create another instance

# Step 3: Create London instance
# Name: london
# Region: 4 (uk-london-1)
# OCPUs: 1
# Memory: 6
# Reserved IP: (leave empty for ephemeral)

# Answer "n" to finish setup

# Step 4: Start all instances
.\scripts\multi\manage-instances.ps1
# Select option 1 (Start Instance) for each region

# Step 5: Monitor status
.\scripts\multi\manage-instances.ps1 -Status
```

## ⚠️ Important Notes

### Free Tier Limits
- **Total Resources**: 4 OCPUs + 24GB RAM across all instances
- **Reserved IPs**: Maximum 2 across all regions
- **Storage**: 200GB total (shared across all instances you create)

### Running Simultaneously
- ✅ Multiple regions: **YES** (recommended!)
- ✅ Multiple PCs: **YES** (even better odds!)
- ❌ Same region twice: **NO** (will compete with yourself)

### Best Practices
1. **Prioritize regions**: Start with most likely to have capacity (Frankfurt, Ashburn)
2. **Stagger starts**: Start instances 30-60 seconds apart
3. **Monitor logs**: Check for errors in the first few minutes
4. **Be patient**: ARM instances are in high demand

## 🎉 When an Instance Succeeds

The instance will:
1. ✅ Create the VM automatically
2. ✅ Stop its own retry loop
3. ✅ Show success message in logs
4. ⚠️ **Other instances keep running** (you might get multiple VMs!)

**Remember**: Stop all other instances after success to avoid creating multiple VMs!

```powershell
# Quick stop all
.\scripts\multi\manage-instances.ps1 -StopAll
```

---

## Deutsche Version 🇩🇪

# Multi-Instance Setup Anleitung

Führe mehrere OCI Instance Sniper gleichzeitig für verschiedene Regionen aus!

## 🎯 Was ist der Multi-Instance Modus?

Der Multi-Instance Modus ermöglicht:
- ✅ Mehrere Sniper für **verschiedene Regionen** gleichzeitig (Frankfurt + Paris + London...)
- ✅ Jede Instance hat ihre **eigene Konfiguration** (OCPUs, RAM, reservierte IP)
- ✅ **Unabhängige Logs** für jede Instance
- ✅ **Zentrale Verwaltung** über interaktives Menü
- ✅ Instances einzeln oder alle zusammen starten/stoppen

## 🚀 Schnellstart

### 1. Erste Instance erstellen

```powershell
.\scripts\multi\setup-instance.ps1
```

Das Script fragt dich:
- **Instance-Name**: z.B. "frankfurt", "paris", "london"
- **Region**: Auswahl aus 6 verfügbaren Regionen
- **Ressourcen**: OCPUs (1-4), Arbeitsspeicher (6-24GB)
- **Reservierte IP** (optional): Vorhandene IP-OCID eingeben oder leer lassen

### 2. Weitere Instances erstellen

Nach der ersten Instance wirst du gefragt:
```
Weitere Instance erstellen? (j/n):
```

Antworte **j** um weitere Instances für andere Regionen zu erstellen!

### 3. Instances verwalten

```powershell
# Interaktives Menü (empfohlen)
.\scripts\multi\manage-instances.ps1

# Oder direkte Befehle:
.\scripts\multi\manage-instances.ps1 -Start frankfurt
.\scripts\multi\manage-instances.ps1 -Status
.\scripts\multi\manage-instances.ps1 -Logs frankfurt
.\scripts\multi\manage-instances.ps1 -Stop frankfurt
.\scripts\multi\manage-instances.ps1 -StopAll
```

## 📊 Beispiel Multi-Region Setup

### Strategie: Chancen maximieren

Free Tier erlaubt **4 OCPUs und 24GB RAM gesamt**. Hier eine smarte Verteilung:

**Option 1: Ausgewogen (3 Regionen)**
```
Frankfurt:  2 OCPUs, 12GB RAM  (Primär)
Paris:      1 OCPU,  6GB RAM   (Sekundär)
London:     1 OCPU,  6GB RAM   (Tertiär)
```

**Option 2: Breite Abdeckung (4 Regionen)**
```
Frankfurt:  1 OCPU,  6GB RAM
Paris:      1 OCPU,  6GB RAM
London:     1 OCPU,  6GB RAM
Amsterdam:  1 OCPU,  6GB RAM
```

## 💡 Reservierte IP Best Practices

Free Tier erlaubt **2 reservierte IPs** über alle Regionen.

### Smarte IP-Verteilung:

1. **Frankfurt** (beliebteste Region): Reservierte IP
2. **Paris** (zweite Wahl): Reservierte IP
3. **Andere Regionen**: Ephemeral IPs (`reserved_public_ip_ocid` leer lassen)

## ⚠️ Wichtige Hinweise

### Free Tier Limits
- **Gesamt-Ressourcen**: 4 OCPUs + 24GB RAM über alle Instances
- **Reservierte IPs**: Maximum 2 über alle Regionen
- **Speicher**: 200GB gesamt (geteilt über alle erstellten Instances)

### Gleichzeitiges Ausführen
- ✅ Mehrere Regionen: **JA** (empfohlen!)
- ✅ Mehrere PCs: **JA** (noch bessere Chancen!)
- ❌ Gleiche Region zweimal: **NEIN** (konkurriert mit sich selbst)

## 🎉 Wenn eine Instance erfolgreich ist

Die Instance wird:
1. ✅ Die VM automatisch erstellen
2. ✅ Ihre eigene Retry-Schleife stoppen
3. ✅ Erfolgsmeldung in Logs zeigen
4. ⚠️ **Andere Instances laufen weiter** (du könntest mehrere VMs bekommen!)

**Wichtig**: Stoppe alle anderen Instances nach Erfolg um mehrere VMs zu vermeiden!

```powershell
# Schnell alle stoppen
.\scripts\multi\manage-instances.ps1 -StopAll
```

---

## 🆘 Troubleshooting

### "No instances found"
- Run `setup-instance.ps1` first to create at least one instance

### Instance won't start
- Check if Python is installed: `python --version`
- Verify OCI CLI is configured: `oci setup config`
- Check instance logs in `instances\<name>\logs\`

### Reserved IP errors
- Verify IP OCID with: `oci network public-ip list --compartment-id <ID> --scope REGION --all`
- Remember: Free Tier allows only 2 reserved IPs total
- Leave field empty to use ephemeral IP

### Multiple VMs created
- This happens if you don't stop other instances after first success
- Solution: `manage-instances.ps1 -StopAll` immediately after first VM

---

**Back to**: [Main README](../README.md) | [Full Documentation](README.md)
