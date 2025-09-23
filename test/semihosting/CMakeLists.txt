# RISC-V Semihosting tests

# ubuntu riscv64-unknown-elf-gcc have multilib support, and it doesn't provide riscv32-unknown-elf-gcc package, so we use riscv64-unknown-elf-gcc here
find_program(GCC_BIN_RV32 "riscv64-unknown-elf-gcc")
find_program(GCC_BIN_RV64 "riscv64-unknown-elf-gcc")

if(GCC_BIN_RV32)
    message(STATUS "Found riscv32-unknown-elf-gcc: ${GCC_BIN_RV32}")
else()
    message(FATAL_ERROR "riscv32-unknown-elf-gcc not found")
endif()
if(GCC_BIN_RV64)
    message(STATUS "Found riscv64-unknown-elf-gcc: ${GCC_BIN_RV64}")
else()
    message(FATAL_ERROR "riscv64-unknown-elf-gcc not found")
endif()

set(SEMIHOSTING_CROSS_COMPILER_COMMAND_RV32 ${GCC_BIN_RV64})
set(SEMIHOSTING_CROSS_COMPILER_COMMAND_RV64 ${GCC_BIN_RV64})

# On macOS, use lld instead of the system linker which does not support ELF
if(APPLE)
    set(SEMIHOSTING_CROSS_COMPILER_COMMAND_RV32
        ${SEMIHOSTING_CROSS_COMPILER_COMMAND_RV32} -fuse-ld=lld)
    set(SEMIHOSTING_CROSS_COMPILER_COMMAND_RV64
        ${SEMIHOSTING_CROSS_COMPILER_COMMAND_RV64} -fuse-ld=lld)
endif()

message(STATUS "Compiling RV32 tests with: ${CROSS_COMPILER_COMMAND_RV32}")
message(STATUS "Compiling RV64 tests with: ${CROSS_COMPILER_COMMAND_RV64}")

option(DOWNLOAD_PICOLIBC "Download picolibc and build the library locally instead of using a system installation" OFF)
if (DOWNLOAD_PICOLIBC)
    include(ExternalProject)
    ExternalProject_Add(
        picolibc
        URL https://github.com/picolibc/picolibc/releases/download/1.8.10/picolibc-1.8.10.tar.xz
        URL_HASH SHA256=0ce5ee3bde81256633644d7b3bd25f5a6ccfd8b0590fd4ee543df2c3ede6e27e
        BUILD_IN_SOURCE 0
        INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/picolibc-install"
        CONFIGURE_COMMAND <SOURCE_DIR>/scripts/do-riscv-configure --prefix=<INSTALL_DIR> -Dsemihost=true
        BUILD_COMMAND ninja
        INSTALL_COMMAND sudo ninja install
    )
endif()

set(tests
  "exit.c"
  "hello_world.c"
  "args.c"
  # "read_write_char.c"
  "file.c"
)

foreach(xlen IN ITEMS 32 64)
    set(arch "rv${xlen}d")
    if(xlen EQUAL 32)
        set(mabi "ilp32")
    else()
        set(mabi "lp64")
    endif()
    set(config "${CMAKE_BINARY_DIR}/config/${arch}_v256_e${xlen}.json")

    foreach(test_source IN LISTS tests)
        set(elf "${arch}_${test_source}.elf")

        add_custom_command(
            OUTPUT ${elf}
            DEPENDS ${common_deps} "src/${test_source}"
            COMMAND
                ${SEMIHOSTING_CROSS_COMPILER_COMMAND_RV${xlen}}
                # The ISA string to compile for.
                -march=rv${xlen}imac
                # Calling convention to use. Valid values are 'ilp32' or 'lp64' for
                # 32/64-bit, optionally followed by 'f' or 'd' for hard-float. Not all
                # combinations are supported by picolibc. You should check the picolibc
                # document for your target.
                -mabi=${mabi}
                # Link against the picolibc library.
                --specs=picolibc.specs
                # Picolibc distributes the semihosting implementation as a separate
                # library, libsemihost.a. Because it provides interfaces that are used
                # by libc itself, it must be included in the linker command line after
                # libc. You can do this by using the GCC --oslib=semihost command line
                # flag defined by picolibc.specs:
                --oslib=semihost
                # The default crt0 version provided by Picolibc calls any constructors
                # before it calls main and then goes into an infinite loop after main
                # returns. To avoid requiring an exit function, applications could use
                # the crt0-semihost variant that calls exit when main returns
                --crt0=semihost
                # Generate a statically linked binary.
                -static
                # The relocation model. This compiles the code so that it can be linked
                # at any address. This means the linker script doesn't have to e.g. put
                # all code in the first 2GB of memory.
                -mcmodel=medany
                # Generate debug info.
                -g
                # Optimise code generation for a good debugging experience.
                -Og
                # Enable warnings and upgrade them to errors.
                -Wall -Werror -o ${elf} "${CMAKE_CURRENT_SOURCE_DIR}/src/${test_source}"
            VERBATIM
            COMMENT "Compiling ${test_source}"
        )

        add_custom_target(build_semihosting_${arch}_${test_source} ALL
                          DEPENDS ${elf} ${config})
        if (DOWNLOAD_PICOLIBC)
            add_dependencies(build_semihosting_${arch}_${test_source} picolibc)
        endif()

        add_test(NAME "semihosting_${arch}_${test_source}"
                COMMAND $<TARGET_FILE:sail_riscv_sim> --config ${config}
                        --enable-semihosting ${elf})
    endforeach()
endforeach()
