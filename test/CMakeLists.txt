add_subdirectory("riscv-tests")

# NOTE: RVV tests were compiled with VLEN=128 and ELEN=64.
# These values must be set accordingly in the config JSON file.
option(RVV_TESTS "Enable RISC-V Vector extension tests.")
if(RVV_TESTS)
    set(RVV_TESTS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/rvv-tests")
    set(RVV_ARCH "rv64d")

    if(EXISTS "${RVV_TESTS_DIR}" AND IS_DIRECTORY "${RVV_TESTS_DIR}")
        message(STATUS "Found rvv-tests, enabling rvv tests")
        file(GLOB elfs_rvv_test CONFIGURE_DEPENDS "${RVV_TESTS_DIR}/v*")
            foreach(elf IN LISTS elfs_rvv_test)
                file(RELATIVE_PATH elf_name "${RVV_TESTS_DIR}" ${elf})

                add_test(
                    NAME "${RVV_ARCH}_${elf_name}"
                    COMMAND
                        $<TARGET_FILE:riscv_sim_${RVV_ARCH}>
                        --config "${CMAKE_SOURCE_DIR}/config/default.json"
                        ${elf}
                )
            endforeach()
    else()
        message(WARNING "rvv-tests submodule not found, skipping tests.\n"
                "To enable RISC-V Vector extensions tests, initialize the submodule:\n"
                "  git submodule update --init --recursive --remote")
        return()
    endif()
endif()

# This is off by default so we don't require people who
# just want to build the model to have Clang or RISC-V GCC
# installed.
option(FIRST_PARTY_TESTS "Compile & run first party tests (requires Clang or RISC-V GCC).")
if (FIRST_PARTY_TESTS)
    add_subdirectory("first_party")
endif()

add_subdirectory("unit_tests")
