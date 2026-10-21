#include "common/encoding.h"

# Test to check data compares for triggers are done using the right width.
#
# Sized (select = 1) data triggers with value matches.
#   case  match    size  access  value  tdata2                low-N-bit compare (spec)
#   0     eq         8     sb      0x55   0xFFFFFFFFFFFFFF55    fire
#   1     ge         8     sb      0x60   0xFFFFFFFFFFFFFF55    fire
#   2     lt         8     sb      0x60   0x0000000000000155    no fire
#   3     ne         8     sb      0x55   0xFFFFFFFFFFFFFF55    no fire
#   4     eq        32     sw      0x55   0xFFFFFFFF00000055    fire
#   5     mask-lo    8     sb      0x55   0xFFFFFF0F55555505    fire
#   6     mask-hi    8     sb      0x55   0xFFFFFF0F55555505    no-fire
#   7     mask-hi    8     sb      0x55   0xFFFFFFFF55555500    fire
#   M=8 N=8
#   8  napot         8     sb      0x55   0x557FFFFFFFFFFFFF    fire
#   9  napot         8     sb      0x60   0x557FFFFFFFFFFFFF    no fire
#   M=8 N=16
#  10  napot         16    sh      0x55   0x557FFFFFFFFFFFFF    no fire
#  11  napot         16    sh      0x55   0x007FFFFFFFFFFFFF    fire
#   M=16 N=8
#  12  napot         8     sb      0x55   0x55607FFFFFFFFFFF    fire
#  13  napot         8     sb      0x60   0x55607FFFFFFFFFFF    no fire

/* type 6, select = 1 (data), m, store */
#if __riscv_xlen == 32
#define BASE   0x60200042
#else
#define BASE   0x6000000000200042
#endif

#define SIZE8  (1 << 16)
#define SIZE16 (2 << 16)
#define SIZE32 (3 << 16)

#define MATCH_EQ     (0 << 7)
#define MATCH_NAPOT  (1 << 7)
#define MATCH_GE     (2 << 7)
#define MATCH_LT     (3 << 7)
#define MATCH_MASKLO (4 << 7)
#define MATCH_MASKHI (5 << 7)
#define MATCH_NE     (8 << 7)

# Each case is represented by the corresponding bit in KEPT and FIRED.
# KEPT tracks whether the trigger configuration was accepted, and
# FIRED tracks whether the trigger fired.

# All triggers should be kept
#define EXPECTED_KEPT  0x3FFF
# Firing should follow spec
#define EXPECTED_FIRED 0x19b3

.macro CASE idx, t1val, t2val, op, val, exp
  li    s2, 0                   # clear expected state
  csrw  tdata1, zero
  li    t1, \t2val
  csrw  tdata2, t1
  li    t2, \t1val
  csrw  tdata1, t2
  csrr  t3, tdata1
  bne   t3, t2, 1f
  li    t4, (1 << \idx)
  or    s1, s1, t4              # update KEPT
1:
  li    a1, \val
  \op   a1, 0(a0)
  csrw  tdata1, zero
  li    t1, \exp
  bne   s2, t1, fail            # check expected state
  beqz  s2, 2f                  # if trigger did not fire, skip update
  li    t4, (1 << \idx)
  or    s0, s0, t4              # update FIRED
2:
.endm

.global main
main:
  # Save return address in temporary register.
  mv t6, ra

  # Setup trap handler
  la    t0, test_trap_handler
  csrw  mtvec, t0
  csrsi 0x744, 0x8              # mnstatus.NMIE = 1 (Smrnmi); skipped if mnstatus is absent
  li    s0, 0                   # initialize FIRED
  li    s1, 0                   # initialize KEPT
  csrsi mstatus, 0x8            # MIE = 1 (interrupt-enable reentrancy)
  csrsi 0x7a5, 0x8              # tcontrol.MTE = 1 (tcontrol reentrancy); skipped if tcontrol is absent
  csrw  tselect, zero
  la    a0, scratch

case0:
#if __riscv_xlen == 32
  CASE 0, BASE|MATCH_EQ|SIZE8,          0xFFFFFF55, sb, 0x55, 1
#else
  CASE 0, BASE|MATCH_EQ|SIZE8,  0xFFFFFFFFFFFFFF55, sb, 0x55, 1
#endif

case1:
#if __riscv_xlen == 32
  CASE 1, BASE|MATCH_GE|SIZE8,          0xFFFFFF55, sb, 0x60, 1
#else
  CASE 1, BASE|MATCH_GE|SIZE8,  0xFFFFFFFFFFFFFF55, sb, 0x60, 1
#endif

case2:
#if __riscv_xlen == 32
  CASE 2, BASE|MATCH_LT|SIZE8,          0x00000155, sb, 0x60, 0
#else
  CASE 2, BASE|MATCH_LT|SIZE8,  0x0000000000000155, sb, 0x60, 0
#endif

case3:
#if __riscv_xlen == 32
  CASE 3, BASE|MATCH_NE|SIZE8,          0xFFFFFF55, sb, 0x55, 0
#else
  CASE 3, BASE|MATCH_NE|SIZE8,  0xFFFFFFFFFFFFFF55, sb, 0x55, 0
#endif

case4:
#if __riscv_xlen == 32
  CASE 4, BASE|MATCH_EQ|SIZE16,         0xFFFF0055, sh, 0x55, 1
#else
  CASE 4, BASE|MATCH_EQ|SIZE32, 0xFFFFFFFF00000055, sw, 0x55, 1
#endif

case5:
#if __riscv_xlen == 32
  CASE 5, BASE|MATCH_MASKLO|SIZE8,         0xFF0F5505, sb, 0x55, 1
#else
  CASE 5, BASE|MATCH_MASKLO|SIZE8, 0xFFFFFF0F55555505, sb, 0x55, 1
#endif

case6:
#if __riscv_xlen == 32
  CASE 6, BASE|MATCH_MASKHI|SIZE8,         0xFF0F5505, sb, 0x55, 0
#else
  CASE 6, BASE|MATCH_MASKHI|SIZE8, 0xFFFFFF0F55555505, sb, 0x55, 0
#endif

case7:
#if __riscv_xlen == 32
  CASE 7, BASE|MATCH_MASKHI|SIZE8,         0xFFFF5500, sb, 0x55, 1
#else
  CASE 7, BASE|MATCH_MASKHI|SIZE8, 0xFFFFFFFF55555500, sb, 0x55, 1
#endif

case8:
#if __riscv_xlen == 32
  CASE 8, BASE|MATCH_NAPOT|SIZE8,         0x557FFFFF, sb, 0x55, 1
#else
  CASE 8, BASE|MATCH_NAPOT|SIZE8, 0x557FFFFFFFFFFFFF, sb, 0x55, 1
#endif

case9:
#if __riscv_xlen == 32
  CASE 9, BASE|MATCH_NAPOT|SIZE8,         0x557FFFFF, sb, 0x60, 0
#else
  CASE 9, BASE|MATCH_NAPOT|SIZE8, 0x557FFFFFFFFFFFFF, sb, 0x60, 0
#endif

case10:
#if __riscv_xlen == 32
  CASE 10, BASE|MATCH_NAPOT|SIZE16,         0x557FFFFF, sh, 0x55, 0
#else
  CASE 10, BASE|MATCH_NAPOT|SIZE16, 0x557FFFFFFFFFFFFF, sh, 0x55, 0
#endif

case11:
#if __riscv_xlen == 32
  CASE 11, BASE|MATCH_NAPOT|SIZE16,         0x007FFFFF, sh, 0x55, 1
#else
  CASE 11, BASE|MATCH_NAPOT|SIZE16, 0x007FFFFFFFFFFFFF, sh, 0x55, 1
#endif

case12:
#if __riscv_xlen == 32
  CASE 12, BASE|MATCH_NAPOT|SIZE8,         0x55607FFF, sb, 0x55, 1
#else
  CASE 12, BASE|MATCH_NAPOT|SIZE8, 0x55607FFFFFFFFFFF, sb, 0x55, 1
#endif

case13:
#if __riscv_xlen == 32
  CASE 13, BASE|MATCH_NAPOT|SIZE8,         0x55607FFF, sb, 0x60, 0
#else
  CASE 13, BASE|MATCH_NAPOT|SIZE8, 0x55607FFFFFFFFFFF, sb, 0x60, 0
#endif

check:
  li    t2, EXPECTED_KEPT
  bne   s1, t2, fail
  li    t2, EXPECTED_FIRED
  bne   s0, t2, fail
pass:
  li a0, 0
  ret
fail:
  li a0, 1
  ret

# Flag breakpoints (mcause 3) in s2 and disable the trigger,
# and skip an illegal tcontrol access (mcause 2).
.balign 4
test_trap_handler:
  csrr  t3, mcause
  li    t4, 3
  beq   t3, t4, is_breakpoint_trap
  li    t4, 2
  bne   t3, t4, fail
  csrr  t4, mepc
  addi  t4, t4, 4
  csrw  mepc, t4
  mret
is_breakpoint_trap:
  addi  s2, s2, 1
  csrw  tdata1, zero
  mret

.data
.balign 8
scratch: .dword 0
