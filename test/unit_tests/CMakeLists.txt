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
            "main_unit_tests.cpp"
        )

        # The generated model is not warnings-clean, silence them.
        set(_generated_c_warning_opt_out
            -Wno-extra
            -Wno-unused
            -Wno-uninitialized
        )
        set_source_files_properties("${CMAKE_BINARY_DIR}/riscv_model_${arch}.c"
                                    PROPERTIES COMPILE_OPTIONS "${_generated_c_warning_opt_out}")

        add_dependencies(unit_tests_${arch} generated_model_${arch})

        target_link_libraries(unit_tests_${arch}
            PRIVATE riscv_platform default_config
        )

        add_test(
            NAME "${arch}_unit_tests"
            COMMAND $<TARGET_FILE:unit_tests_${arch}>
        )
    endforeach()
endforeach()
