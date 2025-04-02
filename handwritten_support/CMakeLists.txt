file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/rocq")
foreach(basename IN ITEMS "riscv_extras" "mem_metadata")
    add_custom_command(
        DEPENDS "${basename}.v"
        VERBATIM
        OUTPUT "${CMAKE_BINARY_DIR}/rocq/${basename}.vo"
        COMMENT "Building Rocq ${basename} file"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMAND
            coqc
            -R "${CMAKE_BINARY_DIR}/rocq" Riscv
            -o "${CMAKE_BINARY_DIR}/rocq/${basename}.vo"
            "${basename}.v"
    )
endforeach()
add_custom_target(build_rocq_common DEPENDS "${CMAKE_BINARY_DIR}/rocq/riscv_extras.vo" "${CMAKE_BINARY_DIR}/rocq/mem_metadata.vo")
