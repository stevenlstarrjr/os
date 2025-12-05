#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="1.3.0"
NAME="hiredis-${VERSION}"
ARCHIVE="${NAME}.tar.gz"
URL="https://github.com/redis/hiredis/archive/refs/tags/v${VERSION}.tar.gz"

cd "$SCRIPT_DIR"

echo "Downloading hiredis ${VERSION}..."
curl -L -o "$ARCHIVE" "$URL"

echo "Extracting ${NAME}..."
tar xzf "$ARCHIVE"

cd "$NAME"

echo "Building hiredis..."
make CFLAGS="-fPIC -O2" static

echo "Installing hiredis to ${SYSTEM_DIR}..."
# Install library
install -D -m 644 libhiredis.a "${SYSTEM_DIR}/lib/libhiredis.a"

# Install headers
install -D -m 644 hiredis.h "${SYSTEM_DIR}/include/hiredis.h"
install -D -m 644 read.h "${SYSTEM_DIR}/include/hiredis/read.h"
install -D -m 644 sds.h "${SYSTEM_DIR}/include/hiredis/sds.h"
install -D -m 644 alloc.h "${SYSTEM_DIR}/include/hiredis/alloc.h"

cd "$SCRIPT_DIR"
rm -rf "$NAME" "$ARCHIVE"

echo "hiredis ${VERSION} installed successfully to ${SYSTEM_DIR}"
echo "Library: libhiredis.a"
echo "Headers: hiredis.h and hiredis/*"
