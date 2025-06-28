# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

SAIL RISC-V is the formal specification of the RISC-V architecture written in Sail, a domain-specific language for describing instruction-set architectures. The model generates executable C emulators and theorem prover definitions.

## Essential Commands

### Building
```bash
# Quick build (recommended)
./build_simulators.sh

# Manual CMake build
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build -j$(nproc)

# Rebuild after modifying Sail files
cmake --build build --target generated_sail_riscv_model
```

### Running Tests
```bash
# Run all tests
cd build && ctest

# Run specific test suite
cd build && ctest -R rv64ui

# Run single test manually
./build/c_emulator/sail_riscv_sim test/riscv-tests/rv64ui-p-add.elf

# Debug with traces
./build/c_emulator/sail_riscv_sim -v instr,reg test.elf
```

### Common Development Tasks
```bash
# Validate configuration file
./build/c_emulator/sail_riscv_sim --validate-config --config myconfig.json

# Generate device tree
./build/c_emulator/sail_riscv_sim --print-dts

# Run with instruction limit
./build/c_emulator/sail_riscv_sim -l 1000000 test.elf
```

## Architecture Overview

### Key Directories
- `model/`: Sail specification files (core RISC-V model)
- `c_emulator/`: C emulator runtime and platform code
- `config/`: JSON configuration files for different RISC-V variants
- `test/`: Test binaries and infrastructure
- `handwritten_support/`: Theorem prover support files

### Model Structure (in dependency order)
1. **Type definitions** (`riscv_types.sail`): Privilege levels, exceptions, memory access types
2. **Registers** (`riscv_regs.sail`, `riscv_sys_regs.sail`): Register files and CSRs
3. **Memory** (`riscv_mem.sail`, `riscv_vmem*.sail`): Physical and virtual memory
4. **Instructions** (`riscv_insts_*.sail`): Instruction definitions by extension
5. **Execution** (`riscv_step.sail`): Fetch-decode-execute loop

### Configuration System
The model uses JSON configuration files to specify:
- Base architecture (XLEN, MISA writability)
- Memory system parameters
- Platform details (RAM/ROM layout, reset vector)
- Supported extensions (M, A, F, D, V, B, etc.)

Example minimal config:
```json
{
  "base": { "xlen": 64 },
  "platform": {
    "ram": { "base": 0x80000000, "size": 0x80000000 },
    "reset_vector": 0x1000
  },
  "extensions": {
    "M": { "supported": true }
  }
}
```

### Adding New Instructions
1. Add to appropriate `riscv_insts_*.sail` file
2. Define:
   - AST clause
   - Encoding/decoding mapping
   - Execution semantics
   - Assembly format
3. Rebuild and test

### Debugging Execution
- All traces: `-v all`
- Specific traces: `-v instr,reg`
- RVFI mode: `--enable-rvfi`
- Timing info: `-T`

## Important Notes
- Each ISA extension is modular (separate files)
- Architecture width/features selected at compile time via config files
- Supports both sequential and relaxed memory models
- Clean separation between ISA specification and platform devices
- Tests communicate success/failure via the `tohost` symbol