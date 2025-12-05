#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo "Installing wlroots into local thirdparty dir"
echo "========================================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# SCRIPT_DIR = .../thirdparty/src/wlroots
THIRDPARTY_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WLROOTS_SRC_DIR="${SCRIPT_DIR}/src"
WLROOTS_BUILD_DIR="${WLROOTS_SRC_DIR}/build"

MODE="normal"
if [[ "${1-}" == "--reconfigure-only" ]]; then
    MODE="reconfigure"
    shift || true
fi

echo "SCRIPT_DIR       : ${SCRIPT_DIR}"
echo "THIRDPARTY_ROOT  : ${THIRDPARTY_ROOT}"
echo "WLROOTS_SRC_DIR  : ${WLROOTS_SRC_DIR}"
echo "WLROOTS_BUILD_DIR: ${WLROOTS_BUILD_DIR}"
echo

detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

ensure_build_deps() {
    local need_meson=0 need_ninja=0 need_glslang=0

    command -v meson >/dev/null 2>&1 || need_meson=1
    command -v ninja >/dev/null 2>&1 || need_ninja=1
    command -v glslangValidator >/dev/null 2>&1 || command -v glslang >/dev/null 2>&1 || need_glslang=1

    if [ "${need_meson}" -eq 0 ] && [ "${need_ninja}" -eq 0 ] && [ "${need_glslang}" -eq 0 ]; then
        echo "Required build tools already present (meson, ninja, glslang)."
        return 0
    fi

    local distro
    distro="$(detect_distro)"
    echo "Attempting to install missing build dependencies on ${distro}..."

    case "${distro}" in
        fedora)
            # meson, ninja, glslangValidator
            sudo dnf install -y \
                meson \
                ninja-build \
                glslang || {
                echo "Failed to install build dependencies via dnf." >&2
                exit 1
            }
            ;;
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y \
                meson \
                ninja-build \
                glslang-tools || {
                echo "Failed to install build dependencies via apt-get." >&2
                exit 1
            }
            ;;
        *)
            echo "Unknown or unsupported distro (${distro}); please install meson, ninja, and glslang manually." >&2
            ;;
    esac
}

ensure_build_deps

mkdir -p "${WLROOTS_SRC_DIR}"

if [ "${MODE}" = "normal" ]; then
    if [ ! -d "${WLROOTS_SRC_DIR}/.git" ]; then
        echo "[1/3] Cloning wlroots (main)..."
        git clone https://gitlab.freedesktop.org/wlroots/wlroots.git "${WLROOTS_SRC_DIR}"
else
    echo "wlroots source already present at ${WLROOTS_SRC_DIR}, pulling latest..."
    (
        cd "${WLROOTS_SRC_DIR}"
        git fetch origin
        if git show-ref --verify --quiet refs/remotes/origin/main; then
            # Prefer tracking the upstream main branch when available.
            git checkout main || true
            git pull --ff-only origin main || git pull --ff-only || true
        else
            # Fallback: stay on the current branch and just pull.
            git pull --ff-only || true
        fi
    )
fi
else
    if [ ! -d "${WLROOTS_SRC_DIR}/.git" ]; then
        echo "Error: wlroots source not cloned yet; cannot --reconfigure-only."
        echo "Clone first by running this script without --reconfigure-only."
        exit 1
    fi
    echo "[1/3] Reconfiguring existing wlroots source (no git update)..."
fi

echo
echo "[2/3] Configuring wlroots with Meson..."
mkdir -p "${WLROOTS_BUILD_DIR}"

(
    cd "${WLROOTS_SRC_DIR}"

    # Use meson to configure the build. We install into the Hultrix
    # thirdparty root, with libraries under lib64 and headers under
    # include/wlroots.
    if [ "${MODE}" = "normal" ]; then
        meson setup "${WLROOTS_BUILD_DIR}" . \
            --prefix="${THIRDPARTY_ROOT}" \
            --libdir=lib64 \
            --includedir=include/wlroots \
            --buildtype=release \
            -Ddefault_library=static \
            -Drenderers=gles2,vulkan \
            -Dexamples=false || meson setup --reconfigure "${WLROOTS_BUILD_DIR}" . \
            --prefix="${THIRDPARTY_ROOT}" \
            --libdir=lib64 \
            --includedir=include/wlroots \
            --buildtype=release \
            -Ddefault_library=static \
            -Drenderers=gles2,vulkan \
            -Dexamples=false
    else
        meson setup --reconfigure "${WLROOTS_BUILD_DIR}" . \
            --prefix="${THIRDPARTY_ROOT}" \
            --libdir=lib64 \
            --includedir=include/wlroots \
            --buildtype=release \
            -Ddefault_library=static \
            -Drenderers=gles2,vulkan \
            -Dexamples=false
    fi
)

echo
echo "[3/3] Building and installing wlroots..."
(
    cd "${WLROOTS_SRC_DIR}"
    ninja -C "${WLROOTS_BUILD_DIR}"
    ninja -C "${WLROOTS_BUILD_DIR}" install
)

echo
echo "wlroots build and install complete."
echo "  Libraries installed under: ${THIRDPARTY_ROOT}/lib64"
echo "  Headers installed under  : ${THIRDPARTY_ROOT}/include/wlroots"
echo "  Build tree (for libwlroots-*.so, etc.): ${WLROOTS_BUILD_DIR}"
echo
