#!/usr/bin/env bash
set -euo pipefail

# Download, build, and install SDL3 (Wayland-only, Vulkan enabled, static) into ../ (thirdparty/).
# Uses Ninja if available.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="$(cd "${ROOT}/.." && pwd)"
SDL_URL="https://github.com/libsdl-org/SDL/archive/refs/tags/release-3.2.26.tar.gz"
SDL_TAR="${ROOT}/release-3.2.26.tar.gz"
SDL_SRC="${ROOT}/SDL-release-3.2.26"

if [ ! -d "${SDL_SRC}" ]; then
    echo "Fetching SDL3..."
    curl -L "${SDL_URL}" -o "${SDL_TAR}"
    tar -xzf "${SDL_TAR}" -C "${ROOT}"
fi

BUILD_DIR="${SDL_SRC}/build-vulkan"

cmake -S "${SDL_SRC}" -B "${BUILD_DIR}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DSDL_X11=OFF \
  -DSDL_WAYLAND=ON \
  -DSDL_VULKAN=ON \
  -DSDL_SHARED=OFF \
  -DSDL_STATIC=ON \
  -DSDL_INSTALL=ON \
  -DSDL_TESTS=OFF

cmake --build "${BUILD_DIR}"
cmake --install "${BUILD_DIR}"
