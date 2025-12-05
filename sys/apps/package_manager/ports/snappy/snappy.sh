#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="1.2.2"
NAME="snappy-${VERSION}"
ARCHIVE="${VERSION}.tar.gz"
URL="https://github.com/google/snappy/archive/refs/tags/${ARCHIVE}"

cd "$SCRIPT_DIR"

echo "Downloading Snappy ${VERSION}..."
curl -L -o "$ARCHIVE" "$URL"

echo "Extracting ${NAME}..."
tar xzf "$ARCHIVE"

cd "$NAME"

echo "Configuring Snappy with CMake..."
mkdir -p build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX="${SYSTEM_DIR}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_CXX_FLAGS="-fPIC -O2" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DSNAPPY_BUILD_TESTS=OFF \
    -DSNAPPY_BUILD_BENCHMARKS=OFF

echo "Building Snappy..."
make -j$(nproc)

echo "Installing Snappy to ${SYSTEM_DIR}..."
make install

cd "$SCRIPT_DIR"
rm -rf "$NAME" "$ARCHIVE"

echo "Snappy ${VERSION} installed successfully to ${SYSTEM_DIR}"
echo "Library: libsnappy.a"
echo "Headers: snappy.h, snappy-c.h, snappy-sinksource.h"
