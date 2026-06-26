# Lean emulator for Sail RISC-V

## Instructions

1. Compile the Sail RISC-V model for Lean which is a dependency for the Lean emulator. Here's an example command to build the Lean backend (from the root directory). You may want to change the set of modules and extensions that are included in your version of the emulator.

```
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DSAIL_MODULES="H;Zca;Zicbom_insts;Zicboz;Zicsr_insts;Zkr;postlude" -DENABLE_LEAN_EMULATOR_TESTS=TRUE
```

2. Compile the Lean emulator

Either, in this directory:

```
lake update && lake build
```

or with CMake:

```
cmake --build build --target build_lean_emulator
```

3. Run the Lean emulator on an ELF binary.

```
lake exec lean_riscv_emulator -- path/to/riscv/binary.elf
```

You can test the emulator with the `riscv-test` suite by running the following

```
ctest --test-dir build -R lean_emulator
```
