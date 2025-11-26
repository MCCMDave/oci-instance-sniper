# Encoding-Regeln für OCI Instance Sniper

## PowerShell-Dateien (.ps1)

**KEINE deutschen Umlaute (ä, ö, ü) oder ß verwenden!**

PowerShell hat Encoding-Probleme mit UTF-8 Umlauten. Diese führen zu:
- Fehlern beim Öffnen der Dateien
- Unlesbaren Zeichen in der Ausgabe
- Problemen bei der Ausführung

### Alternativen verwenden:

| ❌ Nicht verwenden | ✅ Stattdessen |
|-------------------|----------------|
| prüfen | kontrollieren |
| ausführen | starten |
| drücken | - |
| schließen | beenden |
| ändern | anpassen |
| Schlüssel | Key |
| öffentlich | public |
| Übersicht | im Detail |
| nächste | weitere |
| überwachen | kontrollieren |
| läuft | aktiv / lauft |
| ungültig | falsch |
| wählen | wahlen |

## README/Markdown-Dateien (.md)

**Umlaute ERLAUBT und ERWÜNSCHT!**

Markdown-Dateien verwenden UTF-8 und unterstützen Umlaute problemlos.

### Verwende immer korrekte deutsche Rechtschreibung:

✅ **Richtig:**
- prüfen, ändern, schließen
- Übersicht, öffentlich
- größer, süß

❌ **Falsch:**
- pruefen, aendern, schliessen
- Uebersicht, oeffentlich
- groesser, suess

## Zusammenfassung

```
.ps1 Dateien  → KEINE Umlaute (ä→a, ö→o, ü→u, ß→ss oder Alternative)
.md Dateien   → UMLAUTE VERWENDEN (korrekte deutsche Rechtschreibung)
.txt Dateien  → Umlaute OK
.json Dateien → Umlaute OK (UTF-8)
Python .py    → Umlaute OK (UTF-8)
```

## Beispiel

**setup.ps1:**
```powershell
Write-Host "Kontrolliere Python-Installation..."  # ✅ Kein ü
Write-Host "ENTER zum Fortfahren..."              # ✅ Kein ü
```

**README.de.md:**
```markdown
## Überblick                                      # ✅ Umlaute OK
Diese Anleitung erklärt die Einrichtung.         # ✅ Umlaute OK
```
