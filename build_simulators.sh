#!/bin/bash

set -e
: "${DOWNLOAD_GMP:=TRUE}"
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DDOWNLOAD_GMP="${DOWNLOAD_GMP}"
cmake --build build -j2
