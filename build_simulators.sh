#!/bin/sh

set -e
: "${DOWNLOAD_GMP:=TRUE}"
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DDOWNLOAD_GMP="${DOWNLOAD_GMP}" -DENABLE_RISCV_VECTOR_TESTS_V256_E32=TRUE
jobs=$( (nproc || sysctl -n hw.ncpu || echo 2) 2>/dev/null)
cmake --build build -j${jobs}
