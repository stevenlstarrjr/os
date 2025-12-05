#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="1.12.0"
NAME="nghttp3-${VERSION}"
TAG="v${VERSION}"

cd "$SCRIPT_DIR"

echo "Cloning nghttp3 ${VERSION}..."
git clone --depth 1 --branch "$TAG" --recursive https://github.com/ngtcp2/nghttp3.git "$NAME"

cd "$NAME"

echo "Creating build directory..."
mkdir -p build
cd build

echo "Configuring nghttp3..."
cmake .. \
    -DCMAKE_INSTALL_PREFIX="${SYSTEM_DIR}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_C_FLAGS="-fPIC -O2" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_LIB_ONLY=ON

echo "Building nghttp3..."
make -j$(nproc)

echo "Installing nghttp3 to ${SYSTEM_DIR}..."
make install

cd "$SCRIPT_DIR"
rm -rf "$NAME"

echo "nghttp3 ${VERSION} installed successfully to ${SYSTEM_DIR}"
echo "Library: libnghttp3.a"
echo "Headers: nghttp3/*"
