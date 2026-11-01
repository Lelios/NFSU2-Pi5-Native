#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/Spiele/NFSU2-Pi5-Native"

EXPECTED="04b83e2d13c91c6ec294b578a08240ebcfff6fa9513df584edaa968e4ab9990c"
BINNAME="nfsu2-pi5-native-v26-real-expp-fix.aarch64"

fail() {
    echo "FEHLER: $*" >&2
    exit 1
}

echo "========================================"
echo " NFS UNDERGROUND 2 - PI 5 NATIVE"
echo " INSTALLER V26 GOLD"
echo "========================================"

[[ "$(uname -s)" == "Linux" ]] ||
    fail "Linux erforderlich."

[[ "$(uname -m)" == "aarch64" ]] ||
    fail "ARM64 erforderlich."

[[ ! -e "$TARGET" ]] ||
    fail "Zielordner existiert bereits: $TARGET"

[[ -f "$ROOT/start-pi5.sh" ]] ||
    fail "Startskript fehlt."

echo
echo "1. PC-Spielordner auswählen"

read -r -p "Pfad zum eigenen Spielordner: " GAME

[[ -d "$GAME" ]] ||
    fail "Spielordner nicht gefunden."

for DIR in CARS TRACKS GLOBAL; do
    [[ -d "$GAME/$DIR" ]] ||
        fail "Spielordner unvollständig: $DIR fehlt."
done

EXE="$(find "$GAME" -maxdepth 1 \
    -type f -iname 'speed2.exe' -print -quit)"

[[ -n "$EXE" ]] ||
    fail "SPEED2.EXE fehlt."

ACTUAL="$(sha256sum "$EXE" | cut -d' ' -f1)"

[[ "$ACTUAL" == "$EXPECTED" ]] ||
    fail "Diese SPEED2.EXE entspricht nicht der getesteten Version."

echo "OK: Getestete PC-Version 1.0 erkannt."

echo
echo "2. Native ARM64-Datei auswählen"

read -r -p "Pfad zur selbst erstellten V26-Datei: " BINARY

[[ -f "$BINARY" ]] ||
    fail "ARM64-Datei nicht gefunden."

python3 - "$BINARY" <<'CHECK'
import struct
import sys

with open(sys.argv[1], "rb") as f:
    b = f.read(20)

if (
    len(b) < 20
    or b[:4] != b"\x7fELF"
    or b[4] != 2
    or b[5] != 1
    or struct.unpack_from("<H", b, 18)[0] != 183
):
    sys.exit("FEHLER: Keine ARM64-ELF-Datei.")
CHECK

echo
echo "3. Deutsches Sprachpaket (optional)"

read -r -p "Pfad zum Sprachpaket (Enter = keines): " PACK

if [[ -n "$PACK" ]]; then
    if [[ -d "$PACK/NeedForSpeedUnderground2Deutsch" ]]; then
        PACK="$PACK/NeedForSpeedUnderground2Deutsch"
    fi

    [[ -d "$PACK" ]] ||
        fail "Sprachpaket nicht gefunden."

    [[ -d "$PACK/MOVIES" || -f "$PACK/SDATA/sdat.viv" ]] ||
        fail "Ungültiges Sprachpaket."
fi

if find "$GAME" -type l -print -quit | grep -q .; then
    fail "Spielordner enthält symbolische Verknüpfungen."
fi

if [[ -n "$PACK" ]]; then
    if find "$PACK" -type l -print -quit | grep -q .; then
        fail "Sprachpaket enthält symbolische Verknüpfungen."
    fi
fi

echo
echo "4. Dateien installieren ..."

mkdir -p "$HOME/Spiele"

STAGE="$(mktemp -d "$HOME/Spiele/.nfsu2-install.XXXXXXXX")"

trap 'if [[ -n "${STAGE:-}" && -d "$STAGE" ]]; then rm -rf -- "$STAGE"; fi' EXIT

mkdir -p "$STAGE/Spiel/gamedata"

cp -a "$GAME/." "$STAGE/Spiel/gamedata/"

if [[ -n "$PACK" ]]; then
    for DIR in MOVIES SDATA; do
        if [[ -d "$PACK/$DIR" ]]; then
            mkdir -p "$STAGE/Spiel/gamedata/$DIR"
            cp -a "$PACK/$DIR/." "$STAGE/Spiel/gamedata/$DIR/"
        fi
    done
fi

cp "$BINARY" "$STAGE/Spiel/$BINNAME"
chmod +x "$STAGE/Spiel/$BINNAME"

cp "$ROOT/start-pi5.sh" "$STAGE/START-NFSU2.sh"
chmod +x "$STAGE/START-NFSU2.sh"

if [[ ! -f "$STAGE/Spiel/gamedata/MOVIES/Scene01.vp6" ]]; then
    sed -i 's/--lang=German/--lang=English/g' \
        "$STAGE/START-NFSU2.sh"
fi

ICON="applications-games"

if [[ -f "$ROOT/assets/nfsu2-icon.png" ]]; then
    mkdir -p "$STAGE/icons"

    cp "$ROOT/assets/nfsu2-icon.png" \
       "$STAGE/icons/nfsu2-icon.png"

    ICON="$TARGET/icons/nfsu2-icon.png"
fi

mv -T "$STAGE" "$TARGET"
STAGE=""

echo
echo "5. Desktop-Verknüpfung erstellen ..."

APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$APPS"

DESKTOP="$APPS/nfsu2-pi5-native.desktop"

printf '[Desktop Entry]\nType=Application\nName=Need for Speed Underground 2 (Pi 5 Native)\nExec="%s/START-NFSU2.sh"\nPath=%s/Spiel\nIcon=%s\nTerminal=false\nCategories=Game;\n' \
    "$TARGET" "$TARGET" "$ICON" > "$DESKTOP"

chmod +x "$DESKTOP"

DESK="$(xdg-user-dir DESKTOP 2>/dev/null || true)"

if [[ -z "$DESK" || "$DESK" == "$HOME" ]]; then
    for P in "$HOME/Schreibtisch" "$HOME/Desktop"; do
        if [[ -d "$P" ]]; then
            DESK="$P"
            break
        fi
    done
fi

if [[ -d "$DESK" && "$DESK" != "$HOME" ]]; then
    cp "$DESKTOP" "$DESK/Need for Speed Underground 2.desktop"

    chmod +x \
        "$DESK/Need for Speed Underground 2.desktop"

    gio set \
        "$DESK/Need for Speed Underground 2.desktop" \
        metadata::trusted true 2>/dev/null || true
fi

echo
echo "========================================"
echo " INSTALLATION ERFOLGREICH!"
echo "========================================"

echo "Spiel installiert: $TARGET"
echo "Desktop-Verknüpfung erstellt."
echo "V26-Startskript eingerichtet."
