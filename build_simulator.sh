#!/bin/bash
set -euo pipefail

# 1. Dependency Verification
# We use 'command -v' to check if cmake exists - POSIX standard (IEEE 1003.1)
if ! command -v cmake >/dev/null 2>&1; then
    echo "Error: 'cmake' is not installed or not in your PATH." >&2
    echo "Please install CMake (https://cmake.org/download/) and try again." >&2
    exit 1
fi

# Default values
: "${DOWNLOAD_GMP:=TRUE}"
: "${ENABLE_RISCV_TESTS:=TRUE}"
: "${BUILD_TYPE:=RelWithDebInfo}"
: "${BUILD_DIR:=build}"

# 2. Configuration
echo "Configuring build in '${BUILD_DIR}'..."
cmake -S . -B "${BUILD_DIR}" \
      -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
      -DDOWNLOAD_GMP="${DOWNLOAD_GMP}" \
      -DENABLE_RISCV_TESTS="${ENABLE_RISCV_TESTS}" \
      "$@"

# 3. Build
echo "Building project..."
cmake --build "${BUILD_DIR}" --parallel
