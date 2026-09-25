// c.sw / c.lw: MEM D 4, plus a compressed or 4-byte fetch record.

#include "common/encoding.h"

.global main
main:
    la      a0, rvvi_cscratch
    li      a1, 0x11223344
.option push
.option rvc
    c.sw    a1, 0(a0)
    c.lw    a2, 0(a0)
.option pop

    li      a0, 0
    ret

.bss
.balign 8
rvvi_cscratch:
    .zero 16
