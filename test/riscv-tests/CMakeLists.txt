# Run the emulator with all the ELF files in lib/sail-riscv/test/riscv-tests/rv32*.elf etc.
#
# On success or failure they write to the `tohost` symbol. See this code:
# https://github.com/riscv/riscv-test-env/blob/4fabfb4e0d3eacc1dc791da70e342e4b68ea7e46/p/riscv_test.h#L200

file(GLOB elfs_rv32d CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/rv32*.elf")
file(GLOB elfs_rv64d CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/rv64*.elf")

foreach (arch IN ITEMS "rv32d" "rv64d")
    foreach(elf IN LISTS elfs_${arch})
        file(RELATIVE_PATH elf_name "${CMAKE_CURRENT_SOURCE_DIR}" ${elf})

        add_test(
            NAME "${arch}_${elf_name}"
            COMMAND $<TARGET_FILE:riscv_sim_${arch}> ${elf}
        )
    endforeach()
endforeach()
