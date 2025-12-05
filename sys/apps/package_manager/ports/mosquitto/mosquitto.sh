#!/bin/bash
set -e

# Mosquitto MQTT broker/library build script
NAME="mosquitto"
VERSION="2.0.22"
URL="https://github.com/eclipse-mosquitto/mosquitto/archive/refs/tags/v${VERSION}.tar.gz"
TARBALL="v${VERSION}.tar.gz"
BUILD_DIR="${NAME}-${VERSION}"

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure we're in the src directory
cd "$SCRIPT_DIR"

echo "[${NAME}] Downloading ${URL}..."
wget -O "${TARBALL}" "${URL}"

echo "[${NAME}] Extracting ${TARBALL}..."
tar -xzf "${TARBALL}"

echo "[${NAME}] Building ${NAME} in ${SCRIPT_DIR}/${BUILD_DIR}..."
cd "${BUILD_DIR}"

# Create build directory
mkdir -p build
cd build

# Configure with CMake
# Point to our custom OpenSSL installation
export PKG_CONFIG_PATH="${SYSTEM_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
export OPENSSL_ROOT_DIR="${SYSTEM_DIR}"

"${SYSTEM_DIR}/bin/cmake" .. \
    -DCMAKE_INSTALL_PREFIX="${SYSTEM_DIR}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DWITH_STATIC_LIBRARIES=ON \
    -DDOCUMENTATION=OFF \
    -DOPENSSL_ROOT_DIR="${SYSTEM_DIR}" \
    -DOPENSSL_INCLUDE_DIR="${SYSTEM_DIR}/include" \
    -DOPENSSL_CRYPTO_LIBRARY="${SYSTEM_DIR}/lib/libcrypto.so" \
    -DOPENSSL_SSL_LIBRARY="${SYSTEM_DIR}/lib/libssl.so" \
    -G Ninja

# Build with Ninja
"${SYSTEM_DIR}/bin/ninja"

echo "[${NAME}] Installing to ${SYSTEM_DIR}..."
"${SYSTEM_DIR}/bin/ninja" install

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}"
