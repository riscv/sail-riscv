file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/rocq")
add_custom_command(
    DEPENDS "riscv_extras.v"
    VERBATIM
    OUTPUT "${CMAKE_BINARY_DIR}/rocq/riscv_extras.vo"
    COMMENT "Building Rocq riscv_extras file"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND
        coqc
        -R "${CMAKE_BINARY_DIR}/rocq" Riscv
        -o "${CMAKE_BINARY_DIR}/rocq/riscv_extras.vo"
        "riscv_extras.v"
)
add_custom_target(build_rocq_common DEPENDS "${CMAKE_BINARY_DIR}/rocq/riscv_extras.vo")
