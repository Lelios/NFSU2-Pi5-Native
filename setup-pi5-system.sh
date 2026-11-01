#!/usr/bin/env bash
set -euo pipefail

MODE="${1:---check}"

case "$MODE" in
    --check|--install) ;;
    *)
        echo "Aufruf: $0 [--check|--install]"
        exit 2
        ;;
esac

PACKAGES=(
    git
    build-essential
    cmake
    pkg-config
    libsdl2-dev
    libegl-dev
    libgles-dev
    libvulkan-dev
    python3
    python3-pefile
    python3-capstone
)

echo "========================================"
echo " NFSU2 PI 5 - UBUNTU-VORAUSSETZUNGEN"
echo "========================================"

if [[ "$(uname -s)" != "Linux" ||
      "$(uname -m)" != "aarch64" ]]; then
    echo "FEHLER: Linux ARM64 erforderlich."
    exit 1
fi

command -v dpkg-query >/dev/null || {
    echo "FEHLER: Ubuntu/Debian-Paketverwaltung fehlt."
    exit 1
}

missing=()

for package in "${PACKAGES[@]}"; do
    status="$(
        dpkg-query -W -f='${Status}' \
            "$package" 2>/dev/null || true
    )"

    if [[ "$status" == "install ok installed" ]]; then
        echo "OK: $package"
    else
        echo "FEHLT: $package"
        missing+=("$package")
    fi
done

echo

if (( ${#missing[@]} == 0 )); then
    echo "ERFOLG: Alle Systempakete vorhanden."
    exit 0
fi

echo "${#missing[@]} Systempaket(e) fehlen."

if [[ "$MODE" == "--check" ]]; then
    echo "Nur geprüft. Keine Installation gestartet."
    exit 2
fi

command -v apt-get >/dev/null || {
    echo "FEHLER: apt-get nicht vorhanden."
    exit 1
}

echo
echo "Diese Pakete sollen installiert werden:"
printf '  %s\n' "${missing[@]}"
echo
echo "Dafür wird die Ubuntu-Paketverwaltung verwendet."
echo "Möglicherweise wird dein sudo-Passwort benötigt."

if [[ ! -t 0 ]]; then
    echo "ABBRUCH: Bestätigung am Terminal erforderlich."
    exit 1
fi

read -r -p "Installation erlauben? [ja/NEIN]: " answer

case "$answer" in
    ja|JA|j|J|yes|YES|y|Y)
        ;;
    *)
        echo "Installation abgebrochen."
        exit 1
        ;;
esac

if (( EUID == 0 )); then
    apt-get update
    apt-get install -y "${missing[@]}"
else
    command -v sudo >/dev/null || {
        echo "FEHLER: sudo fehlt."
        exit 1
    }

    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
fi

echo
echo "Installierte Pakete abschließend prüfen ..."

for package in "${PACKAGES[@]}"; do
    status="$(
        dpkg-query -W -f='${Status}' \
            "$package" 2>/dev/null || true
    )"

    if [[ "$status" != "install ok installed" ]]; then
        echo "FEHLER: Paket fehlt weiterhin: $package"
        exit 1
    fi
done

echo "ERFOLG: Alle Ubuntu-Systempakete eingerichtet."
