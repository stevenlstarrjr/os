#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="2.2.5"
NAME="zlib-ng-${VERSION}"
ARCHIVE="${VERSION}.tar.gz"
URL="https://github.com/zlib-ng/zlib-ng/archive/refs/tags/${ARCHIVE}"

cd "$SCRIPT_DIR"

echo "Downloading zlib-ng ${VERSION}..."
curl -L -o "$ARCHIVE" "$URL"

echo "Extracting ${NAME}..."
tar xzf "$ARCHIVE"

cd "$NAME"

echo "Configuring zlib-ng with CMake..."
mkdir -p build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX="${SYSTEM_DIR}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_C_FLAGS="-fPIC -O2" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DZLIB_COMPAT=OFF \
    -DZLIB_ENABLE_TESTS=OFF

echo "Building zlib-ng..."
make -j$(nproc)

echo "Installing zlib-ng to ${SYSTEM_DIR}..."
make install

cd "$SCRIPT_DIR"
rm -rf "$NAME" "$ARCHIVE"

echo "zlib-ng ${VERSION} installed successfully to ${SYSTEM_DIR}"
echo "Library: libz-ng.a"
echo "Header: zlib-ng.h"
