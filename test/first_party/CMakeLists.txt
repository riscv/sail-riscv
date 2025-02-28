
# First party tests

# TODO: Probably make these optional and off by default, but enabled in CI.
# Then it doesn't trip up people who just want the model, but it's also
# not too annoying for contributors.

find_program(CLANG_BIN "clang")
if (NOT CLANG_BIN)
    message(FATAL_ERROR "clang not found. This is required to compile the first-party tests. You can download it from https://github.com/llvm/llvm-project/releases")
endif()
message(STATUS "Found clang: ${CLANG_BIN}")

# Check it supports RISC-V. It is apparently possible to compile Clang without
# RISC-V support. For example the version Red Hat provides on RHEL 8 doesn't support it.
execute_process(
    COMMAND clang -print-targets
    OUTPUT_VARIABLE clang_targets
    COMMAND_ERROR_IS_FATAL ANY
)

# Check if `riscv32` is present in the output
if (NOT clang_targets MATCHES "riscv32")
    message(FATAL_ERROR "Your Clang compiler does not support RISC-V (see '${CLANG_BIN} -print-targets'). Please download one from https://github.com/llvm/llvm-project/releases")
endif()

set(common_deps
    "src/common/crt0.S"
    "src/common/encoding.h"
    "src/common/link.ld"
    "src/common/nanoprintf.c"
    "src/common/nanoprintf.h"
    "src/common/riscv_int.h"
    "src/common/runtime.c"
    "src/common/runtime.h"
)

set(tests
    "test_hello_world.c"
    "test_max_pmp.c"
    "test_minstret.S"
)

foreach (xlen IN ITEMS 32 64)
    foreach (test_source IN LISTS tests)
        set(arch "rv${xlen}d")
        if (xlen EQUAL 32)
            set(mabi "ilp32")
        else()
            set(mabi "lp64")
        endif()

        set(elf "${arch}_${test_source}.elf")

        add_custom_command(
            OUTPUT ${elf}
            DEPENDS ${common_deps} "src/${test_source}"
            COMMAND ${CLANG_BIN}
                --target=riscv${xlen}
                # The ISA string to compile for.
                -march=rv${xlen}gc
                # Calling convention to use. Valid values are 'ilp32' or 'lp64' for 32/64-bit,
                # optionally followed by 'f' or 'd' for hard-float. All combinations are valid.
                -mabi=${mabi}d
                # Indicate we are building in a standalone environment. Implies -fno-builtin
                # so the compiler won't assume that memcpy etc. are available.
                -ffreestanding
                # Don't try to link with libc or libc.
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

        add_custom_target(build_${arch}_${test_source} ALL DEPENDS ${elf})

        add_test(
            NAME "first_party_${arch}_${test_source}"
            COMMAND $<TARGET_FILE:riscv_sim_${arch}> --pmp-count 16 ${elf}
        )
    endforeach()
endforeach()
