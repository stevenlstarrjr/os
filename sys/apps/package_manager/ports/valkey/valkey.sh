#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="9.0.0"
NAME="valkey-${VERSION}"
ARCHIVE="${NAME}.tar.gz"
URL="https://github.com/valkey-io/valkey/archive/refs/tags/${VERSION}.tar.gz"

cd "$SCRIPT_DIR"

echo "Downloading Valkey ${VERSION}..."
curl -L -o "$ARCHIVE" "$URL"

echo "Extracting ${NAME}..."
tar xzf "$ARCHIVE"

cd "$NAME"

echo "Building Valkey..."
make -j$(nproc) CFLAGS="-fPIC -O2" BUILD_TLS=yes

echo "Installing Valkey to ${SYSTEM_DIR}..."
# Install binaries
install -D -m 755 src/valkey-server "${SYSTEM_DIR}/bin/valkey-server"
install -D -m 755 src/valkey-cli "${SYSTEM_DIR}/bin/valkey-cli"
install -D -m 755 src/valkey-benchmark "${SYSTEM_DIR}/bin/valkey-benchmark"
install -D -m 755 src/valkey-check-aof "${SYSTEM_DIR}/bin/valkey-check-aof"
install -D -m 755 src/valkey-check-rdb "${SYSTEM_DIR}/bin/valkey-check-rdb"
install -D -m 755 src/valkey-sentinel "${SYSTEM_DIR}/bin/valkey-sentinel"

# Install libvalkey client library and headers
echo "Installing libvalkey client library..."
install -D -m 644 deps/libvalkey/lib/libvalkey.a "${SYSTEM_DIR}/lib/libvalkey.a"
install -D -m 644 deps/libvalkey/lib/libvalkey_tls.a "${SYSTEM_DIR}/lib/libvalkey_tls.a"
cp -r deps/libvalkey/include/valkey "${SYSTEM_DIR}/include/"

cd "$SCRIPT_DIR"
rm -rf "$NAME" "$ARCHIVE"

echo "Valkey ${VERSION} installed successfully to ${SYSTEM_DIR}"
echo "Binaries installed:"
echo "  - valkey-server"
echo "  - valkey-cli"
echo "  - valkey-benchmark"
echo "  - valkey-check-aof"
echo "  - valkey-check-rdb"
echo "  - valkey-sentinel"
echo ""
echo "Client libraries installed:"
echo "  - libvalkey.a"
echo "  - libvalkey_tls.a"
echo "  - valkey headers in include/valkey/"
