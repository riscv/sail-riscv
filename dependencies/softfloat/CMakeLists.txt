if (NOT DOWNLOAD_CPP_DEPENDENCIES)
    return()
endif()

include(FetchContent)

FetchContent_Declare(
    berkeley_softfloat
    URL https://github.com/ucb-bar/berkeley-softfloat-3/archive/afdc157e71f0d97508301ac0965defead49c679b.tar.gz
    URL_HASH SHA256=fe5b8f89b44a706c16d1b780dbc8ea119f6e341c3b8d3b3e0952e0e98ba5a829
)

FetchContent_MakeAvailable(berkeley_softfloat)

SET(source_dir "${berkeley_softfloat_SOURCE_DIR}")

# Generic source plus RISC-V specific source.
file(GLOB riscv_source
    "${source_dir}/source/*.c"
    "${source_dir}/source/include/*.h"
    "${source_dir}/source/RISCV/*.c"
    "${source_dir}/source/RISCV/*.h"
    "${source_dir}/build/Linux-x86_64-GCC/*.h"
)

# Some files do not work with SOFTFLOAT_FAST_INT64
list(REMOVE_ITEM riscv_source
    "${source_dir}/source/s_addExtF80M.c"
    "${source_dir}/source/s_addF128M.c"
    "${source_dir}/source/s_compareNonnormExtF80M.c"
    "${source_dir}/source/s_invalidF128M.c"
    "${source_dir}/source/s_mulAddF128M.c"
    "${source_dir}/source/s_normRoundPackMToExtF80M.c"
    "${source_dir}/source/s_normRoundPackMToF128M.c"
    "${source_dir}/source/s_normSubnormalF128SigM.c"
    "${source_dir}/source/s_roundPackMToExtF80M.c"
    "${source_dir}/source/s_roundPackMToF128M.c"
    "${source_dir}/source/s_shiftLeftM.c"
    "${source_dir}/source/s_shiftNormSigF128M.c"
    "${source_dir}/source/s_shiftRightJamM.c"
    "${source_dir}/source/s_shiftRightM.c"
    "${source_dir}/source/s_tryPropagateNaNExtF80M.c"
    "${source_dir}/source/s_tryPropagateNaNF128M.c"
    "${source_dir}/source/RISCV/s_propagateNaNF128M.c"
    "${source_dir}/source/RISCV/s_commonNaNToF128M.c"
)

add_library(softfloat
    ${riscv_source}
)

target_include_directories(softfloat
    SYSTEM PUBLIC
    "${source_dir}/build/Linux-x86_64-GCC"
    "${source_dir}/source/include"
    "${source_dir}/source/RISCV"
)

target_compile_options(softfloat PRIVATE
    -Werror=implicit-function-declaration
    -Wno-unused-parameter
    $<$<BOOL:${HAVE_WIMPLICIT_FALLTHROUGH}>:-Wno-implicit-fallthrough>
)

# Taken from build/Linux-x86_64-GCC/Makefile
target_compile_definitions(softfloat PRIVATE
    SOFTFLOAT_ROUND_ODD
    INLINE_LEVEL=5
    SOFTFLOAT_FAST_DIV32TO16
    SOFTFLOAT_FAST_DIV64TO32
    SOFTFLOAT_FAST_INT64
)

set_source_files_properties(
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    PROPERTIES SKIP_LINTING ON
)
