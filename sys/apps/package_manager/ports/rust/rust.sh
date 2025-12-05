#!/bin/bash
set -e

# Rust programming language build script
NAME="rust"
VERSION="1.91.1"
URL="https://github.com/rust-lang/rust/archive/refs/tags/${VERSION}.tar.gz"
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

# Create config.toml for Rust build
cat > config.toml << EOF
[llvm]
download-ci-llvm = false
link-shared = true

[build]
target = ["x86_64-unknown-linux-gnu"]
docs = false
extended = true
tools = ["cargo", "clippy", "rustfmt"]

[install]
prefix = "${SYSTEM_DIR}"

[rust]
channel = "stable"
EOF

# Configure and build Rust
python3 x.py build --stage 2

echo "[${NAME}] Installing to ${SYSTEM_DIR}..."
python3 x.py install

echo "[${NAME}] Cleaning up build artifacts from ${SCRIPT_DIR}..."
cd "${SCRIPT_DIR}"
rm -rf "${BUILD_DIR}" "${TARBALL}"

echo "[${NAME}] Build complete!"
echo "[${NAME}] Installed to: ${SYSTEM_DIR}"
