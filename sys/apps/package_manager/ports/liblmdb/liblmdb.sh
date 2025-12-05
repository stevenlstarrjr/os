#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

NAME="openldap-mdb.master"
ARCHIVE="${NAME}.tar.gz"
URL="https://git.openldap.org/openldap/openldap/-/archive/mdb.master/openldap-mdb.master.tar.gz"

cd "$SCRIPT_DIR"

echo "Downloading LMDB from OpenLDAP repository..."
curl -L -o "$ARCHIVE" "$URL"

echo "Extracting ${NAME}..."
tar xzf "$ARCHIVE"

cd "${NAME}/libraries/liblmdb"

echo "Building LMDB..."
make -j$(nproc) XCFLAGS="-fPIC -O2"

echo "Installing LMDB to ${SYSTEM_DIR}..."
# Install library
install -D -m 644 liblmdb.a "${SYSTEM_DIR}/lib/liblmdb.a"

# Install headers
install -D -m 644 lmdb.h "${SYSTEM_DIR}/include/lmdb.h"

cd "$SCRIPT_DIR"
rm -rf "$NAME" "$ARCHIVE"

echo "LMDB installed successfully to ${SYSTEM_DIR}"
