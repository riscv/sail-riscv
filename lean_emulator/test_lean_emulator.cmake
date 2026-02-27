include(${CMAKE_CURRENT_LIST_DIR}/../test/download_riscv_tests.cmake)

set(TARBALL_NAME "riscv-tests")
set(DOWNLOAD_PATH "${CMAKE_CURRENT_BINARY_DIR}/${TEST_DOWNLOAD_VERSION}")
set(DOWNLOAD_URL "${TEST_DOWNLOAD_URL}/${TEST_DOWNLOAD_VERSION}/${TARBALL_NAME}.tar.gz")

download_riscv_tests(
    "${DOWNLOAD_PATH}"
    "${TARBALL_NAME}"
    "${DOWNLOAD_URL}"
)

# Note: this is a bit slow, so only testing a handful of arbitrarily picked ELF
# files.
set(LEAN_EMULATOR_TEST_ELFS
    rv64ui-p-add
    rv64ui-p-addi
    rv64ui-p-addiw
    rv64ui-p-addw
    rv64ui-p-and
    rv64ui-p-andi
    rv64ui-p-auipc
    rv64ui-p-beq
    rv64ui-p-bge
    rv64ui-p-bgeu
    rv64ui-p-blt
    rv64ui-p-bltu
    rv64ui-p-bne
    # rv64ui-p-fence_i # does not work at the moment
    rv64ui-p-jal
    rv64ui-p-jalr
    rv64ui-p-lb
    rv64ui-p-lbu
    rv64ui-p-ld
    rv64ui-p-lh
    rv64ui-p-lhu
    rv64ui-p-lui
    rv64ui-p-lw
    rv64ui-p-lwu
    rv64ui-p-or
    rv64ui-p-ori
    rv64ui-p-sb
    rv64ui-p-sd
    rv64ui-p-sh
    rv64ui-p-simple
    rv64ui-p-sll
    rv64ui-p-slli
    rv64ui-p-slliw
    rv64ui-p-sllw
    rv64ui-p-slt
    rv64ui-p-slti
    rv64ui-p-sltiu
    rv64ui-p-sltu
    rv64ui-p-sra
    rv64ui-p-srai
    rv64ui-p-sraiw
    rv64ui-p-sraw
    rv64ui-p-srl
    rv64ui-p-srli
    rv64ui-p-srliw
    rv64ui-p-srlw
    rv64ui-p-sub
    rv64ui-p-subw
    rv64ui-p-sw
    rv64ui-p-xor
    rv64ui-p-xori
)

execute_process(
    COMMAND lake build lean_riscv_emulator
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
)
foreach(file IN LISTS LEAN_EMULATOR_TEST_ELFS)
    message(STATUS "Testing Lean emulator on file ${file}")
    execute_process(
        COMMAND lake exec lean_riscv_emulator -- "${DOWNLOAD_PATH}/riscv-tests/${file}"
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        COMMAND_ERROR_IS_FATAL ANY
    )
endforeach()
