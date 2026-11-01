#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE="$HOME/.cache/nfsu2-r36s"

PC="${NFSU2_PCRECOMP_DIR:-$HOME/.cache/nfsu2-pi5-native/deps/pcrecomp}"
DXVK="${NFSU2_DXVK_DIR:-$HOME/.cache/nfsu2-pi5-native/deps/dxvk-source}"
SEEDS="${NFSU2_SEEDS_FILE:-$ROOT/config/seeds-pi5-v10.json}"

WORK="${NFSU2_AUTOBUILD_DIR:-$HOME/.cache/nfsu2-pi5-native/auto-build-459}"
GEN="$WORK/gen"
BUILD="$WORK/build"

EXPECTED="04b83e2d13c91c6ec294b578a08240ebcfff6fa9513df584edaa968e4ab9990c"

fail() {
    echo "FEHLER: $*" >&2
    exit 1
}

run_logged() {
    local name="$1"
    shift

    echo
    echo ">>> $name"

    if "$@" > "$WORK/$name.log" 2>&1; then
        echo "OK: $name"
    else
        echo "FEHLER: $name"
        echo "Letzte Meldungen:"
        tail -30 "$WORK/$name.log"
        exit 1
    fi
}

echo "========================================"
echo " NFSU2 - RASPBERRY PI 5 NATIVE"
echo " AUTOMATISCHE ARM64-KOMPILIERUNG"
echo "========================================"

[[ "$(uname -m)" == "aarch64" ]] ||
    fail "ARM64-System erforderlich."

for PROGRAM in python3 cmake sha256sum; do
    command -v "$PROGRAM" >/dev/null ||
        fail "Werkzeug fehlt: $PROGRAM"
done

[[ -d "$PC/runtime/recomp32" ]] ||
    fail "pcrecomp-Toolchain fehlt."

[[ -d "$PC/tools" ]] ||
    fail "pcrecomp-Python-Werkzeuge fehlen."

[[ -d "$DXVK/include/native" ]] ||
    fail "DXVK-Header fehlen."

[[ -s "$SEEDS" ]] ||
    fail "Funktions-Seed-Liste fehlt."

[[ -f "$ROOT/scripts/run_lift.py" ]] ||
    fail "run_lift.py fehlt."

[[ -f "$ROOT/scripts/normalize_exe.py" ]] ||
    fail "normalize_exe.py fehlt."

[[ -f "$ROOT/ports/r36s/lw/analyze.py" ]] ||
    fail "LW-Analyse fehlt."

[[ -f "$ROOT/ports/r36s/lw/annotate.py" ]] ||
    fail "LW-Annotation fehlt."

[[ -f "$ROOT/ports/r36s/pi5-wrap-functions.txt" ]] ||
    fail "Funktionsliste fehlt."

python3 -m json.tool "$SEEDS" >/dev/null ||
    fail "Seed-Liste enthält ungültiges JSON."

export PYTHONPATH="$ROOT/scripts:$PC:${PYTHONPATH:-}"

while IFS= read -r DIR; do
    PYTHONPATH="$DIR:$PYTHONPATH"
done < <(
    find "$PC/tools" -type f -name '*.py' \
        -printf '%h\n' | sort -u
)

export PYTHONPATH

python3 -c 'import pe_analyze, disasm32' ||
    fail "Python-Module konnten nicht geladen werden."

echo
echo "OK: Entwicklungswerkzeuge vorhanden."
echo "OK: Funktionskatalog kann erstellt werden."
echo "OK: LW-Optimierungswerkzeuge vorhanden."

if [[ "${1:-}" == "--check" ]]; then
    echo
    echo "========================================"
    echo " SCHNELLPRUEFUNG ERFOLGREICH"
    echo "========================================"
    echo "Kein Build gestartet."
    exit 0
fi

[[ $# -eq 1 ]] ||
    fail "Aufruf: $0 /Pfad/zum/Spielordner"

GAME="$1"

[[ -d "$GAME" ]] ||
    fail "Spielordner nicht gefunden."

EXE="$(find "$GAME" -maxdepth 1 \
    -type f -iname 'speed2.exe' -print -quit)"

[[ -n "$EXE" ]] ||
    fail "SPEED2.EXE fehlt."

ACTUAL="$(sha256sum "$EXE" | cut -d' ' -f1)"

[[ "$ACTUAL" == "$EXPECTED" ]] ||
    fail "Nicht unterstützte SPEED2.EXE-Version."

[[ ! -e "$WORK" ]] ||
    fail "Build-Verzeichnis existiert bereits: $WORK"

mkdir -p "$GEN"

echo
echo "Getestete SPEED2.EXE erkannt."
echo "Neues Build-Verzeichnis: $WORK"

run_logged "01-normalisieren" \
    python3 "$ROOT/scripts/normalize_exe.py" \
    "$EXE" "$WORK/SPEED2.analysis.exe"

run_logged "02-katalog" \
    python3 "$ROOT/scripts/run_lift.py" \
    catalog "$WORK/SPEED2.analysis.exe" \
    "$SEEDS" "$WORK/catalog.json"

run_logged "03-uebersetzen" \
    python3 "$ROOT/scripts/run_lift.py" \
    lift "$WORK/SPEED2.analysis.exe" \
    "$WORK/catalog.json" "$GEN"

COUNT="$(find "$GEN" -maxdepth 1 \
    -name 'recomp_*.c' -type f | wc -l)"

[[ "$COUNT" -eq 73 ]] ||
    fail "Erwartet: 73 C-Dateien. Gefunden: $COUNT"

echo
echo "OK: 73 C-Dateien erzeugt."

run_logged "04-lw-analyse" \
    python3 "$ROOT/ports/r36s/lw/analyze.py" \
    "$GEN" "$WORK/lw-info.json"

run_logged "05-lw-anwenden" \
    python3 "$ROOT/ports/r36s/lw/annotate.py" \
    apply "$GEN" "$WORK/lw-info.json"

run_logged "06-lw-header" \
    python3 "$ROOT/ports/r36s/lw/annotate.py" \
    header "$GEN" "$WORK/lw-info.json" \
    "$GEN/nfs_lw.h"

[[ -s "$GEN/nfs_lw.h" ]] ||
    fail "LW-Header fehlt."

echo
echo "OK: LW-Optimierungen erstellt."

run_logged "07-cmake" \
    cmake -S "$ROOT/ports/r36s" -B "$BUILD" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPCRECOMP="$PC" \
    -DGEN_DIR="$GEN" \
    -DDXVK_SOURCE="$DXVK"

run_logged "08-arm64-build" \
    cmake --build "$BUILD" \
    --parallel "${NFSU2_BUILD_JOBS:-2}"

BINARY="$BUILD/nfsu2.aarch64"

[[ -s "$BINARY" ]] ||
    fail "ARM64-Programm wurde nicht erstellt."

echo
echo "========================================"
echo " ARM64-KOMPILIERUNG ERFOLGREICH!"
echo "========================================"

ls -lh "$BINARY"

echo
echo "Fertige native Programmdatei:"
echo "$BINARY"

echo
echo "Bestehende Spielinstallation unverändert."
