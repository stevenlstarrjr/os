#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="1.68.0"
NAME="nghttp2-${VERSION}"
ARCHIVE="v${VERSION}.tar.gz"
URL="https://github.com/nghttp2/nghttp2/archive/refs/tags/${ARCHIVE}"

cd "$SCRIPT_DIR"

echo "Downloading nghttp2 ${VERSION}..."
curl -L -o "$ARCHIVE" "$URL"

echo "Extracting ${NAME}..."
tar xzf "$ARCHIVE"

cd "$NAME"

echo "Running autoreconf..."
autoreconf -i

echo "Configuring nghttp2..."
./configure \
    --prefix="${SYSTEM_DIR}" \
    --enable-static \
    --disable-shared \
    --enable-lib-only \
    --disable-examples \
    --disable-python-bindings \
    --with-pic \
    CFLAGS="-fPIC -O2" \
    CXXFLAGS="-fPIC -O2"

echo "Building nghttp2..."
make -j$(nproc)

echo "Installing nghttp2 to ${SYSTEM_DIR}..."
make install

cd "$SCRIPT_DIR"
rm -rf "$NAME" "$ARCHIVE"

echo "nghttp2 ${VERSION} installed successfully to ${SYSTEM_DIR}"
echo "Library: libnghttp2.a"
echo "Headers: nghttp2/*"
