include(FetchContent)

set(use_jsoncons_version "1.4.1")

# The jsoncons `unit_tests` target conflicts with our own.
set(JSONCONS_BUILD_TESTS OFF)

FetchContent_Declare(
  jsoncons
  URL https://github.com/danielaparker/jsoncons/archive/refs/tags/v${use_jsoncons_version}.tar.gz
  URL_HASH SHA3_224=728c12d82be9a60991581236489708321b301373bda7cea41170a195
)

FetchContent_MakeAvailable(jsoncons)
