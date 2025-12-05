#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="1.25"
NAME="libdeflate-${VERSION}"
ARCHIVE="v${VERSION}.tar.gz"
URL="https://github.com/ebiggers/libdeflate/archive/refs/tags/${ARCHIVE}"

cd "$SCRIPT_DIR"

echo "Downloading libdeflate ${VERSION}..."
curl -L -o "$ARCHIVE" "$URL"

echo "Extracting ${NAME}..."
tar xzf "$ARCHIVE"

cd "$NAME"

echo "Configuring libdeflate with CMake..."
mkdir -p build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX="${SYSTEM_DIR}" \
    -DCMAKE_C_FLAGS="-fPIC -O2" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLIBDEFLATE_BUILD_STATIC_LIB=ON \
    -DLIBDEFLATE_BUILD_SHARED_LIB=OFF \
    -DLIBDEFLATE_BUILD_GZIP=OFF

echo "Building libdeflate..."
make -j$(nproc)

echo "Installing libdeflate to ${SYSTEM_DIR}..."
make install

cd "$SCRIPT_DIR"
rm -rf "$NAME" "$ARCHIVE"

echo "libdeflate ${VERSION} installed successfully to ${SYSTEM_DIR}"
echo "Library: libdeflate.a"
echo "Header: libdeflate.h"
