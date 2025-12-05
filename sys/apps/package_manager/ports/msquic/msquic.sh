#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="2.5.5"
NAME="msquic-${VERSION}"
ARCHIVE="v${VERSION}.tar.gz"
URL="https://github.com/microsoft/msquic/archive/refs/tags/v2.5.5.tar.gz"

cd "$SCRIPT_DIR"

echo "Downloading msquic ${VERSION}..."
curl -L -o "$ARCHIVE" "$URL"

echo "Extracting ${NAME}..."
tar xzf "$ARCHIVE"

cd "$NAME"

if [ ! -f "submodules/quictls/config" ]; then
    echo "Fetching quictls (OpenSSL) submodule..."
    git clone --depth 1 https://github.com/quictls/openssl.git submodules/quictls
fi

echo "Configuring msquic with CMake..."
mkdir -p build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX="${SYSTEM_DIR}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_C_FLAGS="-fPIC -O2" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DQUIC_BUILD_SHARED=OFF \
    -DQUIC_BUILD_TOOLS=OFF \
    -DQUIC_BUILD_TEST=OFF \
    -DQUIC_BUILD_PERF=OFF

echo "Building msquic..."
make -j"$(nproc)"

echo "Installing msquic to ${SYSTEM_DIR}..."
make install

cd "$SCRIPT_DIR"
rm -rf "$NAME" "$ARCHIVE"

echo "msquic ${VERSION} installed successfully to ${SYSTEM_DIR}"
echo "Library: libmsquic.a (and/or related msquic libs)"
echo "Headers: msquic/*"
