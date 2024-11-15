#!/bin/bash

set -e
: "${DOWNLOAD_GMP:=TRUE}"
: "${RVE:=FALSE}"
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DDOWNLOAD_GMP="${DOWNLOAD_GMP}" -DRVE="${RVE}"
jobs=$( (nproc || sysctl -n hw.ncpu || echo 2) 2>/dev/null)
cmake --build build -j${jobs}
