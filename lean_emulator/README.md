# Lean emulator for Sail RISC-V

## Instructions

1. Compile the Sail RISC-V model for Lean which is a dependency for the Lean emulator. Here's an example command to build the Lean backend (from the root directory). You may want to change the set of modules and extensions that are included in your version of the emulator.

```
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DSAIL_MODULES="H;Zca;Zicbom_insts;Zicboz;Zicsr_insts;Zkr;postlude" && cmake --build build --target generated_lean_executable_rv64d
```

2. Compile the Lean emulator.

```
lake update && lake build
```

3. Run the Lean emulator on an ELF binary.

```
lake exec lean_riscv_emulator -- path/to/riscv/binary.elf
```

You can download the Spike test ELFs by running the following in the `/test` directory.

```
cmake -S . -B build -DENABLE_RISCV_TESTS=1 && cmake --build build
```
