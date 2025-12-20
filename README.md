# OCI Instance Sniper

Automatisch ARM-Instanzen (VM.Standard.A1.Flex) in Oracle Cloud erstellen sobald Kapazität verfügbar ist.

[English](#english) | **Deutsch**

## Schnellstart

```powershell
# 1. OCI CLI einrichten (einmalig)
oci setup config

# 2. Menü starten
.\start.bat
```

## Menü-Optionen

```
============================================================
  OCI Instance Sniper
============================================================

  Konfigurierte Regionen:

  [1] Frankfurt - eu-frankfurt-1

  ----------------------------------------
  [A] Alle Regionen gleichzeitig (parallel)
  [S] Setup neue Region
  [0] Beenden
```

- **Einzelne Region:** Nummer wählen, dann Vordergrund oder Hintergrund
- **Alle parallel:** `A` startet alle konfigurierten Regionen im Hintergrund
- **Neue Region:** `S` führt durch Setup (Subnet + Image OCID eingeben)

## Konfiguration

`config/sniper-config.json`:
```json
{
  "instance_name": "oci-instance",
  "ocpus": 2,
  "memory_in_gbs": 12,
  "language": "DE",
  "email": {
    "enabled": true,
    "smtp_server": "smtp.gmail.com",
    "from": "deine@email.de",
    "to": "deine@email.de",
    "password": "app-password"
  }
}
```

`config/regions.json` - Pro Region: Subnet + Image OCID

## Projektstruktur

```
oci-instance-sniper/
├── config/
│   ├── sniper-config.json
│   └── regions.json
├── docs/LICENSE
├── scripts/
│   ├── oci-instance-sniper.py
│   └── start.ps1
├── README.md
├── requirements.txt
└── start.bat
```

---

# English

Automatically creates ARM instances (VM.Standard.A1.Flex) in Oracle Cloud when capacity becomes available.

## Quick Start

```powershell
# 1. Setup OCI CLI (once)
oci setup config

# 2. Start menu
.\start.bat
```

## Menu Options

- **Single region:** Select number, then foreground or background
- **All parallel:** `A` starts all configured regions in background
- **New region:** `S` guides through setup (Subnet + Image OCID)

## Configuration

`config/sniper-config.json` - General settings + email notification
`config/regions.json` - Region-specific OCIDs (Subnet, Image, Compartment)

## Features

- Multi-region support with parallel execution
- Background mode with logging
- Email notification on success
- Bilingual (DE/EN)

## License

Apache License 2.0
