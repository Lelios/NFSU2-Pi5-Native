# Need for Speed Underground 2 – Raspberry Pi 5 Native

Native ARM64 port of Need for Speed Underground 2
for Raspberry Pi 5 running Ubuntu Desktop ARM64.

## Tested hardware

- Raspberry Pi 5 with 8 GB RAM
- Ubuntu Desktop ARM64
- Hardware-accelerated OpenGL ES graphics
- Native ARM64 execution without Wine
- Controller support

The port has been successfully compiled,
installed and played on a Raspberry Pi 5.

## Features

- Native ARM64 execution
- Smooth gameplay
- Cars, traffic and pedestrians
- Road reflections
- Music and sound effects
- Optional German voice pack
- Automatic installer
- Separate FAST installer

## Requirements

You must provide your own lawfully obtained
Need for Speed Underground 2 PC game files.

Currently supported SPEED2.EXE SHA256:

04b83e2d13c91c6ec294b578a08240ebcfff6fa9513df584edaa968e4ab9990c

The game directory must include:

- SPEED2.EXE
- CARS/
- TRACKS/
- GLOBAL/

Additional game data such as SOUND/ and MOVIES/
is needed for the complete game experience.

## Installation – full installer

Download the repository and open a terminal
in its directory.

Run:

    bash ./install-pi5-auto.sh

The installer:

1. Checks Ubuntu dependencies.
2. Prepares the development tools.
3. Validates your SPEED2.EXE.
4. Analyses and translates the game code.
5. Builds the native ARM64 executable.
6. Installs your game data.
7. Creates a desktop shortcut.

The initial compilation may take considerable time.

## FAST installer

An additional installer is available:

    install-pi5-fast.sh

It uses an already compiled ARM64 executable.

A local installation test completed in 18 seconds.

This measurement excludes compilation time
and requires the executable to be available
before installation.

Public distribution of an executable derived
from the original game requires appropriate
distribution rights.

## German language pack

An existing German language pack can optionally
be selected during installation.

English is used when no German pack is provided.

## Starting the game

After a successful full installation:

    bash "$HOME/Spiele/NFSU2-Pi5-Native/START-NFSU2.sh"

## Disclaimer

This is an unofficial fan-made port.

Need for Speed and related game content
and trademarks belong to their respective owners.

This repository does not distribute the original
game files, SPEED2.EXE or generated executables
derived from the copyrighted game.

Third-party open-source licences and
copyright notices must be respected.
