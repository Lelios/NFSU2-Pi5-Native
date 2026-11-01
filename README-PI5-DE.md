# Need for Speed Underground 2 – Raspberry Pi 5 Native

Nativer ARM64-Port von Need for Speed Underground 2
für Raspberry Pi 5 mit Ubuntu Desktop ARM64.

## Getestete Hardware

- Raspberry Pi 5 mit 8 GB RAM
- Ubuntu Desktop ARM64
- Hardwarebeschleunigte OpenGL-ES-Grafik
- Native ARM64-Ausführung ohne Wine
- Controller-Unterstützung

Die Portierung wurde auf einem Raspberry Pi 5
erfolgreich kompiliert, installiert und gespielt.

## Funktionen

- Native ARM64-Version
- Flüssiges Gameplay
- Fahrzeuge und Fußgänger
- Straßenreflexionen
- Musik und Soundeffekte
- Optionale deutsche Sprachausgabe
- Automatischer Installer
- Separater FAST-Installer

## Voraussetzungen

Du benötigst deine eigenen, rechtmäßig erworbenen
PC-Spieldateien von Need for Speed Underground 2.

Aktuell wird die getestete SPEED2.EXE-Version
mit folgendem SHA256-Wert unterstützt:

04b83e2d13c91c6ec294b578a08240ebcfff6fa9513df584edaa968e4ab9990c

Der Spielordner muss unter anderem enthalten:

- SPEED2.EXE
- CARS/
- TRACKS/
- GLOBAL/

Weitere Spieldaten wie SOUND/ und MOVIES/
werden für die vollständige Spielerfahrung benötigt.

## Installation – vollständiger Installer

Repository herunterladen und im Terminal
in das Projektverzeichnis wechseln.

Anschließend ausführen:

    bash ./install-pi5-auto.sh

Der Installer:

1. Prüft die benötigten Ubuntu-Pakete.
2. Richtet die Entwicklungswerkzeuge ein.
3. Überprüft die eigene SPEED2.EXE.
4. Analysiert und übersetzt den Spielcode.
5. Erstellt das ARM64-Programm.
6. Installiert die eigenen Spieldateien.
7. Erstellt eine Desktop-Verknüpfung.

Die erstmalige Kompilierung kann längere Zeit
dauern.

## FAST-Installer

Zusätzlich existiert:

    install-pi5-fast.sh

Dieser verwendet ein bereits fertig kompiliertes
ARM64-Programm.

Ein lokaler Test benötigte nur 18 Sekunden.

Wichtig: Dieser Wert gilt für den getesteten
Raspberry Pi mit bereits vorhandener Programmdatei.
Die erstmalige Erstellung der Programmdatei
ist darin nicht enthalten.

Für die öffentliche Bereitstellung einer fertigen,
aus dem Originalspiel übersetzten Programmdatei
müssen die entsprechenden Rechte geklärt sein.

## Deutsches Sprachpaket

Bei der Installation kann optional ein vorhandenes
deutsches Sprachpaket angegeben werden.

Ohne Sprachpaket wird Englisch verwendet.

## Spiel starten

Nach erfolgreicher vollständiger Installation:

    bash "$HOME/Spiele/NFSU2-Pi5-Native/START-NFSU2.sh"

## Hinweise

Dieses Projekt ist ein inoffizieller Fan-Port.

Need for Speed und alle dazugehörigen Marken
und Spielinhalte gehören ihren jeweiligen
Rechteinhabern.

Es werden keine originalen Spieldateien,
keine SPEED2.EXE und keine aus dem Spiel
erzeugten Programmdateien im Repository
bereitgestellt.

Die jeweiligen Urheberrechts- und Lizenzhinweise
der verwendeten Open-Source-Projekte
sind zu beachten.
