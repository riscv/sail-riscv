option(RUN_RISCV_VECTOR_TESTS "Run the riscv-vector-tests" OFF)
option(RUN_RISCV_TESTS "Run the riscv-tests" ON)

# Function to download and extract test files
function(download_riscv_tests DOWNLOAD_PATH ARCHIVE_NAME DOWNLOAD_URL)
    if(NOT EXISTS "${DOWNLOAD_PATH}/${ARCHIVE_NAME}")
        message(STATUS "${ARCHIVE_NAME} directory not found, downloading...")

        # Download the tar.gz file
        file(DOWNLOAD
            "${DOWNLOAD_URL}"
            "${DOWNLOAD_PATH}/${ARCHIVE_NAME}.tar.gz"
            SHOW_PROGRESS
            STATUS download_status
        )

        # Check download status
        list(GET download_status 0 status_code)
        if(NOT status_code EQUAL 0)
            list(GET download_status 1 error_message)
            message(FATAL_ERROR "Failed to download ${ARCHIVE_NAME}: ${error_message}")
        endif()

        # Create directory and extract the tar.gz file into it
        file(MAKE_DIRECTORY "${DOWNLOAD_PATH}/${ARCHIVE_NAME}")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xzf "${DOWNLOAD_PATH}/${ARCHIVE_NAME}.tar.gz"
            WORKING_DIRECTORY "${DOWNLOAD_PATH}/${ARCHIVE_NAME}"
            RESULT_VARIABLE extract_result
        )

        if(NOT extract_result EQUAL 0)
            message(FATAL_ERROR "Failed to extract ${ARCHIVE_NAME}")
        endif()

        # Clean up the tar.gz file
        file(REMOVE "${DOWNLOAD_PATH}/${ARCHIVE_NAME}.tar.gz")
        message(STATUS "${ARCHIVE_NAME} downloaded and extracted successfully")
    endif()
endfunction()

# Extracting vlen_exp and elen_exp
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/../config/default.json" json)

string(REGEX MATCH "\"vlen_exp\"[ \t]*:[ \t]*([0-9]+)" _ "${json}")
set(vlen_exp "${CMAKE_MATCH_1}")

string(REGEX MATCH "\"elen_exp\"[ \t]*:[ \t]*([0-9]+)" _ "${json}")
set(elen_exp "${CMAKE_MATCH_1}")

# Should I add more error handling in case elen_exp or vlen_exp are missing (Sail should catch it anyway)?

math(EXPR vlen "1 << ${vlen_exp}")
math(EXPR elen "1 << ${elen_exp}")

message(STATUS "Config: VLEN=${vlen}, ELEN=${elen}")

# Download riscv-vector-tests
# Only attempt to download vector test files if both vlen and elen are within valid ranges
if((vlen EQUAL 128 OR vlen EQUAL 256 OR vlen EQUAL 512) AND
   (elen EQUAL 32 OR elen EQUAL 64) AND RUN_RISCV_VECTOR_TESTS)
    download_riscv_tests(
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "riscv-vector-tests-v${vlen}x${elen}"
        "https://github.com/nadime15/riscv-test-generator/releases/latest/download/riscv-vector-tests-v${vlen}x${elen}.tar.gz"
    )
endif()

# Download riscv-tests
if(RUN_RISCV_TESTS)
    download_riscv_tests(
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "riscv-tests"
        "https://github.com/nadime15/riscv-test-generator/releases/latest/download/riscv-tests.tar.gz"
    )
endif()

file(GLOB elfs_rv32d CONFIGURE_DEPENDS LIST_DIRECTORIES false
    "${CMAKE_CURRENT_SOURCE_DIR}/riscv-tests/rv32*"
    "${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests-v${vlen}x${elen}/rv32*"
)

file(GLOB elfs_rv64d CONFIGURE_DEPENDS LIST_DIRECTORIES false
    "${CMAKE_CURRENT_SOURCE_DIR}/riscv-tests/rv64*"
    "${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests-v${vlen}x${elen}/rv64*"
)

foreach (arch IN ITEMS "rv32d" "rv64d")
    foreach(elf IN LISTS elfs_${arch})
        file(RELATIVE_PATH elf_name "${CMAKE_CURRENT_SOURCE_DIR}" ${elf})

        add_test(
            NAME "${arch}_${elf_name}"
            COMMAND
                $<TARGET_FILE:riscv_sim_${arch}>
                --config "${CMAKE_SOURCE_DIR}/config/default.json"
                ${elf}
        )
    endforeach()
endforeach()

# This is off by default so we don't require people who
# just want to build the model to have Clang or RISC-V GCC
# installed.
option(FIRST_PARTY_TESTS "Compile & run first party tests (requires Clang or RISC-V GCC).")
if (FIRST_PARTY_TESTS)
    add_subdirectory("first_party")
endif()

add_subdirectory("unit_tests")
