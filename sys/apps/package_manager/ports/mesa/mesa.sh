#!/bin/bash
set -e

# Mesa 3D Graphics Library build script
NAME="mesa"
VERSION="25.3.0"
URL="https://archive.mesa3d.org/mesa-${VERSION}.tar.xz"
TARBALL="mesa-${VERSION}.tar.xz"
BUILD_DIR="mesa-${VERSION}"

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure we're in the src directory
cd "$SCRIPT_DIR"

echo "[${NAME}] Downloading ${URL}..."
wget -O "${TARBALL}" "${URL}"

echo "[${NAME}] Extracting ${TARBALL}..."
tar -xf "${TARBALL}"

echo "[${NAME}] Building ${NAME} in ${SCRIPT_DIR}/${BUILD_DIR}..."
cd "${BUILD_DIR}"

# Create build directory
mkdir -p build
cd build

# Configure with Meson
"${SYSTEM_DIR}/bin/meson" setup .. \
    --prefix="${SYSTEM_DIR}" \
    --buildtype=release \
    -Dplatforms=x11,wayland \
    -Dgallium-drivers=radeonsi,iris,crocus,swrast \
    -Dvulkan-drivers=amd,intel,swrast \
    -Dglx=dri \
    -Degl=enabled \
    -Dgles1=disabled \
    -Dgles2=enabled \
    -Dshared-glapi=enabled

# Build with Ninja
"${SYSTEM_DIR}/bin/ninja"

echo "[${NAME}] Installing to ${SYSTEM_DIR}..."
"${SYSTEM_DIR}/bin/ninja" install

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}"
