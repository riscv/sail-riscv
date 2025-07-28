SET(source_dir "${CMAKE_CURRENT_SOURCE_DIR}/berkeley-softfloat-3")

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

target_include_directories(softfloat PUBLIC
    "${source_dir}/build/Linux-x86_64-GCC"
    "${source_dir}/source/include"
    "${source_dir}/source/RISCV"
)

target_compile_options(softfloat PRIVATE
    -Werror=implicit-function-declaration
    -Wno-unused-parameter
    -Wno-unused-variable
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
