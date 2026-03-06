# CMake options for test downloads
set(TEST_DOWNLOAD_URL "https://github.com/riscv-software-src/sail-riscv-tests/releases/download" CACHE STRING "Base URL to download precompiled riscv-tests and riscv-vector-tests from")
set(TEST_DOWNLOAD_VERSION "2026-02-03" CACHE STRING "Version of precompiled tests to download")

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
