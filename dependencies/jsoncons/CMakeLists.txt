include(FetchContent)

set(use_jsoncons_version "1.4.1")

# The jsoncons `unit_tests` target conflicts with our own.
set(JSONCONS_BUILD_TESTS OFF)

FetchContent_Declare(
  jsoncons
  URL https://github.com/danielaparker/jsoncons/archive/refs/tags/v${use_jsoncons_version}.tar.gz
  URL_HASH MD5=c750ec0db8ad11e84bdc9a3e01780f95
)

FetchContent_MakeAvailable(jsoncons)
