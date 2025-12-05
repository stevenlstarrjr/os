#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="1.11.1"
NAME="libssh2-${VERSION}"
ARCHIVE="${NAME}.tar.gz"
URL="https://github.com/libssh2/libssh2/archive/refs/tags/libssh2-${VERSION}.tar.gz"

cd "$SCRIPT_DIR"

echo "Downloading ${NAME}..."
curl -L -o "$ARCHIVE" "$URL"

echo "Extracting ${NAME}..."
tar xzf "$ARCHIVE"

cd "libssh2-libssh2-${VERSION}"

echo "Building ${NAME}..."
mkdir -p build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX="${SYSTEM_DIR}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTING=OFF \
    -DOPENSSL_ROOT_DIR="${SYSTEM_DIR}" \
    -DOPENSSL_INCLUDE_DIR="${SYSTEM_DIR}/include" \
    -DOPENSSL_CRYPTO_LIBRARY="${SYSTEM_DIR}/lib/libcrypto.a" \
    -DOPENSSL_SSL_LIBRARY="${SYSTEM_DIR}/lib/libssl.a"

make -j$(nproc)

echo "Installing ${NAME}..."
make install

cd "$SCRIPT_DIR"
rm -rf "libssh2-libssh2-${VERSION}" "$ARCHIVE"

echo "${NAME} installed successfully to ${SYSTEM_DIR}"
