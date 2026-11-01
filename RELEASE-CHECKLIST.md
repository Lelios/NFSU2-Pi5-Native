# NFSU2 Pi 5 Native – Release Checklist

## Technische Tests

- [x] ARM64-Build erfolgreich.
- [x] Vollständiger Installer erfolgreich getestet.
- [x] Neu installierte Version erfolgreich gespielt.
- [x] FAST-Installer lokal getestet.
- [x] FAST-Installation in 18 Sekunden gemessen.
- [x] Bestehende V26 GOLD geschützt.

## Vor der Veröffentlichung prüfen

- [ ] Lizenz und Copyright des Basisprojekts klären.
- [ ] Lizenzhinweise aller modifizierten Komponenten erhalten.
- [ ] Eingebundene Drittanbieter-Lizenzen kontrollieren.
- [ ] Git-Dateien einschließlich Git-Historie prüfen.
- [ ] Keine Original-Spieldateien hochladen.
- [ ] Keine SPEED2.EXE hochladen.
- [ ] Keine aus dem Spiel generierten C-Dateien hochladen.
- [ ] Keine ausführbare Datei mit geschütztem Spielcode hochladen.
- [ ] Keine persönlichen Zugangsdaten hochladen.
- [ ] Keine lokalen Sicherungsdateien hochladen.
- [ ] README und Installationsbefehle final prüfen.
- [ ] Öffentliche Veröffentlichung ausdrücklich bestätigen.

## FAST-Installer

Der FAST-Installer ist technisch erfolgreich getestet.

Er benötigt bereits eine fertige ARM64-Programmdatei.

Eine öffentliche Bereitstellung dieser Datei
ist derzeit NICHT freigegeben.

Vor einem öffentlichen FAST-Release muss eine
rechtlich zulässige Bereitstellung geklärt werden.

## Lizenzhinweise

Basisprojekte:

- codepdbh/nfsu2-recompiled
- manuelpllull/nfsu2-recompiled-r36s
- sp00nznet/pcrecomp
- misyltoad/dxvk-native

Die Lizenz jeder verwendeten Komponente muss
anhand des jeweiligen Quellstands überprüft werden.

Eine fehlende Lizenzdatei darf nicht durch
eine erfundene Copyright-Angabe ersetzt werden.
