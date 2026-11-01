#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BASE="${NFSU2_DEPS_DIR:-$HOME/.cache/nfsu2-pi5-native/deps}"

PC="$BASE/pcrecomp"
DXVK="$BASE/dxvk-source"

PCPIN="01655572c8f91a5b549b9cfed0b97901391d22fd"
BASEPIN="35548b8d0fd8aa853da67edcf7cd6134f6b9cdc7"
DXPIN="c8dc91fabd00cac11d697ccf07426e798393cd40"

PATCH="$ROOT/patches/pcrecomp-pi5.patch"
HISTORY="$ROOT/patches/pcrecomp-history-pi5.patch"
MANIFEST="$ROOT/patches/pcrecomp-pi5-sha256.txt"
PREP="$ROOT/ports/dxvk_android/prepare.py"

fail() {
    echo "FEHLER: $*" >&2
    exit 1
}

echo "========================================"
echo " NFSU2 PI 5 NATIVE"
echo " ENTWICKLUNGSWERKZEUGE EINRICHTEN"
echo "========================================"

[[ "$(uname -s)" == "Linux" ]] ||
    fail "Linux erforderlich."

[[ "$(uname -m)" == "aarch64" ]] ||
    fail "ARM64 erforderlich."

for PROGRAM in git python3; do
    command -v "$PROGRAM" >/dev/null ||
        fail "$PROGRAM fehlt."
done

[[ -s "$PATCH" ]] ||
    fail "pcrecomp-Patch fehlt."

[[ -s "$PREP" ]] ||
    fail "DXVK-Vorbereitung fehlt."

mkdir -p "$BASE"

TMP="$(mktemp -d "$BASE/.setup.XXXXXXXX")"

trap 'rm -rf -- "$TMP"' EXIT

echo
# PI5_PUBLIC_BASE_PATCHES
echo "[1/4] pcrecomp vorbereiten"

[[ -s "$HISTORY" ]] ||
    fail "Historischer pcrecomp-Patch fehlt."

[[ -s "$MANIFEST" ]] ||
    fail "pcrecomp-Pruefsummen fehlen."

if [[ -L "$PC" ]]; then
    fail "pcrecomp-Ziel ist ein symbolischer Link."
fi

verify_pcrecomp() {
    local revision

    [[ -d "$1/.git" ]] ||
        fail "pcrecomp-Git-Verzeichnis fehlt."

    revision="$(git -C "$1" rev-parse HEAD)"

    if [[ "$revision" != "$BASEPIN" &&
          "$revision" != "$PCPIN" ]]; then
        fail "Unerwartete pcrecomp-Version."
    fi

    (
        cd "$1"
        sha256sum -c "$MANIFEST" >/dev/null
    ) || fail "pcrecomp-Dateien stimmen nicht."
}

if [[ -e "$PC" ]]; then

    echo "Vorhandene Toolchain pruefen ..."

    verify_pcrecomp "$PC"

    echo "OK: pcrecomp bereits korrekt eingerichtet."

else

    echo "Oeffentlichen pcrecomp-Code herunterladen ..."

    git clone --quiet \
        https://github.com/sp00nznet/pcrecomp.git \
        "$TMP/pcrecomp"

    git -C "$TMP/pcrecomp" checkout \
        --quiet --detach "$BASEPIN"

    [[ "$(git -C "$TMP/pcrecomp" rev-parse HEAD)" == "$BASEPIN" ]] ||
        fail "Ausgangscommit stimmt nicht."

    echo "Historischen Patch anwenden ..."

    git -C "$TMP/pcrecomp" apply \
        --check "$HISTORY"

    git -C "$TMP/pcrecomp" apply "$HISTORY"

    echo "Compiler-Patch anwenden ..."

    git -C "$TMP/pcrecomp" apply \
        --check "$PATCH"

    git -C "$TMP/pcrecomp" apply "$PATCH"

    echo "Wiederhergestellte Dateien pruefen ..."

    verify_pcrecomp "$TMP/pcrecomp"

    mv -T "$TMP/pcrecomp" "$PC"

    echo "OK: pcrecomp erfolgreich rekonstruiert."

fi

echo
echo "[2/4] DXVK Native vorbereiten"

if [[ -L "$DXVK" ]]; then
    fail "DXVK-Ziel ist ein symbolischer Link."
fi

if [[ -e "$DXVK" ]]; then

    [[ -f "$DXVK/PINNED_REVISION" ]] ||
        fail "DXVK-Versionsdatei fehlt."

    grep -qx "$DXPIN" "$DXVK/PINNED_REVISION" ||
        fail "Vorhandene DXVK-Version stimmt nicht."

    [[ -f "$DXVK/include/native/windows/windows.h" ]] ||
        fail "Vorhandene DXVK-Header unvollständig."

    echo "OK: DXVK bereits eingerichtet."

else
    echo "DXVK Native 1.9.2b herunterladen ..."

    git clone --quiet --depth 1 \
        --branch native-1.9.2b \
        https://github.com/misyltoad/dxvk-native.git \
        "$TMP/dxvk-native-src"

    REV="$(git -C "$TMP/dxvk-native-src" rev-parse HEAD)"

    [[ "$REV" == "$DXPIN" ]] ||
        fail "DXVK-Commit stimmt nicht."

    echo "DXVK für ARM64 vorbereiten ..."

    python3 "$PREP" \
        "$TMP/dxvk-native-src" \
        "$TMP/dxvk-source"

    [[ -f "$TMP/dxvk-source/PINNED_REVISION" ]] ||
        fail "DXVK-Versionsdatei fehlt."

    grep -qx "$DXPIN" \
        "$TMP/dxvk-source/PINNED_REVISION" ||
        fail "DXVK-Versionsprüfung fehlgeschlagen."

    [[ -d "$TMP/dxvk-source/include/native" ]] ||
        fail "DXVK-Header fehlen."

    mv -T "$TMP/dxvk-source" "$DXVK"

    echo "OK: DXVK vorbereitet."
fi

echo
echo "[3/4] Installationen überprüfen"

[[ -d "$PC/runtime/recomp32" ]] ||
    fail "pcrecomp-Laufzeit fehlt."

[[ -d "$PC/tools/pe" ]] ||
    fail "pcrecomp-Analysewerkzeuge fehlen."

[[ -d "$DXVK/include/native" ]] ||
    fail "DXVK-Native-Header fehlen."

echo "OK: Beide Abhängigkeiten vorhanden."

echo
echo "[4/4] Ergebnis"

echo
echo "pcrecomp:"
echo "$PC"

echo
echo "DXVK:"
echo "$DXVK"

echo
echo "========================================"
echo " ENTWICKLUNGSWERKZEUGE BEREIT!"
echo "========================================"

echo
echo "Keine Spielinstallation verändert."
echo "Keine GOLD-Sicherung verändert."
