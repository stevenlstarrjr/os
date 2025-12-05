#!/bin/bash
set -e

# libcurl HTTP client library build script
NAME="libcurl"
VERSION="8.17.0"
URL="https://github.com/curl/curl/archive/refs/tags/curl-8_17_0.tar.gz"
TARBALL="curl-8_17_0.tar.gz"
BUILD_DIR="curl-curl-8_17_0"

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

# Generate configure script
autoreconf -fi

# Configure libcurl with common features
./configure \
    --prefix="${SYSTEM_DIR}" \
    --enable-shared \
    --enable-static \
    --with-openssl \
    --enable-versioned-symbols \
    --enable-threaded-resolver \
    --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt \
    --with-ca-path=/etc/ssl/certs \
    --without-libpsl \
    --without-brotli \
    --without-libssh2 \
    --without-librtmp \
    --without-libidn2 \
    --without-nghttp2 \
    --without-ngtcp2 \
    --without-nghttp3

# Build libcurl
make -j$(nproc)

echo "[${NAME}] Installing to ${SYSTEM_DIR}..."
make install

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}"
