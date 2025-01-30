cmake_minimum_required(VERSION 3.20)

project(sail_riscv)

# Make users explicitly pick a build type so they don't get
# surprised when the default gives a very slow emulator.
if (NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(FATAL_ERROR "
No build type selected. You need to pass -DCMAKE_BUILD_TYPE=<type> in order to configure the build.
    * -DCMAKE_BUILD_TYPE=Release        - Optimized build with no debug info.
    * -DCMAKE_BUILD_TYPE=RelWithDebInfo - Optimized build with debug info.
    * -DCMAKE_BUILD_TYPE=Debug          - Unoptimized build with debug info.
    * -DCMAKE_BUILD_TYPE=MinSizeRel     - Optimized for size instead of speed.")
endif()

# Enable CTest
enable_testing()

# Export compile_commands.json for IDE support.
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

# Always use Position Independent Code. By default it is only used for
# shared libraries (which require it), but you also need it for static
# libraries if you link them into shared libraries.
# Generally it just simplifies everything for a negligable performance cost.
set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)

# Don't allow undefined symbols. This is generally a pain.
include(CheckLinkerFlag)

check_linker_flag(C "-Wl,--no-undefined" LINKER_SUPPORTS_NO_UNDEFINED)
if (LINKER_SUPPORTS_NO_UNDEFINED)
    add_link_options("-Wl,--no-undefined")
endif()

# Extra CMake files.
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

# These are the main requirements.
# Don't use `REQUIRED` so that we can print custom help messages.
find_package(ZLIB)
if (NOT ZLIB_FOUND)
    if (APPLE)
        message(FATAL_ERROR "Zlib not found. Try 'brew install zlib'.")
    elseif (UNIX)
        message(FATAL_ERROR "Zlib not found. Try 'sudo apt install zlib1g-dev' or 'sudo dnf install zlib-devel'.")
    else()
        message(FATAL_ERROR "Zlib not found.")
    endif()
endif()

find_package(GMP)
if (NOT GMP_FOUND)
    if (APPLE)
        message(FATAL_ERROR "GMP not found. Try 'brew install gmp'.")
    elseif (UNIX)
        message(FATAL_ERROR "GMP not found. Try 'sudo apt install libgmp-dev' or 'sudo dnf install gmp-devel'.")
    else()
        message(FATAL_ERROR "GMP not found.")
    endif()
endif()

find_program(SAIL_BIN "sail")
if (NOT SAIL_BIN)
    message(FATAL_ERROR "Sail not found. See README.md for installation instructions.")
endif()

set(DEFAULT_ARCHITECTURES "rv32d;rv64d" CACHE STRING "Architectures to build by default (rv32f|rv64f|rv32d|rv64d)(_rvfi)? " )

option(COVERAGE "Compile with Sail coverage collection enabled.")

# Softfloat support.
add_subdirectory("dependencies/softfloat")

# Sail C runtime.
add_subdirectory("sail_runtime")

# Sail model generated C code.
add_subdirectory("model")

# Emulator binary.
add_subdirectory("c_emulator")

# Old pre-compiled riscv-tests.
add_subdirectory("test/riscv-tests")

# Convenience targets.
add_custom_target(csim DEPENDS riscv_sim_rv32d riscv_sim_rv64d)
add_custom_target(check DEPENDS generated_model_rv32d generated_model_rv64d)

# TODO: Support static linking.
# TODO: Add `interpret` target.
# TODO: Add isabelle target.
# TODO: Add lem target.
# TODO: Add hol4 target.
