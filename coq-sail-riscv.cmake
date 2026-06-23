# This small script fills in the version number in the opam package file.
# It can be invoked using
#
#   cmake -P coq-sail-riscv.cmake

include(cmake/project_version.cmake)
configure_file("coq-sail-riscv.opam.in" "coq-sail-riscv.opam" @ONLY)
