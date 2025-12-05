#!/usr/bin/env bash

set -euo pipefail

echo "=========================================="
echo "Installing Poco into local thirdparty dir"
echo "=========================================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THIRDPARTY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALL_PREFIX="${THIRDPARTY_ROOT}"
POCO_SRC_DIR="${SCRIPT_DIR}/poco"
POCO_BUILD_DIR="${THIRDPARTY_ROOT}/build-poco"

echo "SCRIPT_DIR       : ${SCRIPT_DIR}"
echo "THIRDPARTY_ROOT  : ${THIRDPARTY_ROOT}"
echo "POCO_SRC_DIR     : ${POCO_SRC_DIR}"
echo "POCO_BUILD_DIR   : ${POCO_BUILD_DIR}"
echo "INSTALL_PREFIX   : ${INSTALL_PREFIX}"
echo

mkdir -p "${POCO_SRC_DIR}" "${POCO_BUILD_DIR}"

if [ ! -d "${POCO_SRC_DIR}/.git" ]; then
    echo "[1/3] Cloning Poco..."
    git clone https://github.com/pocoproject/poco.git "${POCO_SRC_DIR}"
else
    echo "Poco already cloned at ${POCO_SRC_DIR}, pulling latest..."
    (cd "${POCO_SRC_DIR}" && git pull --ff-only)
fi

echo
echo "[2/3] Configuring Poco (CMake)..."
(
    cd "${POCO_BUILD_DIR}"
    cmake "${POCO_SRC_DIR}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}"
)

echo
echo "[3/3] Building and installing Poco..."
(
    cd "${POCO_BUILD_DIR}"
    cmake --build . --config Release --target install
)

echo
echo "Poco installation complete."
echo "Installed files are under:"
echo "  ${INSTALL_PREFIX}"
echo
echo "Make sure to add '${INSTALL_PREFIX}' to your CMake search paths (e.g. CMAKE_PREFIX_PATH)."

