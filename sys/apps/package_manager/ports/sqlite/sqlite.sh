#!/bin/bash
set -e

# SQLite database library build script
NAME="sqlite"
VERSION="3.51.0"
URL="https://sqlite.org/2025/sqlite-src-3510000.zip"
TARBALL="sqlite-src-3510000.zip"
BUILD_DIR="sqlite-src-3510000"

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure we're in the src directory
cd "$SCRIPT_DIR"

echo "[${NAME}] Downloading ${URL}..."
wget -O "${TARBALL}" "${URL}"

echo "[${NAME}] Extracting ${TARBALL}..."
unzip -q "${TARBALL}"

echo "[${NAME}] Building ${NAME} in ${SCRIPT_DIR}/${BUILD_DIR}..."
cd "${BUILD_DIR}"

# Configure SQLite with compile-time options
# JSON1, FTS5, and RTREE are enabled via CFLAGS
export CFLAGS="-DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_RTREE"

./configure \
    --prefix="${SYSTEM_DIR}" \
    --enable-shared \
    --enable-static

# Build SQLite
make -j$(nproc)

echo "[${NAME}] Installing to ${SYSTEM_DIR}..."
make install

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}"
