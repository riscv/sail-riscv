add_library(CLI11 INTERFACE)

target_sources(CLI11 INTERFACE CLI11.hpp)

target_include_directories(CLI11 INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
