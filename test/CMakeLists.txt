include(download_riscv_tests.cmake)

# Download and add RVV tests.
# NOTE: Setting XLEN independently of ELEN is not
# supported by the RISC-V Vector Test suite.
foreach(vlen IN ITEMS 128 256 512)
    foreach(elen IN ITEMS 32 64)
        option(ENABLE_RISCV_VECTOR_TESTS_V${vlen}_E${elen}
            "Enable riscv-vector-tests with vlen=${vlen}, elen=${elen}"
            OFF)

        if(ENABLE_RISCV_VECTOR_TESTS_V${vlen}_E${elen})
            set(TARBALL_NAME "riscv-vector-tests-v${vlen}x${elen}")
            set(DOWNLOAD_PATH "${CMAKE_CURRENT_BINARY_DIR}/${TEST_DOWNLOAD_VERSION}")
            set(DOWNLOAD_URL "${TEST_DOWNLOAD_URL}/${TEST_DOWNLOAD_VERSION}/${TARBALL_NAME}.tar.gz")

            download_riscv_tests(
                "${DOWNLOAD_PATH}"
                "${TARBALL_NAME}"
                "${DOWNLOAD_URL}"
            )

            # These tests use XLEN=ELEN. There are no tests with XLEN=64 & ELEN=32 or vice versa.
            set(xlen ${elen})

            file(GLOB elfs CONFIGURE_DEPENDS LIST_DIRECTORIES false
                "${DOWNLOAD_PATH}/${TARBALL_NAME}/rv${xlen}*"
            )

            foreach(elf IN LISTS elfs)
                file(RELATIVE_PATH elf_name "${CMAKE_CURRENT_BINARY_DIR}" ${elf})
                add_test(
                    # `elf_name` includes xlen/vlen/elen so we don't need to add any details.
                    NAME "${elf_name}"
                    COMMAND
                        $<TARGET_FILE:sail_riscv_sim>
                        --config "${CMAKE_BINARY_DIR}/config/rv${xlen}d_v${vlen}_e${elen}.json"
                        ${elf}
                )
            endforeach()
        endif()
    endforeach()
endforeach()

# Download and add RISC-V tests.
option(ENABLE_RISCV_TESTS "Enable riscv-tests" OFF)

if(ENABLE_RISCV_TESTS)
    set(TARBALL_NAME "riscv-tests")
    set(DOWNLOAD_PATH "${CMAKE_CURRENT_BINARY_DIR}/${TEST_DOWNLOAD_VERSION}")
    set(DOWNLOAD_URL "${TEST_DOWNLOAD_URL}/${TEST_DOWNLOAD_VERSION}/${TARBALL_NAME}.tar.gz")

    download_riscv_tests(
        "${DOWNLOAD_PATH}"
        "${TARBALL_NAME}"
        "${DOWNLOAD_URL}"
    )

    foreach(xlen IN ITEMS 32 64)
        file(GLOB elf_list CONFIGURE_DEPENDS LIST_DIRECTORIES false
           "${DOWNLOAD_PATH}/${TARBALL_NAME}/rv${xlen}*"
        )
        foreach(elf IN LISTS elf_list)
            file(RELATIVE_PATH elf_name "${CMAKE_CURRENT_BINARY_DIR}" ${elf})
            add_test(
                # `elf_name` includes xlen so we don't need to add any details.
                NAME "${elf_name}"
                COMMAND
                    $<TARGET_FILE:sail_riscv_sim>
                    # Use ELEN=XLEN. These tests don't use vector so it doesn't actually matter.
                    --config "${CMAKE_BINARY_DIR}/config/rv${xlen}d_v256_e${xlen}.json"
                    ${elf}
            )
        endforeach()
    endforeach()
endif()

# This is off by default so we don't require people who
# just want to build the model to have Clang or RISC-V GCC
# installed.
option(FIRST_PARTY_TESTS "Compile & run first party tests (requires Clang or RISC-V GCC).")
if (FIRST_PARTY_TESTS)
    add_subdirectory("first_party")
endif()

add_subdirectory("unit_tests")
