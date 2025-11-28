# 📦 OCI Instance Sniper - Installation & Benötigte Dateien

## Übersicht

Dieses Dokument erklärt, welche Dateien du für den OCI Instance Sniper benötigst und wie du sie einrichtest.

## 📁 Benötigte Dateien

### Minimale Installation (nur was du WIRKLICH brauchst):

```
oci-instance-sniper/
├── scripts/
│   ├── oci-instance-sniper.py    # Haupt-Script (ERFORDERLICH)
│   └── control-menu.ps1           # Windows Control Menu (ERFORDERLICH für Windows)
├── config/
│   └── sniper-config.json         # Konfiguration (wird automatisch erstellt)
├── requirements.txt               # Python-Dependencies (ERFORDERLICH)
└── README.md                      # Dokumentation (optional, aber empfohlen)
```

### Vollständige Installation (alle Dateien):

```
oci-instance-sniper/
├── scripts/
│   ├── oci-instance-sniper.py    # Haupt-Script
│   └── control-menu.ps1           # Windows Control Menu
├── config/
│   └── sniper-config.json         # Konfiguration
├── docs/
│   ├── README.de.md               # Deutsche Dokumentation
│   └── ENCODING-RULES.md          # UTF-8 Guidelines
├── requirements.txt               # Python-Dependencies
├── README.md                      # Englische Dokumentation
├── LICENSE                        # Apache 2.0 Lizenz
└── .gitignore                     # Git-Ignore Regeln
```

## ⚙️ Setup Schritt-für-Schritt

### 1. Dateien herunterladen

**Option A: Git Clone (empfohlen)**
```bash
git clone https://github.com/MCCMDave/oci-instance-sniper.git
cd oci-instance-sniper
```

**Option B: Nur die wichtigsten Dateien**
Lade folgende Dateien herunter:
- `scripts/oci-instance-sniper.py`
- `scripts/control-menu.ps1` (nur Windows)
- `requirements.txt`

### 2. Python-Dependencies installieren

```bash
pip install -r requirements.txt
```

**Installierte Pakete:**
- `oci==2.133.0` - OCI SDK
- `tenacity==8.2.3` - Retry-Logik

### 3. OCI-Konfiguration

**Beim ersten Start** fragt das Script nach:
- User OCID
- Tenancy OCID
- Region
- Compartment OCID
- SSH Public Key
- API Key (Fingerprint + Private Key Path)

Diese werden in `~/.oci/config` gespeichert:
```
C:\Users\<username>\.oci\config    # Windows
/home/<username>/.oci/config       # Linux
```

### 4. Sniper-Konfiguration

Wird automatisch erstellt in `config/sniper-config.json`:
```json
{
    "instance_name": "oci-instance",
    "ocpus": 2,
    "memory_in_gbs": 12,
    "image": "ubuntu",
    "retry_delay_seconds": 60,
    "max_attempts": 1440,
    "region": "eu-frankfurt-1",
    "language": "DE"
}
```

## 🚀 Start-Methoden

### Windows (mit Control-Menu):
```powershell
.\scripts\control-menu.ps1
```

Dann wähle:
- **1** - Vordergrund (siehst Live-Output)
- **2** - Hintergrund (läuft versteckt)
- **3** - Task Scheduler (überlebt Reboots)

### Linux / Direkt:
```bash
python scripts/oci-instance-sniper.py
```

## 📂 Optionale Dateien

Diese Dateien sind **nicht zwingend erforderlich**, aber nützlich:

| Datei | Zweck | Notwendig? |
|-------|-------|-----------|
| `README.md` | Englische Doku | Optional |
| `docs/README.de.md` | Deutsche Doku | Optional |
| `LICENSE` | Apache 2.0 Lizenz | Optional (Open Source) |
| `.gitignore` | Git-Ignore | Optional (nur für Git) |
| `docs/ENCODING-RULES.md` | UTF-8 Guidelines | Optional |

## 🔧 Troubleshooting

### "ModuleNotFoundError: No module named 'oci'"
→ Führe aus: `pip install -r requirements.txt`

### "FileNotFoundError: ~/.oci/config not found"
→ Führe das Script einmal aus, es fragt nach den OCIDs

### "Script läuft nicht im Hintergrund"
→ Nutze `control-menu.ps1` Option 2 (Windows) oder `nohup` (Linux)

### OCIDs zurücksetzen
→ Control-Menu → Option 7 (Configuration) → Option 8 (Reset OCIDs)
→ Oder: Lösche `~/.oci/config` manuell

## 📝 Minimale Setup-Checkliste

Zum Starten brauchst du **nur diese 3 Dateien**:

- [ ] `scripts/oci-instance-sniper.py`
- [ ] `requirements.txt`
- [ ] `scripts/control-menu.ps1` (Windows) ODER direkter Python-Aufruf (Linux)

**Plus:**
- [ ] Python 3.7+ installiert
- [ ] OCI Account mit Free Tier
- [ ] API Keys erstellt (in OCI Console)

## 🎯 Quick Start

```bash
# 1. Dateien holen
git clone https://github.com/MCCMDave/oci-instance-sniper.git
cd oci-instance-sniper

# 2. Dependencies installieren
pip install -r requirements.txt

# 3. Script starten
python scripts/oci-instance-sniper.py

# Beim ersten Start: OCIDs eingeben
# Danach: Script läuft automatisch!
```

## 📊 Dateigrößen

- `oci-instance-sniper.py`: ~15 KB
- `control-menu.ps1`: ~25 KB
- `requirements.txt`: <1 KB
- `sniper-config.json`: <1 KB

**Gesamt:** ~50 KB (ohne Dependencies)

## 🔄 Updates

**Um auf die neueste Version zu updaten:**

```bash
git pull origin main
pip install -r requirements.txt --upgrade
```

---

**Fragen?** Erstelle ein [Issue auf GitHub](https://github.com/MCCMDave/oci-instance-sniper/issues)
