
file(READ "default.json" DEFAULT_JSON)
configure_file("default_config.h.in" "default_config.h" @ONLY)
# Ensure this runs again if `default.json` is changed.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "default.json;default_config.h.in")

add_library(default_config INTERFACE
  "default_config.h"
)

target_include_directories(default_config INTERFACE "${CMAKE_BINARY_DIR}/config")
