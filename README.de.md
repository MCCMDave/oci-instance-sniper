# OCI Instance Sniper 🎯

Erstellt automatisch ARM-Instanzen (VM.Standard.A1.Flex) in Oracle Cloud Infrastructure, sobald Kapazität verfügbar wird.

[English Version](README.md) | **Deutsche Version**

## 🚀 Schnellstart

### Option 1: Interaktives Kontrollmenü (Empfohlen)
```powershell
# 1. Setup (einmalig)
.\setup.ps1

# 2. Kontrollmenü starten
.\control-menu.ps1
```

Das Menü ermöglicht:
- Start im Vordergrund (Live-Ausgabe sichtbar)
- Start im Hintergrund (läuft versteckt bis PC aus)
- Start via Aufgabenplanung (überlebt Neustarts)
- Status prüfen, Logs anzeigen, Skript stoppen

### Option 2: Direkte Ausführung
```powershell
# Direkt im Terminal ausführen
python oci-instance-sniper.py
```

Das Skript läuft 24 Stunden und prüft alle 60 Sekunden.

## 📋 Was du brauchst

- Oracle Cloud Account (Free Tier funktioniert!)
- Windows mit PowerShell
- Python 3.8+ (wird automatisch installiert falls fehlend)

## ⚡ Was `setup.ps1` macht

1. ✅ Prüft/installiert Python
2. ✅ Installiert OCI CLI
3. ✅ Führt dich durch die OCI-Anmeldedaten-Einrichtung
4. ✅ Holt automatisch alle benötigten OCIDs
5. ✅ Konfiguriert das Python-Skript für dich

Keine manuelle Konfiguration nötig!

## 🎯 Features

### Kern-Features
- ✅ **Smart Retry**: Versucht alle 60 Sekunden für 24 Stunden
- ✅ **Multi-AZ**: Testet alle 3 Availability Domains
- ✅ **Instanz-Status-Überwachung**: Wartet automatisch auf RUNNING Status
- ✅ **Auto Public IP Abruf**: Zeigt IP sofort an wenn bereit
- ✅ **SSH Config Generator**: Erstellt fertige SSH-Konfiguration
- ✅ **Reserved IP Support**: Optionale statische IP (empfohlen!)
- 🔔 **E-Mail-Benachrichtigungen**: Werde benachrichtigt wenn Instanz bereit ist *(Optional)*
- 📊 **Umfassendes Logging**: Alles wird in `oci-sniper.log` protokolliert

### Kontrollmenü-Features (NEU!)
- 🎮 **Interaktives Menü**: Einfach zu bedienende Steuerungsoberfläche
- 🖥️ **Vordergrund-Modus**: Live-Ausgabe im Terminal sehen
- 🔄 **Hintergrund-Modus**: Läuft versteckt bis PC-Neustart
- 📅 **Aufgabenplanungs-Modus**: Überlebt System-Neustarts
- 📊 **Status-Prüfung**: Siehst auf einen Blick was läuft
- 📜 **Live-Log-Viewer**: Fortschritt in Echtzeit überwachen
- 🛑 **Stopp-Kontrolle**: Stoppt alle laufenden Instanzen sicher
- 🌍 **Zweisprachig**: Volle Unterstützung für Deutsch und Englisch

## 🆕 Neu in v1.2

### **Instanz-Status-Überwachung**
Kein manuelles Prüfen mehr! Das Skript:
- Wartet automatisch bis Instanz RUNNING Status erreicht
- Zeigt Fortschritt: PROVISIONING → STARTING → RUNNING
- Zeigt Public IP sofort an
- Generiert fertigen SSH-Befehl zum Kopieren

**Vorher (v1.1):**
```
✅ Instanz erstellt!
Nächste Schritte: Gehe zur OCI Console und hole IP...
```

**Jetzt (v1.2):**
```
✅ Instanz erstellt!
⏳ Warte auf RUNNING Status...
⏳ Instanz-Status: PROVISIONING (30s)
⏳ Instanz-Status: STARTING (60s)
✅ Instanz läuft jetzt!

🌐 SSH VERBINDUNGS-INFO
Public IP: 123.45.67.89
SSH-Befehl: ssh ubuntu@123.45.67.89

📝 SSH-Config generiert: ssh-config-oci.txt
```

### **Reserved Public IP (Optional)**
Behalte dieselbe IP auch nach Instanz Stop/Start!

**Vorteile:**
- ✅ IP bleibt für immer gleich
- ✅ Perfekt für SSH Config (`~/.ssh/config`)
- ✅ Leicht zu merken
- ✅ Kostenlos im Oracle Free Tier

**Du wirst beim Ausführen des Skripts gefragt:**
```
Möchtest du eine RESERVIERTE Public IP erstellen? (j/n):
```

### **SSH Config Generator**
Erstellt automatisch `ssh-config-oci.txt`:
```ssh
Host oci
    HostName 123.45.67.89
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking accept-new
```

Einfach nach `~/.ssh/config` kopieren und nutzen: `ssh oci`

### **E-Mail-Benachrichtigungen (Optional)**

Werde benachrichtigt wenn deine Instanz bereit ist!

**Perfekt für:**
- 🛌 Skript über Nacht laufen lassen
- 📱 Handy-Benachrichtigung erhalten (Gmail App)
- 💼 Ausführung auf Remote-Maschine

**Setup (2 Minuten):**

1. **Gmail App-Passwort erstellen:**
   ```
   Google-Konto → Sicherheit → Bestätigung in zwei Schritten (aktivieren)
   → App-Passwörter → Generieren
   → 16-stelliges Passwort kopieren
   ```

2. **`oci-instance-sniper.py` bearbeiten:**
   ```python
   EMAIL_NOTIFICATIONS_ENABLED = True
   EMAIL_FROM = "deine@gmail.com"
   EMAIL_TO = "deine@gmail.com"
   EMAIL_PASSWORD = "dein-16-stelliges-app-passwort"
   ```

3. **Fertig!** E-Mail wird automatisch gesendet wenn Instanz bereit ist.

**E-Mail enthält:**
- ✅ Instanz-Details (Name, Shape, Region, AD)
- ✅ Public IP Adresse
- ✅ Fertigen SSH-Befehl zum Kopieren
- ✅ Nächste Schritte Guide

**Keine E-Mails gewünscht?** Lass einfach `EMAIL_NOTIFICATIONS_ENABLED = False` (Standard)

**Alternative E-Mail-Anbieter:**
- **Outlook:** `smtp.office365.com:587`
- **GMX:** `mail.gmx.net:587`
- **Web.de:** `smtp.web.de:587`

### **Zweisprachiger Support**
Wechsle zwischen Deutsch und Englisch:
```python
LANGUAGE = "DE"  # oder "EN" für Englisch
```

Alle Meldungen, Logs und Prompts in deiner Sprache!

### **Kontrollmenü (v1.3 - NEU!)**

Das interaktive Kontrollmenü macht die Verwaltung des Sniper-Skripts einfach!

**Verwendung:**
```powershell
.\control-menu.ps1
```

**Features:**
1. **Vordergrund-Modus** - Im Terminal ausführen, alle Ausgaben live sehen
2. **Hintergrund-Job-Modus** - Läuft versteckt im Hintergrund bis PC-Neustart
3. **Aufgabenplanungs-Modus** - Überlebt Neustarts, startet automatisch
4. **Status-Prüfung** - Siehst sofort was läuft
5. **Live-Logs** - Logs in Echtzeit ansehen (Strg+C zum Beenden)
6. **Skript stoppen** - Stoppt alle laufenden Instanzen sicher

**Spracheinstellung:**
Bearbeite `control-menu.ps1` um die Sprache zu ändern:
```powershell
$LANGUAGE = "DE"  # oder "EN" für Englisch
```

**Mehrere Instanzen:**
Ja! Du kannst mehrere Instanzen gleichzeitig ausführen:
- Mehrere Hintergrund-Jobs auf demselben PC ✅
- Mehrere PCs die das Skript ausführen ✅
- Unterschiedliche Regionen/Konfigurationen ✅


## 📊 Konfiguration (Optional)

Bearbeite `oci-instance-sniper.py` wenn du folgendes ändern möchtest:

```python
# Instanz-Konfiguration
OCPUS = 2              # Anzahl OCPUs (max 4 für Free Tier)
MEMORY_IN_GBS = 12     # RAM in GB (max 24 für Free Tier)

# Retry-Konfiguration
RETRY_DELAY_SECONDS = 60    # Wartezeit zwischen Versuchen
MAX_ATTEMPTS = 1440         # 24 Stunden

# Sprache
LANGUAGE = "DE"  # "DE" oder "EN"

# E-Mail-Benachrichtigungen (Optional)
EMAIL_NOTIFICATIONS_ENABLED = False  # Auf True setzen zum Aktivieren
EMAIL_FROM = "deine@gmail.com"
EMAIL_TO = "deine@gmail.com"
EMAIL_PASSWORD = "dein-app-passwort"
```

## 💡 Tipps für Erfolg

### **Timing ist wichtig**
- 🌙 **Beste Zeiten**: 2-6 Uhr UTC (Oracle Wartungsfenster)
- 📅 **Wochenenden**: Höhere Erfolgsrate Samstag/Sonntag
- 🌍 **Beste Regionen**: eu-frankfurt-1, us-ashburn-1

### **Sei geduldig**
- ⏱️ ARM-Instanzen sind sehr gefragt
- 📊 **Durchschnittliche Wartezeit**: 2-8 Stunden (kann variieren)
- 🎲 **Maximum berichtet**: Bis zu 3-5 Tage

### **Mehrere Versuche**
- 💻 Auf mehreren Rechnern laufen lassen für bessere Chancen
- 📱 Skript über Nacht mit E-Mail-Benachrichtigungen laufen lassen

### **Logs überwachen**
```powershell
# Live-Ausgabe der Logs
Get-Content -Path oci-sniper.log -Wait -Tail 20
```

## 🎉 Bei Erfolg

```
🎉 INSTANZ ERFOLGREICH ERSTELLT!
Instanz-Details:
  - Name: nextcloud-backup-instance
  - OCID: ocid1.instance...
  - Availability Domain: AD-2
  - Shape: VM.Standard.A1.Flex
  - Status: RUNNING

🌐 SSH VERBINDUNGS-INFO
Public IP: 123.45.67.89
Private IP: 10.0.0.42

SSH-Befehl:
  ssh ubuntu@123.45.67.89

Erste Verbindung (akzeptiert automatisch Fingerprint):
  ssh -o StrictHostKeyChecking=accept-new ubuntu@123.45.67.89

📝 SSH-Config generiert: ssh-config-oci.txt
📧 E-Mail-Benachrichtigung gesendet an: deine@gmail.com

Nächste Schritte:
1. Per SSH in Instanz einloggen mit obigem Befehl
2. System aktualisieren: sudo apt update && sudo apt upgrade -y
3. Docker installieren: curl -fsSL https://get.docker.com | sh
4. Nextcloud deployen!
```

## 🔧 Fehlerbehebung

### **Konfigurationsfehler beim Start?**
```powershell
# Setup-Skript ausführen um OCIDs automatisch zu konfigurieren
.\setup.ps1
```

### **OCI CLI nach Setup nicht gefunden?**
```powershell
# PowerShell neu starten und erneut versuchen
```

### **Kein VCN während Setup gefunden?**
```
VCN in OCI Console erstellen:
Networking → Virtual Cloud Networks → Create VCN
Nutze "VCN Wizard" für schnellstes Setup
```

### **Skript findet immer keine Kapazität?**
```
Das ist normal! ARM-Instanzen sind sehr beliebt.
- Lass es weiterlaufen - es wird irgendwann klappen
- Aktiviere E-Mail-Benachrichtigungen für Übernacht-Läufe
- Probiere verschiedene Zeiten (siehe "Tipps für Erfolg" oben)
```

### **E-Mail funktioniert nicht?**
```
Häufige Probleme:
- Gmail: Stelle sicher, dass du App-Passwort nutzt, nicht normales Passwort
- 2FA: Muss im Google-Konto aktiviert sein für App-Passwörter
- Firewall: Prüfe ob Port 587 blockiert ist
- Teste E-Mail manuell um SMTP-Einstellungen zu verifizieren
```

### **Reserved IP nicht angehängt?**
```
Die Instanz nutzt ephemere IP während der Erstellung.
Reserved IP wird beim nächsten Neustart/Neuerstellung genutzt.
Oder manuell anhängen via OCI Console:
Networking → Public IPs → Attach to Instance
```

## 📄 Lizenz

MIT License - Frei nutzbar!

## 👤 Autor

**Dave Vaupel**
- GitHub: [@MCCMDave](https://github.com/MCCMDave)
- Aufbau von Expertise in Cloud Infrastructure & Customer Success Engineering

## 🙏 Danksagungen

- Oracle Cloud Infrastructure für Free Tier ARM-Instanzen
- Community-Feedback für Feature-Anfragen

---

**Entwickelt um den "Out of host capacity" Fehler zu besiegen! ☁️**

*Gib dem Repo einen Stern ⭐ wenn es dir geholfen hat eine ARM-Instanz zu bekommen!*
