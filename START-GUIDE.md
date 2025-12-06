# OCI Instance Sniper - Start Guide

## 🚀 Schnellstart - Welches Skript nutzen?

### **Option 1: Single-Instance (Eine Region)** ⭐ Einfachste Methode

**Für:** Nur eine Region (z.B. nur Frankfurt)

**Start-Methoden:**

#### A) Doppelklick .bat Dateien (Einfachste Methode)
```
start-sniper.bat                 → Sichtbares Fenster
start-sniper-background.bat      → Versteckt im Hintergrund
```

#### B) PowerShell Control Menu (Mehr Features)
```powershell
.\scripts\single\control-menu.ps1
```
**Features:**
- Foreground / Background / Task Scheduler
- Live-Logs anzeigen
- Status prüfen
- Konfiguration ändern

---

### **Option 2: Multi-Instance (Mehrere Regionen gleichzeitig)** 🌍

**Für:** Mehrere Regionen parallel (Frankfurt + Paris + London)

**Start-Methoden:**

#### A) Doppelklick .bat Datei
```
start-multi-instance.bat         → Interaktives Menü
```

#### B) PowerShell direkt
```powershell
.\scripts\multi\manage-instances.ps1 -Interactive
```

**Features:**
- Mehrere Regionen gleichzeitig snipen
- Separate Configs pro Region
- Unabhängige Start/Stop pro Region
- Gemeinsame Logs oder getrennt

---

## 📂 Verzeichnis-Struktur

```
oci-instance-sniper/
├── start-sniper.bat               ← Single-Instance (sichtbar)
├── start-sniper-background.bat    ← Single-Instance (versteckt)
├── start-multi-instance.bat       ← Multi-Instance Manager
├── config/
│   └── sniper-config.json         ← Single-Instance Config
├── instances/                     ← Multi-Instance Configs
│   ├── frankfurt/
│   │   └── sniper-config.json
│   ├── paris/
│   │   └── sniper-config.json
│   └── london/
│       └── sniper-config.json
└── scripts/
    ├── oci-instance-sniper.py     ← Haupt-Script (von allen genutzt)
    ├── single/
    │   ├── control-menu.ps1       ← Single-Instance Menü
    │   └── setup.ps1              ← Erst-Einrichtung
    └── multi/
        ├── manage-instances.ps1   ← Multi-Instance Manager
        └── setup-instance.ps1     ← Neue Region hinzufügen
```

---

## 🔧 Welche Skripte können gelöscht werden?

### **Wenn du NUR Multi-Instance nutzt:**

**Behalten:**
- `start-multi-instance.bat` ✅
- `scripts/multi/*.ps1` ✅
- `scripts/oci-instance-sniper.py` ✅ (wird von Multi genutzt!)

**Kann gelöscht werden:**
- `start-sniper.bat` ❌
- `start-sniper-background.bat` ❌
- `scripts/single/control-menu.ps1` ❌
- `scripts/single/setup.ps1` ❌
- `config/sniper-config.json` ❌

---

### **Wenn du NUR Single-Instance nutzt:**

**Behalten:**
- `start-sniper.bat` ✅
- `start-sniper-background.bat` ✅
- `scripts/single/*.ps1` ✅
- `scripts/oci-instance-sniper.py` ✅
- `config/sniper-config.json` ✅

**Kann gelöscht werden:**
- `start-multi-instance.bat` ❌
- `scripts/multi/*.ps1` ❌
- `instances/` Ordner ❌

---

### **Wenn du BEIDES nutzt (Empfohlen):**

**Alles behalten!** ✅

**Use Case:**
- Multi-Instance für paralleles Snipen in mehreren Regionen
- Single-Instance für schnelle Tests oder einzelne Region

---

## 🎯 Empfehlung

**Für maximale Erfolgsrate:**
```bash
# Nutze Multi-Instance mit 3 Regionen
start-multi-instance.bat

# Im Menü wählen:
1. Frankfurt starten
2. Paris starten
3. London starten

→ 3x höhere Chance auf ARM Instance!
```

**Für einfache Nutzung:**
```bash
# Einfach Doppelklick
start-sniper.bat

→ Nur Frankfurt, aber super einfach
```

---

## ⚙️ Konfiguration

### Single-Instance Config
**Datei:** `config/sniper-config.json`
```json
{
  "instance_name": "oci-instance",
  "ocpus": 2,
  "memory_in_gbs": 12,
  "region": "eu-frankfurt-1",
  "language": "EN"
}
```

### Multi-Instance Configs
**Dateien:** `instances/*/sniper-config.json`
```
instances/
├── frankfurt/sniper-config.json  (region: eu-frankfurt-1)
├── paris/sniper-config.json      (region: eu-paris-1)
└── london/sniper-config.json     (region: uk-london-1)
```

---

## 🔍 Logs

### Single-Instance
```
oci-sniper.log                    ← Haupt-Log
control-menu.log                  ← Control Menu Log
```

### Multi-Instance
```
instances/frankfurt/sniper.log
instances/paris/sniper.log
instances/london/sniper.log
```

---

## 📝 Zusammenfassung

| Szenario | Nutze | Dateien | Erfolgsrate |
|----------|-------|---------|-------------|
| **Anfänger** | `start-sniper.bat` | Single-Instance | 1x |
| **Power-User** | `control-menu.ps1` | Single-Instance | 1x |
| **Pro** | `start-multi-instance.bat` | Multi-Instance | 3x |
| **Maximum** | Multi + 5 Regionen | Multi-Instance | 5x |

---

## 🚨 Wichtig

**Das Python-Script `oci-instance-sniper.py` wird von ALLEN Modi genutzt!**
- Single-Instance ruft es direkt auf
- Multi-Instance ruft es mit `SNIPER_CONFIG_PATH` auf

**→ NIEMALS `oci-instance-sniper.py` löschen!**

---

## 🎁 Bonus: Kommandozeilen-Nutzung

### Single-Instance direkt
```bash
python scripts/oci-instance-sniper.py
```

### Multi-Instance: Frankfurt starten
```powershell
.\scripts\multi\manage-instances.ps1 -Start frankfurt
```

### Multi-Instance: Status aller Regionen
```powershell
.\scripts\multi\manage-instances.ps1 -Status
```

---

**Fertig!** Wähle die Methode, die zu dir passt. 🚀
