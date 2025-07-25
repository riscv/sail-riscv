## Test Suites

The simulator supports multiple test suites that are downloaded on-demand during the CMake configure step:

- **Standard RISC-V Tests** from the [`riscv-tests`](https://github.com/riscv-software-src/riscv-tests) repository: Basic pre-compiled ELFs with fundamental ISA tests. Enabled by default (can be disabled with `-DENABLE_RISCV_TESTS=OFF`). Precompiled binaries are downloaded from [sail-riscv-tests releases](https://github.com/riscv-software-src/sail-riscv-tests/releases/).

- **RISC-V Vector Extension Tests** from the [`riscv-vector-tests`](https://github.com/chipsalliance/riscv-vector-tests) repository: Comprehensive vector extension tests enabled with CMake options like `-DENABLE_RISCV_VECTOR_TESTS_V256_E32=ON` for specific VLEN/ELEN configurations (supported combinations: V128_E32, V128_E64, V256_E32, V256_E64, V512_E32, V512_E64). Precompiled binaries are downloaded from [sail-riscv-tests releases](https://github.com/riscv-software-src/sail-riscv-tests/releases).

## Local Test Directory

- `first_party` - tests specifically designed for this Sail model. These tests are not designed to test all the features of RISC-V. Rather they are for testing new code that we add, and bug fixes.
