#!/bin/bash
set -e

# FFmpeg multimedia framework build script
NAME="ffmpeg"
VERSION="8.0.1"
URL="https://ffmpeg.org/releases/ffmpeg-${VERSION}.tar.xz"
TARBALL="${NAME}-${VERSION}.tar.xz"
BUILD_DIR="${NAME}-${VERSION}"

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure we're in the src directory
cd "$SCRIPT_DIR"

echo "[${NAME}] Downloading ${URL}..."
wget -O "${TARBALL}" "${URL}"

echo "[${NAME}] Extracting ${TARBALL}..."
tar -xf "${TARBALL}"

echo "[${NAME}] Building ${NAME} in ${SCRIPT_DIR}/${BUILD_DIR}..."
cd "${BUILD_DIR}"

# Configure FFmpeg
./configure \
    --prefix="${SYSTEM_DIR}" \
    --enable-shared \
    --enable-gpl \
    --enable-version3 \
    --enable-nonfree \
    --disable-static \
    --disable-doc

# Build FFmpeg
make -j$(nproc)

echo "[${NAME}] Installing to ${SYSTEM_DIR}..."
make install

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}"
