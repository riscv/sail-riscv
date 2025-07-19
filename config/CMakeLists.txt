set(default_config_filename "rv64d.json")
file(READ ${default_config_filename} DEFAULT_JSON)
configure_file("default_config.h.in" "default_config.h" @ONLY)
# Ensure this runs again if the dependencies are changed.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${default_config_filename};default_config.h.in")

add_library(default_config INTERFACE
    "default_config.h"
)

target_include_directories(default_config INTERFACE "${CMAKE_BINARY_DIR}/config")

install(FILES "rv64d.json" "rv32d.json"
    DESTINATION ${CMAKE_INSTALL_DATADIR}/${CMAKE_PROJECT_NAME}/config
)

foreach(vlen RANGE 7 9)
    foreach(elen RANGE 5 6)
	math(EXPR CONFIG_BASE_XLEN "1<<${elen}")
        set(CONFIG_V_VLEN ${vlen})
        set(CONFIG_V_ELEN ${elen})
        math(EXPR vlen2 "1<<${vlen}")
        message(STATUS "VLEN=${vlen2},ELEN=${CONFIG_BASE_XLEN}")
        configure_file(rvd.json.in rv${CONFIG_BASE_XLEN}d-v${vlen2}.json)
    endforeach()
endforeach()
