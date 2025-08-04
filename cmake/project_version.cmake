# Increment this appropriately at tag-and-release time.
set(sail_riscv_release_version "0.8")

# Sets GIT_EXECUTABLE
find_package(Git)

if (Git_FOUND)
  # --tags     Search for lightweight tags as well as annotated ones.
  # --always   If there are no tags use the git hash instead of failing.
  # --dirty    Append '-dirty' if the working tree has local modifications.
  # --broken   Append '-broken' if the repo is corrupt instead of failing.
  execute_process(
    COMMAND ${GIT_EXECUTABLE} describe --tags --always --dirty --broken
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
