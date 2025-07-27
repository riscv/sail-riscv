#add_custom_command(
#  DEPENDS "default_config.h.in" "generate_default_config_h.cmake" "rv64d.json" "${CMAKE_BINARY_DIR}/sail_riscv_config_schema.json"
#  COMMAND cmake -P "${CMAKE_CURRENT_SOURCE_DIR}/generate_default_config_h.cmake"
#  OUTPUT "default_config.h"
#  VERBATIM
#)
# Ensure this runs again if the dependencies are changed.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${default_config_filename};default_config.h.in")

add_library(default_config INTERFACE
    "default_config.h"
)

target_include_directories(default_config INTERFACE "${CMAKE_BINARY_DIR}/config")

install(FILES "rv64d.json" "rv32d.json"
    DESTINATION ${CMAKE_INSTALL_DATADIR}/${CMAKE_PROJECT_NAME}/config
)

add_custom_command(
  DEPENDS "default_config.h.in" "generate_default_config_h.cmake" "rv64d.json" "${CMAKE_BINARY_DIR}/sail_riscv_config_schema.json"
  COMMAND cmake -e "${CMAKE_CURRENT_SOURCE_DIR}/generate_default_config_h.cmake"
  OUTPUT "default_config.h"
  VERBATIM
)
