#!/bin/bash
set -e

# libsodium cryptography library build script
NAME="libsodium"
VERSION="1.0.20"
URL="https://github.com/jedisct1/libsodium/archive/refs/tags/${VERSION}-RELEASE.tar.gz"
TARBALL="${VERSION}-RELEASE.tar.gz"
BUILD_DIR="${NAME}-${VERSION}-RELEASE"

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

# Run autogen to generate configure script
echo "[${NAME}] Running autogen.sh..."
./autogen.sh

# Configure libsodium
./configure \
    --prefix="${SYSTEM_DIR}" \
    --libdir="${SYSTEM_DIR}/lib" \
    --enable-shared \
    --enable-static

# Build libsodium
make -j$(nproc)

echo "[${NAME}] Installing to ${SYSTEM_DIR}..."
make install

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}"
