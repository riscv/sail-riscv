
# First party tests

# There are three options for cross-compilation of an RV32 program.
#
# 1. Clang, which is sensibly designed to be able to cross-compile to any architecture it supports.
#    Unfortunately it is possible to build it without RISC-V support, e.g. RHEL 8 does this, so we
#    need to check that. You can download a binary from https://github.com/llvm/llvm-project/releases
# 2. GCC via riscv32-unknown-elf-gcc. Unlike Clang you have to specifically build GCC as a cross
#    compiler. You can download a binary from https://github.com/riscv-collab/riscv-gnu-toolchain/releases
# 3. GCC via riscv64-unknown-elf-gcc, but only if it has "multilib" support, so we'll try riscv32-... first.

find_program(CLANG_BIN "clang")
find_program(GCC_BIN_RV32 "riscv32-unknown-elf-gcc")
find_program(GCC_BIN_RV64 "riscv64-unknown-elf-gcc")

if (CLANG_BIN)
    message(STATUS "Found clang: ${CLANG_BIN}")
endif()
if (GCC_BIN_RV32)
    message(STATUS "Found riscv32-unknown-elf-gcc: ${GCC_BIN_RV32}")
endif()
if (GCC_BIN_RV64)
    message(STATUS "Found riscv64-unknown-elf-gcc: ${GCC_BIN_RV64}")
endif()

set(CROSS_COMPILER_COMMAND_RV32)
set(CROSS_COMPILER_COMMAND_RV64)

# Prefer Clang.
if (CLANG_BIN)
    # Check it supports RISC-V.
    execute_process(
        COMMAND clang -print-targets
        OUTPUT_VARIABLE clang_targets
        COMMAND_ERROR_IS_FATAL ANY
    )

    # Check if `riscv32` is present in the output
    if (clang_targets MATCHES "riscv32")
        set(CROSS_COMPILER_COMMAND_RV32 ${CLANG_BIN} --target=riscv32)
        set(CROSS_COMPILER_COMMAND_RV64 ${CLANG_BIN} --target=riscv64)
    endif()
endif()

# Prefer riscv32-unknown-elf-gcc to riscv64-unknown-elf-gcc for RV32.
if (GCC_BIN_RV32)
    if (NOT CROSS_COMPILER_COMMAND_RV32)
        set(CROSS_COMPILER_COMMAND_RV32 ${GCC_BIN_RV32})
    endif()
endif()

if (GCC_BIN_RV64)
    if (NOT CROSS_COMPILER_COMMAND_RV32)
        # It might support multilib.
        set(CROSS_COMPILER_COMMAND_RV32 ${GCC_BIN_RV64})
    endif()
    if (NOT CROSS_COMPILER_COMMAND_RV64)
        set(CROSS_COMPILER_COMMAND_RV64 ${GCC_BIN_RV64})
    endif()
endif()

if (NOT CROSS_COMPILER_COMMAND_RV32 OR NOT CROSS_COMPILER_COMMAND_RV64)
    if (CLANG_BIN)
        message(FATAL_ERROR "Your Clang compiler does not support RISC-V (see '${CLANG_BIN} -print-targets') and another suitable cross-compiler was not found. Please download one from https://github.com/llvm/llvm-project/releases")
    else()
        message(FATAL_ERROR "No suitable cross-compiler found. We recommend downloading Clang from https://github.com/llvm/llvm-project/releases")
    endif()
endif()

message(STATUS "Compiling RV32 tests with: ${CROSS_COMPILER_COMMAND_RV32}")
message(STATUS "Compiling RV64 tests with: ${CROSS_COMPILER_COMMAND_RV64}")

set(common_deps
    "src/common/crt0.S"
    "src/common/encoding.h"
    "src/common/link.ld"
    "src/common/nanoprintf.c"
    "src/common/nanoprintf.h"
    "src/common/runtime.c"
    "src/common/runtime.h"
)

set(tests
    "test_hello_world.c"
    "test_max_pmp.c"
    "test_minstret.S"
    "test_pmp_access.c"
)


foreach (xlen IN ITEMS 32 64)
    set(arch "rv${xlen}d")
    if (xlen EQUAL 32)
        set(mabi "ilp32")
    else()
        set(mabi "lp64")
    endif()
    set(config "${CMAKE_BINARY_DIR}/config/${arch}_v256_e${xlen}.json")

    foreach (test_source IN LISTS tests)
        set(elf "${arch}_${test_source}.elf")

        add_custom_command(
            OUTPUT ${elf}
            DEPENDS ${common_deps} "src/${test_source}"
            COMMAND ${CROSS_COMPILER_COMMAND_RV${xlen}}
                # The ISA string to compile for.
                -march=rv${xlen}gc
                # Calling convention to use. Valid values are 'ilp32' or 'lp64' for 32/64-bit,
                # optionally followed by 'f' or 'd' for hard-float. All combinations are valid.
                -mabi=${mabi}d
                # Required for compatibility with old versions of LLD. Otherwise you get an error
                # "relocation R_RISCV_ALIGN requires unimplemented linker relaxation; recompile with -mno-relax"
                -mno-relax
                # Indicate we are building in a standalone environment. Implies -fno-builtin
                # so the compiler won't assume that memcpy etc. are available.
                -ffreestanding
                # Don't try to link with libc or libm.
                -nostdlib
                # Generate a statically linked binary.
                -static
                # The relocation model. This compiles the code so that it can
                # be linked at any address. This means the linker script
                # doesn't have to e.g. put all code in the first 2GB of memory.
                -mcmodel=medany
                # Generate debug info.
                -g
                # Optimise code generation for a good debugging experience.
                -Og
                # Enable warnings and upgrade them to errors.
                -Wall
                -Werror
                # The linker script.
                -T "${CMAKE_CURRENT_SOURCE_DIR}/src/common/link.ld"
                -o ${elf}
                "${CMAKE_CURRENT_SOURCE_DIR}/src/${test_source}"
                "${CMAKE_CURRENT_SOURCE_DIR}/src/common/crt0.S"
                "${CMAKE_CURRENT_SOURCE_DIR}/src/common/nanoprintf.c"
                "${CMAKE_CURRENT_SOURCE_DIR}/src/common/runtime.c"
            VERBATIM
            COMMENT "Compiling ${test_source}"
        )

        add_custom_target(build_${arch}_${test_source} ALL DEPENDS ${elf} ${config})

        add_test(
            NAME "first_party_${arch}_${test_source}"
            COMMAND $<TARGET_FILE:sail_riscv_sim> --config ${config} ${elf}
        )
    endforeach()
endforeach()
