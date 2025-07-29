add_library(nlohmann_json INTERFACE
    "nlohmann-json.hpp"
)
target_include_directories(nlohmann_json INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}"
)
