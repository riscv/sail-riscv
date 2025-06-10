# This option is required for the GitHub CI to prevent parallel
# jobs from building both riscv-tests and riscv-vector-tests.
# For example, if the `run-riscv-tests` job runs and DOWNLOAD_LOCALLY
# is not set to FALSE, it would automatically download and run the
# vector tests as well, because they are missing locally.
option(DOWNLOAD_LOCALLY "Download test files locally if needed" ON)

find_program(JQ_EXECUTABLE jq REQUIRED)

message(STATUS "JQ_EXECUTABLE=${JQ_EXECUTABLE}")

execute_process(
    COMMAND ${JQ_EXECUTABLE} -r .extensions.V.vlen_exp "${CMAKE_CURRENT_SOURCE_DIR}/../config/default.json"
    OUTPUT_VARIABLE vlen_exp
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process(
    COMMAND ${JQ_EXECUTABLE} -r .extensions.V.elen_exp "${CMAKE_CURRENT_SOURCE_DIR}/../config/default.json"
    OUTPUT_VARIABLE elen_exp
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

math(EXPR vlen "1 << ${vlen_exp}")  # 2^vlen_exp
math(EXPR elen "1 << ${elen_exp}")  # 2^elen_exp

message(STATUS "Config: VLEN=${vlen}, ELEN=${elen}")

# Check if riscv-vector-v${vlen}x${elen} directory exists
# Only attempt to download vector test files if both vlen and elen are within valid ranges
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests-v${vlen}x${elen}" AND
   (vlen EQUAL 128 OR vlen EQUAL 256 OR vlen EQUAL 512) AND
   (elen EQUAL 32 OR elen EQUAL 64) AND DOWNLOAD_LOCALLY)

    message(STATUS "riscv-vector-tests-v${vlen}x${elen} directory not found, downloading...")

    # Download the tar.gz file
    file(DOWNLOAD
        "https://github.com/nadime15/riscv-test-generator/releases/latest/download/riscv-vector-tests-v${vlen}x${elen}.tar.gz"
        "${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests-v${vlen}x${elen}.tar.gz"
        SHOW_PROGRESS
        STATUS download_status
    )

    # Check download status
    list(GET download_status 0 status_code)
    if(NOT status_code EQUAL 0)
        list(GET download_status 1 error_message)
        message(FATAL_ERROR "Failed to download riscv-vector-tests-v${vlen}x${elen}: ${error_message}")
    endif()

    # Create riscv-vector-tests-v${vlen}x${elen} directory and extract the tar.gz file into it
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests-v${vlen}x${elen}")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf "${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests-v${vlen}x${elen}.tar.gz"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests-v${vlen}x${elen}"
        RESULT_VARIABLE extract_result
    )

    if(NOT extract_result EQUAL 0)
        message(FATAL_ERROR "Failed to extract riscv-vector-tests-v${vlen}x${elen}")
    endif()

    # Clean up the tar.gz file
    file(REMOVE "${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests-v${vlen}x${elen}.tar.gz")

    message(STATUS "riscv-vector-tests-v${vlen}x${elen} downloaded and extracted successfully")
endif()

# Check if riscv-tests directory exists
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/riscv-tests" AND DOWNLOAD_LOCALLY)
    message(STATUS "riscv-tests directory not found, downloading...")

    # Download the tar.gz file
    file(DOWNLOAD
        "https://github.com/nadime15/riscv-test-generator/releases/latest/download/riscv-tests.tar.gz"
        "${CMAKE_CURRENT_SOURCE_DIR}/riscv-tests.tar.gz"
        SHOW_PROGRESS
        STATUS download_status
    )

    # Check download status
    list(GET download_status 0 status_code)
    if(NOT status_code EQUAL 0)
        list(GET download_status 1 error_message)
        message(FATAL_ERROR "Failed to download riscv-tests.tar.gz: ${error_message}")
    endif()

    # Create riscv-tests directory and extract the tar.gz file into it
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/riscv-tests")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf "${CMAKE_CURRENT_SOURCE_DIR}/riscv-tests.tar.gz"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/riscv-tests"
        RESULT_VARIABLE extract_result
    )

    if(NOT extract_result EQUAL 0)
        message(FATAL_ERROR "Failed to extract riscv-tests.tar.gz")
    endif()

    # Clean up the tar.gz file
    file(REMOVE "${CMAKE_CURRENT_SOURCE_DIR}/riscv-tests.tar.gz")

    message(STATUS "riscv-tests downloaded and extracted successfully")
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
