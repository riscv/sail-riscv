if (NOT DOWNLOAD_CPP_DEPENDENCIES)
  return()
endif()

include(FetchContent)

# The jsoncons `unit_tests` target conflicts with our own.
set(JSONCONS_BUILD_TESTS OFF)

FetchContent_Declare(
  jsoncons
  URL https://github.com/danielaparker/jsoncons/archive/refs/tags/v1.10.0.tar.gz
  URL_HASH SHA3_256=4c969cc48151906b368f2c4076df1c425631d6a0746b12f8441bf5389484b835
)

FetchContent_MakeAvailable(jsoncons)

set_target_properties(jsoncons
  PROPERTIES SKIP_LINTING ON
)
