set(EMULATOR_COMMON_SRCS
    riscv_config.h
    riscv_platform.c
    riscv_platform.h
    riscv_platform_impl.c
    riscv_platform_impl.h
    riscv_prelude.c
    riscv_prelude.h
    riscv_sail.h
    riscv_sim.c
    riscv_softfloat.c
    riscv_softfloat.h
)

foreach (xlen IN ITEMS 32 64)
    foreach (flen IN ITEMS 32 64)
        foreach (variant IN ITEMS "" "rvfi")
            set(arch "rv${xlen}")
            if (flen EQUAL 32)
                string(APPEND arch "f")
            else()
                string(APPEND arch "d")
            endif()
            if (variant)
                string(APPEND arch "_${variant}")
            endif()

            add_executable(riscv_sim_${arch}
                "${CMAKE_BINARY_DIR}/riscv_model_${arch}.c"
                ${EMULATOR_COMMON_SRCS}
            )

            if (NOT arch IN_LIST DEFAULT_ARCHITECTURES)
                set_target_properties(riscv_sim_${arch} PROPERTIES EXCLUDE_FROM_ALL TRUE)
            endif()

            add_dependencies(riscv_sim_${arch} generated_model_${arch})

            target_link_libraries(riscv_sim_${arch}
                PRIVATE softfloat sail_runtime GMP::GMP ZLIB::ZLIB
            )

            target_include_directories(riscv_sim_${arch}
                # So the generated C can find riscv_platform/prelude.h"
                PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}"
            )

            if (arch MATCHES "rvfi")
                target_compile_definitions(riscv_sim_${arch}
                    PRIVATE RVFI_DII
                )
            endif()

            # TODO: Enable warnings when we use the #include trick
            # to include the generated Sail code. Currently it
            # generates too many warnings to turn these on globally.

            # target_compile_options(riscv_sim_${arch} PRIVATE
            #     -Wall -Wextra
            #     # Too annoying at the moment.
            #     -Wno-unused-parameter
            # )

            install(TARGETS riscv_sim_${arch})
        endforeach()
    endforeach()
endforeach()
