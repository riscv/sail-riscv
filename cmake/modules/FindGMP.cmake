# From https://github.com/Z3Prover/z3/blob/7f8e2a9f75f6c8b4b8ab05b87ea6a343d9a0b88d/cmake/modules/FindGMP.cmake
# with minor simplication to remove gmp++ and try pkg-config.

# Tries to find an install of the GNU multiple precision library
#
# Once done this will define
#  GMP_FOUND - BOOL: System has the GMP library installed
#  GMP_C_LIBRARIES - LIST: The libraries needed to use GMP via it's C interface
#  GMP_C_INCLUDES - LIST: The GMP include directories

include(FindPackageHandleStandardArgs)

find_package(PkgConfig)
if (PKG_CONFIG_FOUND)
  pkg_check_modules(PC_GMP QUIET gmp)
endif()

# Try to find libraries
find_library(GMP_C_LIBRARIES
  NAMES gmp
  PATHS ${PC_GMP_LIBRARY_DIRS}
  DOC "GMP C libraries"
)

# Try to find headers
find_path(GMP_C_INCLUDES
  NAMES gmp.h
  PATHS ${PC_GMP_INCLUDE_DIRS}
  DOC "GMP C header"
)

# TODO: We should check we can link some simple code against libgmp

# Handle QUIET and REQUIRED and check the necessary variables were set and if so
# set ``GMP_FOUND``
find_package_handle_standard_args(GMP
  REQUIRED_VARS GMP_C_LIBRARIES GMP_C_INCLUDES)

if (GMP_FOUND)
  if (NOT TARGET GMP::GMP)
    add_library(GMP::GMP UNKNOWN IMPORTED)
    set_target_properties(GMP::GMP PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${GMP_C_INCLUDES}"
      IMPORTED_LOCATION "${GMP_C_LIBRARIES}")
  endif()
endif()
