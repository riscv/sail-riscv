#!/bin/sh
# =======================================================================================
# This Sail RISC-V architecture model, comprising all files and
# directories except where otherwise noted is subject the BSD
# two-clause license in the LICENSE file.
#
# SPDX-License-Identifier: BSD-2-Clause
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# =======================================================================================

# Build the simulator with profile-guided optimization (PGO).
# Builds an instrumented simulator, runs every 10th test to collect a profile,
# then builds again using that profile. Both builds use the same directory, so
# Sail runs only a single time. Arguments are passed directly through to CMake.

set -e
: "${DOWNLOAD_GMP:=TRUE}"
profile_dir="$(pwd)/build/pgo-profile"
jobs=$( (nproc || sysctl -n hw.ncpu || echo 2) 2>/dev/null)

# Build instrumented simulator in the build directory. All tests are enabled so a wide
# variety of programs can be used for profiling.
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DDOWNLOAD_GMP="${DOWNLOAD_GMP}" \
  -DENABLE_RISCV_TESTS=TRUE -DENABLE_RISCV_ARCH_TESTS=TRUE -DENABLE_DAMO_TESTS=TRUE \
  -DENABLE_RISCV_VECTOR_TESTS_V64_E64=TRUE -DENABLE_RISCV_VECTOR_TESTS_V128_E32=TRUE -DFIRST_PARTY_TESTS=TRUE \
  -DENABLE_LTO=TRUE -DPGO_GENERATE=ON -DPGO_PROFILE= -DPGO_PROFILE_DIR="${profile_dir}" "$@"
cmake --build build -j"${jobs}"

# Generate profile
rm -rf "${profile_dir}"
ctest --test-dir build -j"${jobs}" -I 1,,10 # Run every 10th test

# Clang writes raw profiles that must be merged before use. GCC uses the directory as is.
if ls "${profile_dir}"/*.profraw > /dev/null 2>&1; then
  # Use the llvm-profdata of the compiler. AppleClang has it only through xcrun.
  cxx=$(sed -n 's/^CMAKE_CXX_COMPILER:[A-Z]*=//p' build/CMakeCache.txt)
  profdata=$("${cxx}" -print-prog-name=llvm-profdata)
  if ! command -v "${profdata}" > /dev/null; then
    profdata=$(xcrun -f llvm-profdata)
  fi
  "${profdata}" merge -o "${profile_dir}/merged.profdata" "${profile_dir}"/*.profraw
  profile="${profile_dir}/merged.profdata"
elif [ -n "$(ls -A "${profile_dir}" 2>/dev/null)" ]; then
  profile="${profile_dir}"
else
  echo "error: no PGO profile in ${profile_dir}" >&2
  exit 1
fi

# Build final simulator using generated profile
cmake -B build -DPGO_GENERATE=OFF -DPGO_PROFILE="${profile}"
cmake --build build -j"${jobs}"
