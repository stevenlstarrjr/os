#!/bin/bash
set -e

# Meson build script
NAME="meson"
VERSION="1.6.1"
URL="https://github.com/mesonbuild/meson/releases/download/${VERSION}/meson-${VERSION}.tar.gz"
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

echo "[${NAME}] Installing ${NAME} to ${SYSTEM_DIR}..."
cd "${BUILD_DIR}"

# Install meson using Python
python3 setup.py install --prefix="${SYSTEM_DIR}"

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}"
