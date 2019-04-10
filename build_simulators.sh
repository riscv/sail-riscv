#!/bin/bash

make ARCH=RV32 ocaml_emulator/riscv_ocaml_sim_RV32
make ARCH=RV64 ocaml_emulator/riscv_ocaml_sim_RV64

make ARCH=RV32 c_emulator/riscv_sim_RV32
make ARCH=RV64 c_emulator/riscv_sim_RV64

