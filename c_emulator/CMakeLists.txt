# Extract version and build info.
execute_process(
    COMMAND ${SAIL_BIN} --version
    OUTPUT_VARIABLE sail_version
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)
message(STATUS "Sail version: ${sail_version}")

# The --version is is usually a multiline output; the first line is the most useful.
execute_process(
    COMMAND ${CMAKE_CXX_COMPILER} --version
    OUTPUT_VARIABLE compiler_version_blob
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)
string(REGEX MATCH "[^\n\r]*" cxx_compiler_version ${compiler_version_blob})
message(STATUS "CXX compiler version: ${cxx_compiler_version}")

# make version available to emulator
configure_file(sail_riscv_version.cpp.in sail_riscv_version.cpp @ONLY)

## A library that contains the C model and support code.

add_library(riscv_model
    elf_loader.cpp
    elf_loader.h
    riscv_callbacks.cpp
    riscv_callbacks.h
    riscv_callbacks_if.h
    riscv_config.h
    riscv_platform.cpp
    riscv_platform.h
    riscv_platform_impl.cpp
    riscv_platform_impl.h
    riscv_prelude.cpp
    riscv_prelude.h
    riscv_sail.h
    riscv_softfloat.cpp
    riscv_softfloat.h
    config_utils.cpp
    config_utils.h
    symbol_table.cpp
    symbol_table.h
    sail_riscv_version.h
    "${CMAKE_CURRENT_BINARY_DIR}/sail_riscv_version.cpp"
    "${CMAKE_BINARY_DIR}/sail_riscv_model.c"
    "${CMAKE_BINARY_DIR}/sail_riscv_model.h"
)

target_include_directories(riscv_model
    PUBLIC
        # So the generated C can find riscv_platform/prelude.h"
        "${CMAKE_CURRENT_SOURCE_DIR}"
        # So `riscv_sail.h` can find `sail_riscv_model.h`.
        "${CMAKE_BINARY_DIR}"
)

target_link_libraries(riscv_model
    PUBLIC elfio softfloat sail_runtime
)

add_dependencies(riscv_model generated_sail_riscv_model)

## A binary that can load an ELF file into the model and run it.

add_executable(sail_riscv_sim
    riscv_sim.cpp
    rvfi_dii.cpp
    rvfi_dii.h
    riscv_callbacks_log.cpp
    riscv_callbacks_log.h
    riscv_callbacks_rvfi.cpp
    riscv_callbacks_rvfi.h
)

# The generated C model is not warnings-clean, silence them.
set(_generated_c_warning_opt_out
    -Wno-extra
    -Wno-unused
    -Wno-uninitialized
)
set_source_files_properties(
    "${CMAKE_BINARY_DIR}/sail_riscv_model.c"
    "${CMAKE_BINARY_DIR}/sail_riscv_model.h"
    PROPERTIES COMPILE_OPTIONS "${_generated_c_warning_opt_out}"
)

add_dependencies(sail_riscv_sim generated_sail_riscv_model)

target_link_libraries(sail_riscv_sim
    PRIVATE CLI11 riscv_model default_config
)

# TODO: Enable warnings when we use the #include trick
# to include the generated Sail code. Currently it
# generates too many warnings to turn these on globally.

# target_compile_options(sail_riscv_sim PRIVATE
#     -Wall -Wextra
#     # Too annoying at the moment.
#     -Wno-unused-parameter
# )

# Enable Sail coverage collection.
if (COVERAGE)
    target_compile_definitions(sail_riscv_sim
        PRIVATE "SAILCOV"
    )
endif()

install(TARGETS sail_riscv_sim
    RUNTIME DESTINATION "bin"
)
