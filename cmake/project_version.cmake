# Increment this appropriately at tag-and-release time.
set(sail_riscv_release_version "0.7")

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

  set(sail_riscv_git_version   "unknown commit")
else()
  set(sail_riscv_git_version   ${git_describe})
endif()

# Log versions in the build log.
message(STATUS "Building versions: ${sail_riscv_git_version} (git), ${sail_riscv_release_version} (cmake).")
