add_subdirectory("riscv-tests")

# First party test.

# TODO: Probably make these optional and off by default, but enabled in CI.
# Then it doesn't trip up people who just want the model, but it's also
# not too annoying for contributors.

find_program(ZIG_BIN "zig")
if (NOT ZIG_BIN)
    # TODO: Add instructions. This is just download, untar, add to PATH.
    # It's small enough that we could off an option to do it automatically like we do for GMP.
    message(FATAL_ERROR "zig not found. Download ...")
endif()
message(STATUS "Found zig: ${ZIG_BIN}")

# This will always run zig build, but nop builds are extremely fast (a few ms)
# so we don't need to have CMake track dependencies too.
add_custom_target(first_party_tests ALL
    ${ZIG_BIN} build --release=safe
                     --prefix "${CMAKE_CURRENT_BINARY_DIR}/zig-out"
                     --cache-dir "${CMAKE_CURRENT_BINARY_DIR}/.zig-cache"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/first_party"
    VERBATIM
)

foreach (test_name IN ITEMS test_hello_world test_max_pmp)
    # TODO: Build RV64 versions too.
    add_test(
        NAME "first_party_rv32d_${test_name}"
        COMMAND $<TARGET_FILE:riscv_sim_rv32d> --pmp-count 16 "${CMAKE_CURRENT_BINARY_DIR}/zig-out/bin/${test_name}.elf"
    )
endforeach()
