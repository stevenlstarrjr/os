#!/bin/bash
set -e

# OpenSSL cryptography library build script
NAME="openssl"
VERSION="3.6.0"
URL="https://github.com/openssl/openssl/archive/refs/tags/openssl-${VERSION}.tar.gz"
TARBALL="openssl-${VERSION}.tar.gz"
BUILD_DIR="openssl-openssl-${VERSION}"

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

# Configure OpenSSL
# Use ./Configure (capital C) - OpenSSL's custom configure script
# --libdir=lib ensures libraries go to lib/ not lib64/
./Configure \
    --prefix="${SYSTEM_DIR}" \
    --libdir=lib \
    shared \
    enable-fips

# Build OpenSSL
make -j$(nproc)

echo "[${NAME}] Installing to ${SYSTEM_DIR}..."
make install

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}"
