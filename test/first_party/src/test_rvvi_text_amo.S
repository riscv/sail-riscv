// amoadd.w: read-modify-write, MEM D 4.
#include "common/encoding.h"

.global main
main:
    la      t0, rvvi_amo
    li      t1, 10
    sw      t1, 0(t0)
    li      t1, 7
    amoadd.w t2, t1, (t0)
    lw      t3, 0(t0)

    li      a0, 0
    ret

.bss
.balign 8
rvvi_amo:
    .zero 8
