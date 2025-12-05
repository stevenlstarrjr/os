#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="1.2.0"
NAME="brotli-${VERSION}"
ARCHIVE="v${VERSION}.tar.gz"
URL="https://github.com/google/brotli/archive/refs/tags/${ARCHIVE}"

cd "$SCRIPT_DIR"

echo "Downloading Brotli ${VERSION}..."
curl -L -o "$ARCHIVE" "$URL"

echo "Extracting ${NAME}..."
tar xzf "$ARCHIVE"

cd "$NAME"

echo "Configuring Brotli with CMake..."
mkdir -p build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX="${SYSTEM_DIR}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_C_FLAGS="-fPIC -O2" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF

echo "Building Brotli..."
make -j$(nproc)

echo "Installing Brotli to ${SYSTEM_DIR}..."
make install

cd "$SCRIPT_DIR"
rm -rf "$NAME" "$ARCHIVE"

echo "Brotli ${VERSION} installed successfully to ${SYSTEM_DIR}"
echo "Libraries: libbrotlienc.a, libbrotlidec.a, libbrotlicommon.a"
echo "Headers: brotli/*"
