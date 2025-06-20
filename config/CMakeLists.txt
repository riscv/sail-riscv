set(default_config_filename "rv64d.json")
file(READ ${default_config_filename} DEFAULT_JSON)
configure_file("default_config.h.in" "default_config.h" @ONLY)
# Ensure this runs again if the dependencies are changed.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${default_config_filename};default_config.h.in")

add_library(default_config INTERFACE
    "default_config.h"
)

target_include_directories(default_config INTERFACE "${CMAKE_BINARY_DIR}/config")
