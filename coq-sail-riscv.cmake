# This small script fills in the version numbers in the opam package file.
# It can be invoked using
#
#   cmake -P coq-sail-riscv.cmake

include(cmake/project_version.cmake)
include(cmake/sail_required_version.cmake)
# If the Rocq output requires a more recent version of Sail than the model does,
# you can override it here.
if(EXISTS "cmake/sail_required_version_rocq.txt")
  file(READ "cmake/sail_required_version_rocq.txt" sail_required_version_rocq)
  string(STRIP "${sail_required_version_rocq}" sail_required_version_rocq)
else()
  set(sail_required_version_rocq ${SAIL_REQUIRED_VER})
endif()
configure_file("coq-sail-riscv.opam.in" "coq-sail-riscv.opam" @ONLY)
