execute_process(
    COMMAND ${SAIL_BIN} --dir
    OUTPUT_VARIABLE sail_dir
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)

add_library(sail_runtime
    "${sail_dir}/lib/elf.c"
    "${sail_dir}/lib/elf.h"
    "${sail_dir}/lib/rts.c"
    "${sail_dir}/lib/rts.h"
    "${sail_dir}/lib/sail.c"
    "${sail_dir}/lib/sail.h"
    "${sail_dir}/lib/sail_failure.c"
    "${sail_dir}/lib/sail_failure.h"
    "${sail_dir}/lib/sail_coverage.h"
    "${sail_dir}/lib/sail_state.h"
)

target_include_directories(sail_runtime
    PUBLIC "${sail_dir}/lib"
)

if (COVERAGE)
    find_package(Threads REQUIRED)

    # Note, you must run `make` in the ${sail_dir}/lib/coverage
    # directory; it doesn't come precompiled.
    target_link_libraries(sail_runtime
        PUBLIC
            "${sail_dir}/lib/coverage/libsail_coverage.a"
            Threads::Threads
            ${CMAKE_DL_LIBS}
    )
endif()
