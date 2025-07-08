#!/bin/sh

set -e
: "${DOWNLOAD_GMP:=TRUE}"
: "${ENABLE_RISCV_TESTS:=TRUE}"
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DDOWNLOAD_GMP="${DOWNLOAD_GMP}" -DENABLE_RISCV_TESTS="${ENABLE_RISCV_TESTS}"
jobs=$( (nproc || sysctl -n hw.ncpu || echo 2) 2>/dev/null)
cmake --build build -j${jobs}
