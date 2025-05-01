cmake_minimum_required(VERSION 3.20)
cmake_policy(VERSION 3.20...3.31)

project(sail_riscv)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)
set(SAIL_REQUIRED_VER 0.19)

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
# Generally it just simplifies everything for a negligible performance cost.
set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)

# Don't allow undefined symbols. This is generally a pain.
include(CheckLinkerFlag)

check_linker_flag(C "-Wl,--no-undefined" LINKER_SUPPORTS_NO_UNDEFINED)
if (LINKER_SUPPORTS_NO_UNDEFINED)
    add_link_options("-Wl,--no-undefined")
endif()

add_compile_options(-Wall -Wextra -Wno-sign-compare)
include(CheckCCompilerFlag)
check_c_compiler_flag(-Wself-assign HAVE_WSELF_ASSIGN)
check_c_compiler_flag(-Wimplicit-fallthrough HAVE_WIMPLICIT_FALLTHROUGH)

# Extra CMake files.
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

# This will change how the `find_library` calls work so they find
# the static version of libraries first. Unlike `-static` it won't
# link glibc statically, which is generally considered to be a bad idea.
option(STATIC "Prefer static versions of dependencies.")

if (STATIC)
    if (WIN32)
        list(INSERT CMAKE_FIND_LIBRARY_SUFFIXES 0 .lib .a)
    else()
        set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
        check_linker_flag(CXX "-static-libstdc++" HAVE_STATIC_LIBSTDCXX)
        if (NOT HAVE_STATIC_LIBSTDCXX)
            message(FATAL_ERROR "Building with -DSTATIC=TRUE requires static C++ std library installation")
        endif()
        add_link_options(-static-libstdc++)
        check_linker_flag(CXX "-static-libgcc" HAVE_STATIC_LIBGCC)
        if (NOT HAVE_STATIC_LIBGCC)
            message(FATAL_ERROR "Building with -DSTATIC=TRUE requires static libgcc installation")
        endif()
        add_link_options(-static-libgcc)
    endif()
endif()


# These are the main requirements.
# Don't use `REQUIRED` so that we can print custom help messages.
option(DOWNLOAD_GMP "Download libgmp and build the library locally instead of using a system installation" OFF)
if (DOWNLOAD_GMP)
    include(ExternalProject)
    ExternalProject_Add(
        gmp
        URL https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz https://ftpmirror.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
        URL_HASH SHA256=a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898
        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/gmp
        CONFIGURE_COMMAND "<SOURCE_DIR>/configure" "--prefix=<INSTALL_DIR>" --disable-shared --enable-static
        # The libgmp.a output is created by the install step but since GMP::GMP
        # depends on the entire ExternalProject build, we can pretend it is
        # created by the build.
        # TODO: Once we depend on CMake 3.26, use INSTALL_BYPRODUCTS
        BUILD_BYPRODUCTS "<INSTALL_DIR>/lib/libgmp.a"
    )
    ExternalProject_Get_property(gmp INSTALL_DIR)
    add_library(GMP::GMP STATIC IMPORTED GLOBAL)
    # Work around `Imported target "GMP::GMP" includes non-existent path`.
    # See https://gitlab.kitware.com/cmake/cmake/-/issues/15052
    file(MAKE_DIRECTORY ${INSTALL_DIR}/include)
    set_target_properties(GMP::GMP PROPERTIES
            IMPORTED_LOCATION "${INSTALL_DIR}/lib/libgmp.a"
            INTERFACE_INCLUDE_DIRECTORIES "${INSTALL_DIR}/include")
    add_dependencies(GMP::GMP gmp)
else()
    find_package(GMP)
    if (NOT GMP_FOUND)
        set(download_gmp "setting -DDOWNLOAD_GMP=TRUE to use a local build of GMP instead of a system library")
        if (APPLE)
            message(FATAL_ERROR "GMP not found. Try 'brew install gmp' or ${download_gmp}.")
        elseif (UNIX)
            message(FATAL_ERROR "GMP not found. Try 'sudo apt install libgmp-dev' or 'sudo dnf install gmp-devel' or ${download_gmp}.")
        else()
            message(FATAL_ERROR "GMP not found. Try ${download_gmp}")
        endif()
    endif()
endif()

find_program(SAIL_BIN "sail")
if (NOT SAIL_BIN)
    message(FATAL_ERROR "Sail not found. See README.md for installation instructions.")
endif()
message(STATUS "Found sail: ${SAIL_BIN}")

# Set sail_dir to Sail's library directory for use in build rules
execute_process(
    COMMAND ${SAIL_BIN} --dir
    OUTPUT_VARIABLE sail_dir
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)
message(STATUS "Sail library directory: ${sail_dir}")

set(DEFAULT_ARCHITECTURES "rv32d;rv64d" CACHE STRING "Architectures to build by default (rv32f|rv64f|rv32d|rv64d)? " )

option(COVERAGE "Compile with Sail coverage collection enabled.")

# Softfloat support.
add_subdirectory("dependencies/softfloat")

# Sail C runtime.
add_subdirectory("sail_runtime")

# Sail configuration
add_subdirectory("config")

# Sail model generated C code.
add_subdirectory("model")

# Emulator binary.
add_subdirectory("c_emulator")

# Old pre-compiled riscv-tests & first-party tests.
add_subdirectory("test")

# Handwritten support files for provers
add_subdirectory("handwritten_support")

# Release packaging.
if (NOT CPACK_GENERATOR)
    if (WINDOWS)
        set(CPACK_GENERATOR "ZIP")
    else()
        set(CPACK_GENERATOR "TGZ")
    endif()
endif()
if (DARWIN)
    # ${CMAKE_SYSTEM_NAME} is unfortunately "Darwin", but we want "Mac".
    set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-Mac-${CMAKE_HOST_SYSTEM_PROCESSOR}")
else()
    set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CMAKE_SYSTEM_NAME}-${CMAKE_HOST_SYSTEM_PROCESSOR}")
endif()
include(CPack)

# Convenience targets.
add_custom_target(csim DEPENDS riscv_sim_rv32d riscv_sim_rv64d)
add_custom_target(check DEPENDS generated_model_rv32d generated_model_rv64d)

# TODO: Add `interpret` target.
# TODO: Add hol4 target.
