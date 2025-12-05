#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="18.1"
NAME="postgresql-${VERSION}"
ARCHIVE="${NAME}.tar.gz"
URL="https://ftp.postgresql.org/pub/source/v${VERSION}/${ARCHIVE}"

cd "$SCRIPT_DIR"

echo "Downloading ${NAME}..."
curl -L -o "$ARCHIVE" "$URL"

echo "Extracting ${NAME}..."
tar xzf "$ARCHIVE"

cd "$NAME"

echo "Configuring ${NAME}..."
./configure \
    --prefix="${SYSTEM_DIR}" \
    --libdir="${SYSTEM_DIR}/lib" \
    --enable-thread-safety \
    --with-openssl \
    --with-readline \
    --with-zlib \
    CFLAGS="-fPIC -O2" \
    OPENSSL_CFLAGS="-I${SYSTEM_DIR}/include" \
    OPENSSL_LIBS="-L${SYSTEM_DIR}/lib -lssl -lcrypto"

echo "Building ${NAME}..."
make -j$(nproc)

echo "Installing ${NAME}..."
make install

cd "$SCRIPT_DIR"
rm -rf "$NAME" "$ARCHIVE"

echo "${NAME} installed successfully to ${SYSTEM_DIR}"
