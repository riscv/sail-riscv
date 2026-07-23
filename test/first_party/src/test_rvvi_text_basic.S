// Basic RVVI-TEXT trace validation in M-mode: integer arithmetic (X),
// load/store (MEM D), CSR write (C), and ecall (TRAP). The crt0 ecall
// handler sets a0=-1 and mrets, so we override a0=0 before returning.

#include "common/encoding.h"

.global main
main:
    // Integer arithmetic -> X register changes
    li      a0, 100
    li      a1, 200
    add     a2, a0, a1              // a2 = 300

    // Memory store/load -> MEM D entries
    la      t0, rvvi_scratch
#if __riscv_xlen == 64
    sd      a2, 0(t0)
    ld      a3, 0(t0)
#else
    sw      a2, 0(t0)
    lw      a3, 0(t0)
#endif

    // CSR write -> C register change (mscratch is safe to write)
    li      t0, 0x42
    csrw    mscratch, t0

    // ecall -> TRAP line (crt0 handler sets a0=-1, mrets)
    li      a7, 0
    ecall

    li      a0, 0
    ret

.bss
rvvi_scratch:
    .zero 16
