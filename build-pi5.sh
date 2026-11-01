#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE="${NFSU2_CACHE_DIR:-$HOME/.cache/nfsu2-r36s}"
GEN="${NFSU2_GEN_DIR:-$CACHE/nfsu2-v10/src/recomp/gen}"
PCRECOMP="${NFSU2_PCRECOMP_DIR:-$CACHE/pcrecomp}"
DXVK="${NFSU2_DXVK_DIR:-$ROOT/build/dxvk-source}"
BUILD="${NFSU2_BUILD_DIR:-$CACHE/host-pi5-fork-v26-test}"

fail() {
    echo "FEHLER: $*" >&2
    exit 1
}

echo "========================================"
echo " NFSU2 PI 5 - ARM64 BUILD"
echo "========================================"

[[ "$(uname -m)" == "aarch64" ]] ||
    fail "Ein ARM64-System wird benötigt."

command -v cmake >/dev/null ||
    fail "CMake fehlt."

command -v python3 >/dev/null ||
    fail "Python 3 fehlt."

[[ -d "$PCRECOMP/runtime/recomp32" ]] ||
    fail "Die vorbereitete pcrecomp-Toolchain fehlt."

[[ -d "$GEN" ]] ||
    fail "Generierter Spielcode fehlt. Die automatische Übersetzung wird noch ergänzt."

[[ -f "$GEN/recomp_0039.c" ]] ||
    fail "Generierter Spielcode ist unvollständig."

[[ -d "$DXVK/include/native" ]] ||
    fail "Vorbereitete DXVK-Header fehlen."

[[ -f "$ROOT/ports/r36s/pi5-wrap-functions.txt" ]] ||
    fail "Die Funktionsliste fehlt."

echo
echo "Build-Voraussetzungen vorhanden."

if [[ "${1:-}" == "--check" ]]; then
    echo "Prüfung erfolgreich. Kein Build gestartet."
    exit 0
fi

echo
echo "ARM64-Version wird kompiliert ..."

cmake \
    -S "$ROOT/ports/r36s" \
    -B "$BUILD" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPCRECOMP="$PCRECOMP" \
    -DGEN_DIR="$GEN" \
    -DDXVK_SOURCE="$DXVK"

cmake --build "$BUILD" \
    --parallel "${NFSU2_BUILD_JOBS:-2}"

BINARY="$BUILD/nfsu2.aarch64"

[[ -s "$BINARY" ]] ||
    fail "Kompilierung hat keine Programmdatei erzeugt."

echo
echo "BUILD ERFOLGREICH!"
ls -lh "$BINARY"
