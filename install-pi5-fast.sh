#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODE="${1:---install}"

case "$MODE" in
    --install|--check) ;;
    *)
        echo "Aufruf: $0 [--check|--install]"
        exit 2
        ;;
esac

fail() {
    echo "FEHLER: $*" >&2
    exit 1
}

EXPECTED="04b83e2d13c91c6ec294b578a08240ebcfff6fa9513df584edaa968e4ab9990c"

BINNAME="nfsu2-pi5-native-v26-real-expp-fix.aarch64"

BIN="${NFSU2_FAST_BINARY:-$ROOT/release/nfsu2.aarch64}"
GAME="${NFSU2_GAME_DIR:-}"
PACK="${NFSU2_FAST_LANG_DIR:-}"
TARGET="${NFSU2_FAST_TARGET:-$HOME/Spiele/NFSU2-Pi5-Native}"

echo "========================================"
echo " NFSU2 PI 5 NATIVE - FAST INSTALLER"
echo "========================================"

[[ "$(uname -m)" == "aarch64" ]] ||
    fail "Raspberry Pi ARM64 erforderlich."

[[ -f "$BIN" ]] ||
    fail "Fertige ARM64-Datei fehlt: $BIN"

[[ -f "$ROOT/start-pi5.sh" ]] ||
    fail "Startskript fehlt."

grep -Fq "$BINNAME" "$ROOT/start-pi5.sh" ||
    fail "Startskript und Programmname stimmen nicht überein."

if [[ -z "$GAME" ]]; then
    [[ "$MODE" != "--check" ]] ||
        fail "Für --check bitte NFSU2_GAME_DIR angeben."

    read -r -p "Pfad zum PC-Spielordner: " GAME
fi

[[ -d "$GAME" ]] ||
    fail "PC-Spielordner fehlt."

for DIR in CARS TRACKS GLOBAL; do
    [[ -d "$GAME/$DIR" ]] ||
        fail "Spielordner fehlt: $DIR"
done

EXE="$(find "$GAME" -maxdepth 1 \
    -type f -iname 'speed2.exe' -print -quit)"

[[ -n "$EXE" ]] ||
    fail "SPEED2.EXE fehlt."

ACTUAL="$(sha256sum "$EXE" | cut -d' ' -f1)"

[[ "$ACTUAL" == "$EXPECTED" ]] ||
    fail "SPEED2.EXE ist nicht die getestete Version."

[[ "$TARGET" == /* ]] ||
    fail "Installationsziel muss ein absoluter Pfad sein."

[[ ! -e "$TARGET" && ! -L "$TARGET" ]] ||
    fail "Installationsziel existiert bereits: $TARGET"

GAMEREAL="$(realpath -e "$GAME")"
TARGETREAL="$(realpath -m "$TARGET")"

GOLDREAL="$(realpath -m \
    "$HOME/Spiele/Need-for-Speed-Underground-2/Spiel")"

BACKUPREAL="$(realpath -m \
    "$HOME/Spiele/NFSU2-Backups")"

for PROTECTED in "$GAMEREAL" "$GOLDREAL" "$BACKUPREAL"; do
    case "$TARGETREAL/" in
        "$PROTECTED/"*) fail "Ziel liegt im geschützten Verzeichnis." ;;
    esac
    case "$PROTECTED/" in
        "$TARGETREAL/"*) fail "Ziel enthält ein geschütztes Verzeichnis." ;;
    esac
done

if [[ "$MODE" == "--install" && -z "$PACK" ]]; then
    read -r -p \
        "Deutsches Sprachpaket (Enter = keines): " PACK
fi

if [[ -n "$PACK" ]]; then
    if [[ -d "$PACK/NeedForSpeedUnderground2Deutsch" ]]; then
        PACK="$PACK/NeedForSpeedUnderground2Deutsch"
    fi

    [[ -d "$PACK" ]] ||
        fail "Sprachpaket nicht gefunden."
fi

echo
echo "ARM64-Programm:"
ls -lh "$BIN"

echo
echo "SHA256:"
sha256sum "$BIN"

echo
echo "Originale Spieldaten:"
echo "$GAME"

echo
echo "Installationsziel:"
echo "$TARGET"

echo
echo "Modus: Bereits kompilierte ARM64-Version"
echo "Keine erneute Übersetzung notwendig."

if [[ "$MODE" == "--check" ]]; then
    echo
    echo "========================================"
    echo " SCHNELLPRUEFUNG ERFOLGREICH"
    echo "========================================"
    echo "Keine Dateien verändert."
    exit 0
fi

echo
echo "Installation vorbereiten ..."

PARENT="$(dirname "$TARGET")"
mkdir -p "$PARENT"

STAGE="$(mktemp -d "$PARENT/.nfsu2-fast.XXXXXXXX")"

cleanup() {
    if [[ -n "${STAGE:-}" && -d "$STAGE" ]]; then
        rm -rf -- "$STAGE"
    fi
}
trap cleanup EXIT

mkdir -p "$STAGE/Spiel/gamedata"

echo
# PI5_FAST_COPY_STEP480
echo "[1/3] Spieldaten sicher kopieren ..."

if [[ -n "$(find "$GAMEREAL" -type l -print -quit)" ]]; then
    fail "Spielordner enthält symbolische Links. Bitte erst prüfen."
fi

cp -a --reflink=auto     "$GAMEREAL/." "$STAGE/Spiel/gamedata/"

# Bei einem optionalen Sprachpaket nur die betroffenen
# Verzeichnisse kopieren. Originaldateien bleiben unangetastet.
if [[ -n "$PACK" ]]; then
    for DIR in MOVIES SDATA; do
        if [[ -d "$PACK/$DIR" ]]; then
            DEST="$STAGE/Spiel/gamedata/$DIR"

            mkdir -p "$DEST"

            cp -a --reflink=auto \
                "$PACK/$DIR/." "$DEST/"
        fi
    done
fi

echo
echo "[2/3] Fertiges ARM64-Programm installieren ..."

cp "$BIN" "$STAGE/Spiel/$BINNAME"
chmod +x "$STAGE/Spiel/$BINNAME"

cp "$ROOT/start-pi5.sh" "$STAGE/START-NFSU2.sh"
chmod +x "$STAGE/START-NFSU2.sh"

if [[ -z "$PACK" ]]; then
    sed -i \
        's/--lang=German/--lang=English/g' \
        "$STAGE/START-NFSU2.sh"
fi

echo
echo "[3/3] Installation abschließen ..."

mv -T --no-clobber "$STAGE" "$TARGET"

[[ ! -e "$STAGE" ]] ||
    fail "Ziel wurde zwischenzeitlich belegt."

STAGE=""

echo
echo "========================================"
echo " SCHNELLINSTALLATION ERFOLGREICH!"
echo "========================================"

echo
echo "Spiel:"
echo "$TARGET"

echo
echo "Starten mit:"
echo "bash \"$TARGET/START-NFSU2.sh\""

echo
echo "Hinweis:"
echo "Die Spieldaten wurden eigenständig kopiert."
echo "Die Originaldateien bleiben unverändert."

echo
echo "Keine Kompilierung durchgeführt."
