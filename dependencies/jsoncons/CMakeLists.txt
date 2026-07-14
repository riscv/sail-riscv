include(FetchContent)

# Allow downloads to be turned off (in particular, for targets that don't need it).
option(DOWNLOAD_JSONCONS "Download jsoncons" ON)

# The jsoncons `unit_tests` target conflicts with our own.
set(JSONCONS_BUILD_TESTS OFF)

FetchContent_Declare(
  jsoncons
  URL https://github.com/danielaparker/jsoncons/archive/refs/tags/v1.8.1.tar.gz
  URL_HASH SHA3_256=c1f7957049ce756005ce67917ce8b6f09c0cf56e630664edeb272365229baada
)

if (DOWNLOAD_JSONCONS)
    FetchContent_MakeAvailable(jsoncons)

    set_target_properties(jsoncons
        PROPERTIES SKIP_LINTING ON
    )
endif()
