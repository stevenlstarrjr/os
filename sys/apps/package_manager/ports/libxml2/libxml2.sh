#!/bin/bash
set -e

# libxml2 XML parser library build script
NAME="libxml2"
VERSION="master"
URL="https://gitlab.gnome.org/GNOME/libxml2/-/archive/master/libxml2-master.tar.gz"
TARBALL="${NAME}-${VERSION}.tar.gz"
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
"${SYSTEM_DIR}/bin/cmake" .. \
    -DCMAKE_INSTALL_PREFIX="${SYSTEM_DIR}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
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
