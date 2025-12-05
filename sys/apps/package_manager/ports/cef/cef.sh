#!/usr/bin/env bash

set -euo pipefail

echo "=========================================="
echo "Installing CEF binary into thirdparty dir"
echo "=========================================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THIRDPARTY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CEF_URL="https://cef-builds.spotifycdn.com/cef_binary_142.0.17%2Bg60aac24%2Bchromium-142.0.7444.176_linux64.tar.bz2"
CEF_TARBALL_NAME="cef_binary_142.0.17+g60aac24+chromium-142.0.7444.176_linux64.tar.bz2"

CEF_DOWNLOAD_DIR="${SCRIPT_DIR}/cef_downloads"
CEF_INSTALL_DIR="${THIRDPARTY_ROOT}/cef"

echo "SCRIPT_DIR        : ${SCRIPT_DIR}"
echo "THIRDPARTY_ROOT   : ${THIRDPARTY_ROOT}"
echo "CEF_DOWNLOAD_DIR  : ${CEF_DOWNLOAD_DIR}"
echo "CEF_INSTALL_DIR   : ${CEF_INSTALL_DIR}"
echo

mkdir -p "${CEF_DOWNLOAD_DIR}" "${CEF_INSTALL_DIR}"

TARBALL_PATH="${CEF_DOWNLOAD_DIR}/${CEF_TARBALL_NAME}"

if [ ! -f "${TARBALL_PATH}" ]; then
    echo "[1/2] Downloading CEF binary package..."
    if command -v curl >/dev/null 2>&1; then
        curl -L "${CEF_URL}" -o "${TARBALL_PATH}"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "${TARBALL_PATH}" "${CEF_URL}"
    else
        echo "ERROR: Neither 'curl' nor 'wget' is available to download CEF."
        exit 1
    fi
else
    echo "CEF tarball already present at ${TARBALL_PATH}, reusing it."
fi

echo
echo "[2/2] Extracting CEF into install directory..."

# Clean install dir to avoid mixing different versions
rm -rf "${CEF_INSTALL_DIR:?}/"*

tar -xjf "${TARBALL_PATH}" -C "${CEF_INSTALL_DIR}" --strip-components=1

echo
echo "CEF installation complete."
echo "Installed files are under:"
echo "  ${CEF_INSTALL_DIR}"
echo
echo "You can point your CMake configuration to this directory via CMAKE_PREFIX_PATH or explicit CEF paths."

