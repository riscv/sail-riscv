#!/bin/bash

mkdir -p build

sail --project model/riscv.sail_project --variable ARCH=RV64 --lean --config config/rv64im.config.json --lean-import-file handwritten_support/RiscvExtrasExecutable.lean --lean-output-dir build/ -o Lean_RV64IM --lean-force-output I M riscv_postlude
