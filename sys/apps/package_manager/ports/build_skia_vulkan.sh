#!/usr/bin/env bash
set -euo pipefail

# Download, build, and place Skia Vulkan artifacts under thirdparty/src/skia/out/vulkan.
# Requires depot_tools in PATH.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPOT_TOOLS_DIR="${ROOT}/depot_tools"
SKIA_DIR="${ROOT}/skia"
OUT_DIR="${SKIA_DIR}/out/vulkan"
INSTALL_LIB_DIR="${ROOT}/../lib64"
INSTALL_INCLUDE_DIR="${ROOT}/../include/skia"

# Ensure depot_tools is available for gn/ninja
if [ ! -d "${DEPOT_TOOLS_DIR}" ]; then
    echo "Cloning depot_tools..."
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "${DEPOT_TOOLS_DIR}"
fi
export PATH="${DEPOT_TOOLS_DIR}:${PATH}"
if [ ! -f "${DEPOT_TOOLS_DIR}/python3_bin_reldir.txt" ]; then
    echo "Bootstrapping depot_tools python..."
    (cd "${DEPOT_TOOLS_DIR}" && ./ensure_bootstrap)
fi

# Fetch Skia if missing
if [ ! -d "${SKIA_DIR}" ]; then
    echo "Cloning Skia..."
    git clone https://skia.googlesource.com/skia "${SKIA_DIR}"
    (cd "${SKIA_DIR}" && python3 tools/git-sync-deps)
fi

cd "${SKIA_DIR}"

gn gen "${OUT_DIR}" --args='
  is_official_build=true
  skia_enable_gpu=true
  skia_use_vulkan=true
  skia_use_gl=false
  skia_use_direct3d=false
  skia_use_metal=false
  skia_use_system_freetype2=false
  skia_use_system_icu=false
  is_debug=false
  skia_enable_skottie=true
  skia_enable_svg=true
'

ninja -C "${OUT_DIR}" skia

mkdir -p "${INSTALL_LIB_DIR}" "${INSTALL_INCLUDE_DIR}/include"
cp -u "${OUT_DIR}/"*.a "${INSTALL_LIB_DIR}/"
rsync -a --delete "${SKIA_DIR}/include/" "${INSTALL_INCLUDE_DIR}/include/"
# Install headers from modules that core headers depend on (e.g. skcms).
rsync -a --delete "${SKIA_DIR}/modules/skcms" "${INSTALL_INCLUDE_DIR}/modules/"

echo "Skia Vulkan build output at ${OUT_DIR}"
