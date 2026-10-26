#!/usr/bin/env bash
# Build and install st-patched on Debian-based systems.
#
# Sources, checksums, and patch logic are read directly from the PKGBUILD in
# this directory — no duplication of that metadata here.
#
# Usage:
#   sudo ./debian-install.sh              install to /usr/local (default)
#   sudo ./debian-install.sh --prefix /usr/local
#   sudo ./debian-install.sh --prefix /usr

set -euo pipefail

if ! command -v apt-get &>/dev/null; then
    echo "error: this script requires a Debian-based system (apt-get not found)" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX=/usr/local

# Debian equivalents of PKGBUILD depends + makedepends.
# NOTE: keep in sync with depends/makedepends in PKGBUILD — no automatic translation exists.
DEBIAN_DEPS=(
    libxft-dev
    libxext-dev
    libfreetype6-dev
    libfontconfig1-dev
    libxrender-dev
    libx11-dev
)

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix) PREFIX="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# --- dependency install -------------------------------------------------------

install_deps() {
    sudo apt-get install -y "${DEBIAN_DEPS[@]}"
}

# --- source metadata from PKGBUILD -------------------------------------------
# Stub the build functions so sourcing the PKGBUILD only loads variables.
# prepare()/build() are called explicitly below after srcdir is set up.
prepare() { :; }
build()   { :; }
package() { :; }
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/PKGBUILD"

# --- download and verify sources ---------------------------------------------

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

export srcdir="${workdir}/src"
mkdir -p "$srcdir"

i=0
for entry in "${source[@]}"; do
    expected_sum="${sha256sums[$i]}"
    i=$(( i + 1 ))

    if [[ "$entry" == *::* ]]; then
        filename="${entry%%::*}"
        url="${entry##*::}"
    else
        url="$entry"
        filename="${url##*/}"
    fi

    destfile="${srcdir}/${filename}"

    if [[ "$url" == *://* ]]; then
        echo "Downloading ${filename}..."
        curl -fL -o "$destfile" "$url"
    else
        # Local file relative to the PKGBUILD directory
        cp "${SCRIPT_DIR}/${url}" "$destfile"
    fi

    actual_sum=$(sha256sum "$destfile" | awk '{print $1}')
    if [[ "$actual_sum" != "$expected_sum" ]]; then
        echo "error: SHA256 mismatch for ${filename}" >&2
        echo "  expected: ${expected_sum}" >&2
        echo "  got:      ${actual_sum}" >&2
        exit 1
    fi
done

# --- extract, patch, build ---------------------------------------------------

cd "$srcdir"
tar -xzf "st-${pkgver}.tar.gz"

# Re-source to get the real prepare() and build() now that srcdir is populated.
unset -f prepare build package
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/PKGBUILD"

prepare
cd "$srcdir"
build

# --- install -----------------------------------------------------------------

cd "${srcdir}/st-${pkgver}"

install -Dm755 st "${PREFIX}/bin/st"
install -Dm644 st.1 "${PREFIX}/share/man/man1/st.1"
sed -i "s/VERSION/${pkgver}/g" "${PREFIX}/share/man/man1/st.1"

# Terminfo is intentionally NOT installed. ncurses already provides the `st`
# and `st-256color` entries that $TERM resolves to; installing our own would
# conflict with ncurses-owned files.

install -Dm644 LICENSE "${PREFIX}/share/licenses/st-patched/LICENSE"
