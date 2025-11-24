# OCI Instance Sniper 🎯

Erstellt automatisch ARM-Instanzen (VM.Standard.A1.Flex) in Oracle Cloud Infrastructure, sobald Kapazität verfügbar wird.

[English Version](README.md) | **Deutsche Version**

## 🚀 Schnellstart

```powershell
# 1. Setup (einmalig)
.\setup.ps1

# 2. Ausführen
python oci-instance-sniper.py
```

Das war's! Das Skript läuft 24 Stunden und prüft alle 60 Sekunden.

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

- **Smart Retry**: Versucht alle 60 Sekunden für 24 Stunden
- **Multi-AZ**: Testet alle 3 Availability Domains
- **Umfassendes Logging**: Alles wird in `oci-sniper.log` protokolliert
- **Zero Config**: Setup-Skript macht alles automatisch

## 📊 Konfiguration (Optional)

Bearbeite `oci-instance-sniper.py` wenn du folgendes ändern möchtest:

```python
OCPUS = 2              # Anzahl OCPUs (max 4 für Free Tier)
MEMORY_IN_GBS = 12     # RAM in GB (max 24 für Free Tier)
RETRY_DELAY_SECONDS = 60
MAX_ATTEMPTS = 1440    # 24 Stunden
```

## 💡 Tipps für Erfolg

- **Sei geduldig**: ARM-Instanzen sind sehr gefragt. Kann Stunden/Tage dauern.
- **Beste Zeiten**: Über Nacht und an Wochenenden laufen lassen
- **Mehrere Versuche**: Auf mehreren Rechnern laufen lassen für bessere Chancen
- **Logs überwachen**: `Get-Content -Path oci-sniper.log -Wait -Tail 20`

## 🎉 Bei Erfolg

```
🎉 INSTANZ ERFOLGREICH ERSTELLT!
Instance Name: nextcloud-backup-instance
Instance OCID: ocid1.instance...
Availability Domain: AD-2
Shape: VM.Standard.A1.Flex
State: PROVISIONING

Nächste Schritte:
1. Warte bis Instanz 'RUNNING' Status erreicht
2. Hole Public IP aus OCI Console
3. SSH in Instanz: ssh ubuntu@<PUBLIC_IP>
```

## 🔧 Fehlerbehebung

**Konfigurationsfehler beim Start?**
```powershell
# Setup-Skript ausführen um OCIDs automatisch zu konfigurieren
.\setup.ps1
```

**OCI CLI nach Setup nicht gefunden?**
```powershell
# PowerShell neu starten und erneut versuchen
```

**Kein VCN gefunden?**
```
VCN in OCI Console erstellen:
Networking → Virtual Cloud Networks → Create VCN
```

**Skript findet immer keine Kapazität?**
```
Das ist normal! ARM-Instanzen sind sehr beliebt.
Lass es weiterlaufen - es wird irgendwann klappen.
```

**Unicode/Emoji-Fehler im Log?**
```
In v1.1 behoben! Skript nutzt jetzt UTF-8 Encoding für Windows Console.
Stelle sicher, dass du die neueste Version nutzt.
```

## 📄 Lizenz

MIT License - Frei nutzbar!

## 👤 Autor

**Dave Vaupel**
- GitHub: [@davidvaupel](https://github.com/davidvaupel)
- Aufbau von Expertise in Cloud Infrastructure & Customer Success Engineering

---

**Entwickelt um den "Out of host capacity" Fehler zu besiegen! ☁️**
