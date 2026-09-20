// lb/lh/lw/(ld) and matching stores; MEM D width follows the access size.

#include "common/encoding.h"

.global main
main:
    la      t0, rvvi_scratch

    li      t1, 0xA1
    sb      t1, 0(t0)
    lb      t2, 0(t0)
    lbu     t3, 0(t0)

    li      t1, 0xB2B1
    sh      t1, 2(t0)
    lh      t2, 2(t0)
    lhu     t3, 2(t0)

    li      t1, 0xC4C3C2C1
    sw      t1, 4(t0)
    lw      t2, 4(t0)
#if __riscv_xlen == 64
    lwu     t3, 4(t0)
#endif

#if __riscv_xlen == 64
    li      t1, 0xD8D7D6D5D4D3D2D1
    sd      t1, 8(t0)
    ld      t2, 8(t0)
#endif

    li      a0, 0
    ret

.bss
.balign 16
rvvi_scratch:
    .zero 32
