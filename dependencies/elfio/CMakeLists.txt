# Allow downloads to be turned off (in particular, for targets that don't need it).
option(DOWNLOAD_ELFIO "Download elfio" ON)

if (NOT DOWNLOAD_ELFIO)
  return()
endif()

include(FetchContent)

FetchContent_Declare(
  elfio
  URL https://github.com/serge1/ELFIO/releases/download/Release_3.12/elfio-3.12.tar.gz
  URL_HASH SHA256=caf49f3bf55a9c99c98ebea4b05c79281875783802e892729eea0415505f68c4
)

FetchContent_MakeAvailable(elfio)

set_target_properties(elfio
  PROPERTIES SKIP_LINTING ON
)
