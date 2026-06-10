include(FetchContent)

# Allow downloads to be turned off (in particular, for targets that don't need it).
option(DOWNLOAD_CLI11 "Download CLI11" ON)

FetchContent_Declare(cli11_hpp
  URL "https://github.com/CLIUtils/CLI11/releases/download/v2.6.2/CLI11.hpp"
  DOWNLOAD_NO_EXTRACT YES
  URL_HASH SHA256=227a16fe5f9f8ada80c3c409492475536f597e7bd83a6c26eacc3c8c149a9295
)

if(DOWNLOAD_CLI11)
  FetchContent_MakeAvailable(cli11_hpp)
  add_library(CLI11 INTERFACE)
  target_include_directories(CLI11
    SYSTEM INTERFACE
    "${cli11_hpp_SOURCE_DIR}")
endif()
