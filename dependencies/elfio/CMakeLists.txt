if (NOT DOWNLOAD_CPP_DEPENDENCIES)
  return()
endif()

include(FetchContent)

FetchContent_Declare(
  elfio
  GIT_REPOSITORY https://github.com/serge1/ELFIO.git
  GIT_TAG 9814eaaa7623e05b1e2dd11794eb6404afac9040 # fix for clang-tidy; this announces version 3.14 but there is no such release, and there was no version 3.13 :/
)

FetchContent_MakeAvailable(elfio)

set_target_properties(elfio
  PROPERTIES SKIP_LINTING ON
)
