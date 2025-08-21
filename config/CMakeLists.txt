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

            configure_file(config.json.in ${config_filename})

            install(FILES ${config_filename}
                DESTINATION ${CMAKE_INSTALL_DATADIR}/${CMAKE_PROJECT_NAME}/config
            )
        endforeach()
    endforeach()
endforeach()

file(READ "${CMAKE_CURRENT_BINARY_DIR}/rv64d_v256_e64.json" DEFAULT_JSON)
configure_file("default_config.h.in" "default_config.h" @ONLY)

add_library(default_config INTERFACE
    "default_config.h"
)

target_include_directories(default_config INTERFACE "${CMAKE_CURRENT_BINARY_DIR}")
