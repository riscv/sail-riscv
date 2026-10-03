#include "common/encoding.h"

# Check the source EEW overlap rule for indexed segment stores. The data
# register groups (vs3 and the following fields) are read with EEW=SEW and
# the index register group (vs2) with the index EEW. When the two EEWs
# differ, vs2 must not overlap any of the fields, not only the first one;
# otherwise the encoding is reserved. This is reserved behaviour so this
# test is specific to the default configuration of the Sail model.
#
# All instructions run with vl=0, so no memory is accessed.

# Expect `insn` to execute without a trap.
.macro expect_legal insn:vararg
    li t3, 0
    \insn
.endm

# Expect `insn` to raise an illegal instruction exception.
.macro expect_illegal insn:vararg
    la t3, 1f
    la t4, 2f
1:
    \insn
    j fail
2:
.endm

.global main
main:
    # Save return address in temporary register we're not using.
    mv t6, ra

    # Enable vector.
    li t0, MSTATUS_VS
    csrs mstatus, t0

    # Set trap handler
    la t0, trap_handler
    csrw mtvec, t0

    # SEW=32, LMUL=1, 2 fields: the data register groups are v2 and v3.
    # 8-bit indices have EMUL=1/4, so the index register group is one register.
    vsetivli zero, 0, e32, m1, ta, ma

    expect_legal vsuxseg2ei8.v v2, (a0), v1
    expect_legal vsuxseg2ei8.v v2, (a0), v4
    expect_legal vsoxseg2ei8.v v2, (a0), v4

    # Index register is the first field.
    expect_illegal vsuxseg2ei8.v v2, (a0), v2
    # Index register is the second field.
    expect_illegal vsuxseg2ei8.v v2, (a0), v3
    expect_illegal vsoxseg2ei8.v v2, (a0), v3

    # 4 fields: v4, v5, v6 and v7.
    expect_illegal vsuxseg4ei16.v v4, (a0), v7
    expect_legal vsuxseg4ei16.v v4, (a0), v8

    # Same EEW for data and indices: overlap is allowed.
    expect_legal vsuxseg2ei32.v v2, (a0), v3

    # SEW=32, LMUL=2, 2 fields: the data register groups are v4-v5 and v6-v7.
    # 16-bit indices have EMUL=1.
    vsetivli zero, 0, e32, m2, ta, ma

    expect_legal vsuxseg2ei16.v v4, (a0), v3
    expect_legal vsuxseg2ei16.v v4, (a0), v8
    expect_illegal vsuxseg2ei16.v v4, (a0), v5
    expect_illegal vsuxseg2ei16.v v4, (a0), v6
    expect_illegal vsuxseg2ei16.v v4, (a0), v7

    # SEW=8, LMUL=1 with 16-bit indices: the index register group has EMUL=2,
    # so it is larger than each of the data register groups.
    vsetivli zero, 0, e8, m1, ta, ma

    expect_illegal vsuxseg2ei16.v v3, (a0), v4
    expect_illegal vsuxseg3ei16.v v1, (a0), v2
    expect_legal vsuxseg2ei16.v v2, (a0), v4

    j pass

.balign 4
trap_handler:
    la t2, fail

    # If mcause != ILLEGAL, return to `fail`.
    csrr t0, mcause
    li t1, CAUSE_ILLEGAL_INSTRUCTION
    bne t0, t1, 1f

    # If mepc != the instruction expected to trap, return to `fail`.
    csrr t0, mepc
    bne t0, t3, 1f

    # Otherwise continue after the instruction.
    mv t2, t4
1:
    csrw mepc, t2
    mret

pass:
    li a0, 0
    mv ra, t6
    ret
fail:
    li a0, 1
    mv ra, t6
    ret
