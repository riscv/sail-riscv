file(GLOB elfs_rv32d CONFIGURE_DEPENDS LIST_DIRECTORIES false
    "${CMAKE_CURRENT_SOURCE_DIR}/riscv-tests/rv32*"
)
file(GLOB elfs_rv64d CONFIGURE_DEPENDS LIST_DIRECTORIES false
    "${CMAKE_CURRENT_SOURCE_DIR}/riscv-tests/rv64*"
    "${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests/v512x64/rv64*"
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
