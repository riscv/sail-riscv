include(FetchContent)

# Allow downloads to be turned off (in particular, for targets that don't need it).
option(DOWNLOAD_CLI11 "Download CLI11" ON)

FetchContent_Declare(cli11_hpp
  URL "https://github.com/CLIUtils/CLI11/releases/download/v2.6.1/CLI11.hpp"
  DOWNLOAD_NO_EXTRACT YES
  URL_HASH SHA256=8bad421104bbac1d763be60e3f833768e72c2d9f6fa14a6d19162979ba97c2e9
)

if(DOWNLOAD_CLI11)
  FetchContent_MakeAvailable(cli11_hpp)
  add_library(CLI11 INTERFACE)
  target_include_directories(CLI11 INTERFACE "${cli11_hpp_SOURCE_DIR}")
endif()
