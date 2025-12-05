#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo "Installing Skia into local thirdparty dir"
echo "========================================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THIRDPARTY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALL_PREFIX="${THIRDPARTY_ROOT}"
SKIA_SRC_DIR="${SCRIPT_DIR}/skia"
SKIA_BUILD_DIR="${SCRIPT_DIR}/build-skia"

echo "SCRIPT_DIR       : ${SCRIPT_DIR}"
echo "THIRDPARTY_ROOT  : ${THIRDPARTY_ROOT}"
echo "SKIA_SRC_DIR     : ${SKIA_SRC_DIR}"
echo "SKIA_BUILD_DIR   : ${SKIA_BUILD_DIR}"
echo "INSTALL_PREFIX   : ${INSTALL_PREFIX}"
echo

mkdir -p "${SKIA_SRC_DIR}" "${SKIA_BUILD_DIR}"

if [ ! -d "${SKIA_SRC_DIR}/.git" ]; then
    echo "[1/3] Cloning Skia..."
    git clone https://skia.googlesource.com/skia "${SKIA_SRC_DIR}"
else
    echo "Skia already cloned at ${SKIA_SRC_DIR}, pulling latest..."
    (cd "${SKIA_SRC_DIR}" && git pull --ff-only)
fi

SKIA_VERSION="$(cd "${SKIA_SRC_DIR}" && (git describe --tags --dirty --always 2>/dev/null || git rev-parse --short HEAD))"

echo
echo "Building Skia version: ${SKIA_VERSION}"
echo

echo
echo "[2/3] Syncing Skia dependencies (requires depot_tools in PATH)..."
(
    cd "${SKIA_SRC_DIR}"
    python tools/git-sync-deps
)

echo
echo "[3/3] Building Skia with GN/Ninja..."
(
    cd "${SKIA_SRC_DIR}"
    gn gen "${SKIA_BUILD_DIR}" --args="is_official_build=true is_component_build=false skia_use_system_expat=false skia_use_system_icu=false skia_use_system_zlib=false skia_use_system_harfbuzz=false skia_use_system_libjpeg_turbo=false skia_use_system_libpng=false skia_use_system_freetype2=false skia_enable_gpu=true skia_use_gl=true skia_use_vulkan=true skia_use_graphite=true skia_enable_pdf=true skia_enable_svg=true skia_enable_skshaper=true"
    ninja -C "${SKIA_BUILD_DIR}"
)

echo
echo "Skia build complete. Binaries/libraries are in:"
echo "  ${SKIA_BUILD_DIR}"
echo

echo "[4/4] Installing Skia headers and libraries..."
INSTALL_INCLUDE_DIR="${INSTALL_PREFIX}/include/skia"
INSTALL_LIB_DIR="${INSTALL_PREFIX}/lib"

mkdir -p "${INSTALL_INCLUDE_DIR}" "${INSTALL_LIB_DIR}"

echo "  Copying headers to: ${INSTALL_INCLUDE_DIR}"
cp -a "${SKIA_SRC_DIR}/include/." "${INSTALL_INCLUDE_DIR}/"

echo "  Copying libraries to: ${INSTALL_LIB_DIR}"
cp -a "${SKIA_BUILD_DIR}"/*.a "${INSTALL_LIB_DIR}/" 2>/dev/null || true
cp -a "${SKIA_BUILD_DIR}"/*.so "${INSTALL_LIB_DIR}/" 2>/dev/null || true

echo
echo "Skia version file written to:"
echo "  ${SKIA_BUILD_DIR}/SKIA_VERSION.txt"
echo "${SKIA_VERSION}" > "${SKIA_BUILD_DIR}/SKIA_VERSION.txt"
echo
echo "Installed Skia into:"
echo "  ${INSTALL_PREFIX}"
echo
echo "You can copy or reference these from your CMake configuration as needed."
