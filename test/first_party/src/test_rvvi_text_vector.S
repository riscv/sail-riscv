// vle32.v / vse32.v: one MEM D per element.

#include "common/encoding.h"

.global main
main:
    // VS must be on; otherwise even vsetivli is illegal.
    li      t0, MSTATUS_VS
    csrs    mstatus, t0

    vsetivli t0, 8, e32, m1, ta, ma
    la      a0, rvvi_vec_src
    la      a1, rvvi_vec_dst
    vle32.v v1, (a0)
    vse32.v v1, (a1)

    li      a0, 0
    ret

.bss
.balign 16
rvvi_vec_src:
    .zero 64
rvvi_vec_dst:
    .zero 64
