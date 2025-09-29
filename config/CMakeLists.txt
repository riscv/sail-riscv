set(config_validation_files)

# Create a variety of configuration files for different XLEN/ELEN/VLENs.
foreach (CONFIG__BASE__XLEN IN ITEMS 32 64)
    foreach(CONFIG__V__ELEN_EXP RANGE 5 6)
        foreach(CONFIG__V__VLEN_EXP RANGE 7 9)
            math(EXPR vlen "1 << ${CONFIG__V__VLEN_EXP}")
            math(EXPR elen "1 << ${CONFIG__V__ELEN_EXP}")

            set(config_filename "rv${CONFIG__BASE__XLEN}d_v${vlen}_e${elen}.json")

            set(CONFIG_XLEN_IS_32 "false")
            set(CONFIG_XLEN_IS_64 "false")
            set(CONFIG_XLEN_IS_${CONFIG__BASE__XLEN} "true")

            configure_file(config.json.in ${CMAKE_CURRENT_BINARY_DIR}/${config_filename})

            install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${config_filename}
                DESTINATION ${CMAKE_INSTALL_DATADIR}/${CMAKE_PROJECT_NAME}/config
            )

            # After the emulator is built, run it to verify this config is valid.
            add_custom_command(
                DEPENDS sail_riscv_sim
                OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${config_filename}.valid"
                COMMAND $<TARGET_FILE:sail_riscv_sim>
                            --validate-config
                            --config ${CMAKE_CURRENT_BINARY_DIR}/${config_filename}
                            > "${config_filename}.out"
                # Only if successful, move the .out to .valid (otherwise
                # things will go wrong when it fails but still generates the .out file).
                COMMAND cmake -E rename "${config_filename}.out" "${config_filename}.valid"
                COMMENT "Validating config file ${config_filename}"
                VERBATIM
            )
            list(APPEND config_validation_files "${CMAKE_CURRENT_BINARY_DIR}/${config_filename}.valid")
        endforeach()
    endforeach()
endforeach()

# This target runs the C emulator to validate all of the configs generated here.
add_custom_target(config_validation ALL DEPENDS ${config_validation_files})

# Embed the default config in a C header.
file(READ "${CMAKE_CURRENT_BINARY_DIR}/rv64d_v256_e64.json" DEFAULT_JSON)
configure_file("default_config.h.in" "default_config.h" @ONLY)

add_library(default_config INTERFACE
    "default_config.h"
)

target_include_directories(default_config INTERFACE "${CMAKE_CURRENT_BINARY_DIR}")
