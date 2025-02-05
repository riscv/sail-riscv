foreach (xlen IN ITEMS 32 64)
    # TODO: flen=32. Will do this when the new config system is implemented.
    foreach (flen IN ITEMS 64)
        set(arch "rv${xlen}")
        if (flen EQUAL 32)
            string(APPEND arch "f")
        else()
            string(APPEND arch "d")
        endif()

        add_executable(unit_tests_${arch}
            "${CMAKE_BINARY_DIR}/riscv_model_${arch}.c"
            "main_unit_tests.c"
        )

        add_dependencies(unit_tests_${arch} generated_model_${arch})

        target_link_libraries(unit_tests_${arch}
            PRIVATE riscv_platform
        )

        add_test(
            NAME "${arch}_unit_tests"
            COMMAND $<TARGET_FILE:unit_tests_${arch}>
        )
    endforeach()
endforeach()
