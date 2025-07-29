# CMake options for test downloads
set(TEST_DOWNLOAD_URL "https://github.com/riscv-software-src/sail-riscv-tests/releases/download" CACHE STRING "Base URL to download precompiled riscv-tests and riscv-vector-tests from")
set(TEST_DOWNLOAD_VERSION "2025-07-16" CACHE STRING "Version of precompiled tests to download")

# Function to download and extract test files
function(download_riscv_tests DOWNLOAD_PATH TARBALL_NAME DOWNLOAD_URL)
    if(NOT EXISTS "${DOWNLOAD_PATH}/${TARBALL_NAME}")
        message(STATUS "${TARBALL_NAME} directory not found, downloading...")

        # Download the tar.gz file
        file(DOWNLOAD
            "${DOWNLOAD_URL}"
            "${DOWNLOAD_PATH}/${TARBALL_NAME}.tar.gz"
            SHOW_PROGRESS
            STATUS download_status
        )

        # Check download status
        list(GET download_status 0 status_code)
        if(NOT status_code EQUAL 0)
            list(GET download_status 1 error_message)
            message(FATAL_ERROR "Failed to download ${TARBALL_NAME}: ${error_message}")
        endif()

        # Create directory and extract the tar.gz file into it
        file(MAKE_DIRECTORY "${DOWNLOAD_PATH}/${TARBALL_NAME}")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xzf "${DOWNLOAD_PATH}/${TARBALL_NAME}.tar.gz"
            WORKING_DIRECTORY "${DOWNLOAD_PATH}/${TARBALL_NAME}"
            RESULT_VARIABLE extract_result
        )

        if(NOT extract_result EQUAL 0)
            message(FATAL_ERROR "Failed to extract ${TARBALL_NAME}")
        endif()

        # Clean up the tar.gz file
        file(REMOVE "${DOWNLOAD_PATH}/${TARBALL_NAME}.tar.gz")
        message(STATUS "${TARBALL_NAME} downloaded and extracted successfully")
    endif()
endfunction()

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

            file(GLOB elfs_rv32d CONFIGURE_DEPENDS LIST_DIRECTORIES false
                "${DOWNLOAD_PATH}/${TARBALL_NAME}/rv32*"
            )
            file(GLOB elfs_rv64d CONFIGURE_DEPENDS LIST_DIRECTORIES false
                "${DOWNLOAD_PATH}/${TARBALL_NAME}/rv64*"
            )

            add_custom_command(
                OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/config_rv${elen}d_v${vlen}_e${elen}.json"
                COMMAND jq
                    '.base.xlen = ${elen} |
                     .extensions.V.vlen_exp = (${vlen} | log2) |
                     .extensions.V.elen_exp = (${elen} | log2) '
                    "${CMAKE_CURRENT_SOURCE_DIR}/../config/rv${elen}d.json"
                    > "${CMAKE_CURRENT_BINARY_DIR}/config_rv${elen}d_v${vlen}_e${elen}.json"
                DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/../config/rv${elen}d.json"
                COMMENT "Generating config for vlen=${vlen}, elen=${elen}, xlen=${elen}"
            )

            add_custom_target(config_rv${elen}d_v${vlen}_e${elen} ALL
                DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/config_rv${elen}d_v${vlen}_e${elen}.json"
            )

            foreach(arch IN ITEMS "rv32d" "rv64d")
                foreach(elf IN LISTS elfs_${arch})
                    file(RELATIVE_PATH elf_name "${CMAKE_CURRENT_BINARY_DIR}" ${elf})
                    add_test(
                        NAME "${arch}_${elf_name}"
                        COMMAND
                            $<TARGET_FILE:sail_riscv_sim>
                            --config "${CMAKE_CURRENT_BINARY_DIR}/config_rv${elen}d_v${vlen}_e${elen}.json"
                            ${elf}
                    )
                endforeach()
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

    file(GLOB elfs_rv32d CONFIGURE_DEPENDS LIST_DIRECTORIES false
        "${DOWNLOAD_PATH}/${TARBALL_NAME}/rv32*"
    )

    file(GLOB elfs_rv64d CONFIGURE_DEPENDS LIST_DIRECTORIES false
        "${DOWNLOAD_PATH}/${TARBALL_NAME}/rv64*"
    )

    foreach(arch IN ITEMS "rv32d" "rv64d")
        foreach(elf IN LISTS elfs_${arch})
            file(RELATIVE_PATH elf_name "${CMAKE_CURRENT_BINARY_DIR}" ${elf})
            add_test(
                NAME "${arch}_${elf_name}"
                COMMAND
                    $<TARGET_FILE:sail_riscv_sim>
                    --config "${CMAKE_SOURCE_DIR}/config/${arch}.json"
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
