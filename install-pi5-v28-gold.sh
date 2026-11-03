#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/Spiele/NFSU2-Pi5-Native-V28-GOLD"

EXPECTED="04b83e2d13c91c6ec294b578a08240ebcfff6fa9513df584edaa968e4ab9990c"
BINNAME="nfsu2-pi5-native-v28-gold.aarch64"

fail() {
    echo "FEHLER: $*" >&2
    exit 1
}

echo "========================================"
echo " NFS UNDERGROUND 2 - PI 5 NATIVE"
echo " INSTALLER V28 GOLD"
echo "========================================"

[[ "$(uname -s)" == "Linux" ]] ||
    fail "Linux erforderlich."

[[ "$(uname -m)" == "aarch64" ]] ||
    fail "ARM64 erforderlich."

[[ ! -e "$TARGET" && ! -L "$TARGET" ]] ||
    fail "Zielordner existiert bereits: $TARGET"

# PI5_INSTALL_PROTECTION_476
# Verknuepfungen bereits vor dem langen Build pruefen.
APP_V476="${XDG_DATA_HOME:-$HOME/.local/share}/applications/nfsu2-pi5-native-v28-gold.desktop"

if [[ -e "$APP_V476" || -L "$APP_V476" ]]; then
    fail "Programmverknuepfung existiert bereits: $APP_V476"
fi

DESK_V476="$(xdg-user-dir DESKTOP 2>/dev/null || true)"

if [[ -z "$DESK_V476" || "$DESK_V476" == "$HOME" ]]; then
    DESK_V476=""
    for P_V476 in "$HOME/Schreibtisch" "$HOME/Desktop"; do
        if [[ -d "$P_V476" ]]; then
            DESK_V476="$P_V476"
            break
        fi
    done
fi

if [[ -n "$DESK_V476" && -d "$DESK_V476" ]]; then
    LINK_V476="$DESK_V476/Need for Speed Underground 2 V28 GOLD.desktop"

    if [[ -e "$LINK_V476" || -L "$LINK_V476" ]]; then
        fail "Desktop-Verknuepfung existiert bereits: $LINK_V476"
    fi
fi

[[ -f "$ROOT/start-pi5-v28-gold.sh" ]] ||
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
echo "2. Native ARM64-Version automatisch erstellen"

# PI5_SYSTEM_SETUP_STEP472
echo
echo "NFSU2: Ubuntu-Systempakete pruefen ..."

"$ROOT/setup-pi5-system.sh" --install

# PI5_AUTO_DEPS_STEP471
echo
echo "NFSU2: Entwicklungswerkzeuge vorbereiten ..."

DEPS_BASE="${NFSU2_DEPS_DIR:-$HOME/.cache/nfsu2-pi5-native/deps}"

NFSU2_DEPS_DIR="$DEPS_BASE" "$ROOT/setup-pi5-deps.sh"

echo
echo "NFSU2: Native ARM64-Version erstellen ..."

NFSU2_PCRECOMP_DIR="$DEPS_BASE/pcrecomp" \
NFSU2_DXVK_DIR="$DEPS_BASE/dxvk-source" \
NFSU2_AUTOBUILD_DIR="${NFSU2_AUTOBUILD_DIR:-$HOME/.cache/nfsu2-pi5-native/auto-build-v28-gold}" \
"$ROOT/build-pi5-from-exe.sh" "$GAME"

BUILD_DIR="${NFSU2_AUTOBUILD_DIR:-$HOME/.cache/nfsu2-pi5-native/auto-build-v28-gold}"

BINARY="$BUILD_DIR/build/nfsu2.aarch64"

[[ -s "$BINARY" ]] ||
    fail "Automatisch erstellte ARM64-Datei fehlt."

echo
echo "OK: ARM64-Version erfolgreich erstellt."

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

cp "$ROOT/start-pi5-v28-gold.sh" "$STAGE/START-NFSU2.sh"
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

mv -T --no-clobber "$STAGE" "$TARGET"

[[ ! -e "$STAGE" ]] ||
    fail "Zielordner wurde zwischenzeitlich angelegt."

STAGE=""

echo
echo "5. Desktop-Verknüpfung erstellen ..."

APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$APPS"

DESKTOP="$APPS/nfsu2-pi5-native-v28-gold.desktop"

printf '[Desktop Entry]\nType=Application\nName=Need for Speed Underground 2 V28 GOLD\nExec="%s/START-NFSU2.sh"\nPath=%s/Spiel\nIcon=%s\nTerminal=false\nCategories=Game;\n' \
    "$TARGET" "$TARGET" "$ICON" | (
        set -C
        cat > "$DESKTOP"
    )

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
    (
        set -C
        cat "$DESKTOP" > "$DESK/Need for Speed Underground 2 V28 GOLD.desktop"
    )

    chmod +x \
        "$DESK/Need for Speed Underground 2 V28 GOLD.desktop"

    gio set \
        "$DESK/Need for Speed Underground 2 V28 GOLD.desktop" \
        metadata::trusted true 2>/dev/null || true
fi

echo
echo "========================================"
echo " INSTALLATION ERFOLGREICH!"
echo "========================================"

echo "Spiel installiert: $TARGET"
echo "Desktop-Verknüpfung erstellt."
echo "V28-GOLD-Startskript eingerichtet."
