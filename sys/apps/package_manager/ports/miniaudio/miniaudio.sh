#!/bin/bash
set -e

# miniaudio single-file audio library build script
NAME="miniaudio"
VERSION="0.11.23"
URL="https://github.com/mackron/miniaudio/archive/refs/tags/${VERSION}.tar.gz"
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

# miniaudio is a header-only library, just copy the header
mkdir -p "${SYSTEM_DIR}/include"
cp miniaudio.h "${SYSTEM_DIR}/include/"

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}/include/miniaudio.h"
