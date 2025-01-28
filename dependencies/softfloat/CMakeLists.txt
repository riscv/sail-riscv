SET(source_dir "${CMAKE_CURRENT_SOURCE_DIR}/berkeley-softfloat-3")

# Generic source plus RISC-V specific source.
file(GLOB riscv_source
    "${source_dir}/source/*.c"
    "${source_dir}/source/include/*.h"
    "${source_dir}/source/RISCV/*.c"
    "${source_dir}/source/RISCV/*.h"
    "${source_dir}/build/Linux-RISCV-GCC/platform.h"
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
    "${source_dir}/source/include"
    "${source_dir}/source/RISCV"
    "${source_dir}/build/Linux-RISCV-GCC"
)

target_compile_options(softfloat PRIVATE "-Werror=implicit-function-declaration" "-DSOFTFLOAT_ROUND_ODD")
