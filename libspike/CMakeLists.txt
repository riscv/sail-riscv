# This requires an install of Spike.  Its install instructions are
# given as:
#   ../configure --prefix=$RISCV
#   make && make install
# This file requires the value of $RISCV to be placed in the environment.

if (USE_SPIKE)

  if (NOT DEFINED ENV{RISCV})
    message(FATAL_ERROR "Using the USE_SPIKE option requires specifying the location for Spike using the RISCV environment variable.")
  endif()

  set(spike_install_prefix $ENV{RISCV})

  if (NOT IS_DIRECTORY ${spike_install_prefix})
    message(FATAL_ERROR "The value ${RISCV} of the RISCV environment variable is not a directory.")
  endif()

  message(STATUS "Spike install prefix (from $RISCV): ${spike_install_prefix}")

  find_library(libfesvr_loc libfesvr.a
    PATHS ${spike_install_prefix} PATH_SUFFIXES lib
  )
  message(STATUS "libfesvr.a: ${libfesvr_loc}")

  find_library(libriscv_loc libriscv.so
    PATHS ${spike_install_prefix} PATH_SUFFIXES lib
  )
  message(STATUS "libriscv.so: ${libriscv_loc}")

  find_path(fesvr_inc_loc htif.h
    PATHS ${spike_install_prefix} PATH_SUFFIXES include/fesvr
  )
  message(STATUS "htif.h: ${fesvr_inc_loc}")

  find_path(riscv_inc_loc sim.h
    PATHS ${spike_install_prefix} PATH_SUFFIXES include/riscv
  )
  message(STATUS "sim.h: ${riscv_inc_loc}")

  if (libfesvr_loc AND libriscv_loc AND fesvr_inc_loc AND riscv_inc_loc)
    cmake_path(GET fesvr_inc_loc PARENT_PATH fesvr_inc)
    cmake_path(GET riscv_inc_loc PARENT_PATH riscv_inc)

    add_library(spike INTERFACE IMPORTED GLOBAL)
    target_include_directories(spike
      INTERFACE ${fesvr_inc} ${riscv_inc}
    )
    target_link_libraries(spike
      INTERFACE ${libfesvr_loc} ${libriscv_loc}
    )
    target_compile_definitions(spike
      INTERFACE USE_SPIKE=1
    )
  endif()

endif()
