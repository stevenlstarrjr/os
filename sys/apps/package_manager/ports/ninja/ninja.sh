#!/bin/bash
set -e

# Ninja build script
NAME="ninja"
VERSION="1.13.2"
URL="https://github.com/ninja-build/ninja/archive/refs/tags/v${VERSION}.tar.gz"
TARBALL="${NAME}-${VERSION}.tar.gz"
BUILD_DIR="${NAME}-${VERSION}"

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure we're in the src directory
cd "$SCRIPT_DIR"

echo "[${NAME}] Downloading ${URL}..."
wget -O "${TARBALL}" "${URL}"

echo "[${NAME}] Extracting ${TARBALL}..."
tar -xzf "${TARBALL}"

echo "[${NAME}] Building ${NAME} in ${SCRIPT_DIR}/${BUILD_DIR}..."
cd "${BUILD_DIR}"

# Build ninja using its configure script
./configure.py --bootstrap

echo "[${NAME}] Installing to ${SYSTEM_DIR}..."
mkdir -p "${SYSTEM_DIR}/bin"
cp ninja "${SYSTEM_DIR}/bin/"

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}/bin/ninja"
