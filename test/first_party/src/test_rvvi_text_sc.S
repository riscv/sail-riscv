// LR/SC: successful LR emits MEM D; a failing SC (no reservation) does not;
// a successful SC emits one MEM D for the store.

#include "common/encoding.h"

.global main
main:
    la      t0, rvvi_lrsc
#if __riscv_xlen == 64
    sd      zero, 8(t0)
    lr.d    t1, 0(t0)               // MEM D 8; reserves rvvi_lrsc
    la      t4, rvvi_lrsc_end       // different address, zero offset
    sc.d    t2, zero, 0(t4)         // fails, no MEM D
    lr.d    t1, 0(t0)
    sc.d    t2, zero, 0(t0)         // succeeds, MEM D 8
#else
    sw      zero, 4(t0)
    lr.w    t1, 0(t0)               // MEM D 4; reserves rvvi_lrsc
    la      t4, rvvi_lrsc_end       // different address, zero offset
    sc.w    t2, zero, 0(t4)         // fails, no MEM D
    lr.w    t1, 0(t0)
    sc.w    t2, zero, 0(t0)         // succeeds, MEM D 4
#endif

    li      a0, 0
    ret

.bss
.balign 16
rvvi_lrsc:
    .zero 8
rvvi_lrsc_end:
    .zero 8
