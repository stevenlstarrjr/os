#!/bin/bash
set -e

# tomlc17 TOML parser library build script
NAME="tomlc17"
VERSION="R250712"
URL="https://github.com/cktan/tomlc17/archive/refs/tags/${VERSION}.tar.gz"
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

# Build tomlc17
make prefix="${SYSTEM_DIR}" -j$(nproc)

echo "[${NAME}] Installing to ${SYSTEM_DIR}..."
make install prefix="${SYSTEM_DIR}"

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}"
