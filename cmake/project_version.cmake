# Set a default version for archive builds that do not have
# git history.  Increment this appropriately at tag-and-release time.
set(archive_build_version "0.7.0")

# Sets GIT_EXECUTABLE
find_package(Git)

if (Git_FOUND)
  # We could remove --tags if we started annotating the release tags.
  execute_process(
    COMMAND ${GIT_EXECUTABLE} describe --tags HEAD
    RESULT_VARIABLE git_error
    OUTPUT_VARIABLE git_describe
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
else()
  set(git_error TRUE)
endif()

if (git_error)
  message(STATUS "Failed to run git describe: ${git_error}")

  set(sail_riscv_git_version   ${archive_build_version})
  set(sail_riscv_cmake_version ${archive_build_version})
else()
  # `git describe` cannot directly be used as a CMake VERSION argument
  # for project() due the trailing commit hash failing CMake's semver
  # format check.
  #
  # We could directly set PROJECT_VERSION to ${git_describe}, but that
  # makes it incompatible with CPack in case we decide to use it.
  # https://gitlab.kitware.com/cmake/cmake/-/issues/16716#note_956803
  #
  # Instead, parse the version components for CMake and CPack, and use
  # git_describe for the simulator --version.

  if (git_describe MATCHES "^([0-9]+)\\.([0-9]+)(-.*)?$")
    set(v_major ${CMAKE_MATCH_1})
    set(v_minor ${CMAKE_MATCH_2})
  else()
    message(FATAL_ERROR "Cannot parse git describe output: ${git_describe}")
  endif()

  set(sail_riscv_git_version   ${git_describe})
  set(sail_riscv_cmake_version "${v_major}.${v_minor}")
endif()

# Log versions in the build log.
message(STATUS "Building versions: ${sail_riscv_git_version} (git), ${sail_riscv_cmake_version} (cmake).")
