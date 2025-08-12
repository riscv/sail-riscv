add_library(elfloader INTERFACE)

target_sources(elfloader INTERFACE elfloader.hpp)

target_link_libraries(elfloader
    INTERFACE elfio
)

target_include_directories(elfloader INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
