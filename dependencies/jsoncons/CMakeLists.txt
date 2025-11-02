include(FetchContent)

# The jsoncons `unit_tests` target conflicts with our own.
set(JSONCONS_BUILD_TESTS OFF)

FetchContent_Declare(
  jsoncons
  URL https://github.com/danielaparker/jsoncons/archive/refs/tags/v1.4.3.tar.gz
  URL_HASH SHA3_256=7AE49B206A2D271C4B1A122824FA76EFAAD91703F3124AC7A66A26D1EEA1D07E
)

FetchContent_MakeAvailable(jsoncons)
