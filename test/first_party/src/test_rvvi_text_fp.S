// fld/fsd: F records and MEM D 8.

#include "common/encoding.h"

.global main
main:
    la      t0, rvvi_fscratch
    // 1.0 in IEEE-754 double = 0x3FF0000000000000
#if __riscv_xlen == 64
    li      t1, 0x3FF0000000000000
    sd      t1, 0(t0)
#else
    sw      zero, 0(t0)
    li      t1, 0x3FF00000
    sw      t1, 4(t0)
#endif
    fld     fa0, 0(t0)
    fsd     fa0, 8(t0)
    fld     fa1, 8(t0)

    li      a0, 0
    ret

.bss
.balign 16
rvvi_fscratch:
    .zero 32
