#include "common/encoding.h"

# Sized (select = 1) data triggers with value matches, RV64. Same reporting as mask_match.S.
#   case  match  size  access  value  tdata2                low-N-bit compare (spec)
#   0     eq     8     sb      0x55   0xFFFFFFFFFFFFFF55    fire
#   1     ge     8     sb      0x60   0xFFFFFFFFFFFFFF55    fire
#   2     lt     8     sb      0x60   0x0000000000000155    no fire
#   3     ne     8     sb      0x55   0xFFFFFFFFFFFFFF55    no fire
#   4     eq     32    sw      0x55   0xFFFFFFFF00000055    fire

/* type 6, select = 1 (data), m, store */
#if __riscv_xlen == 32
#define BASE   0x60200042
#else
#define BASE   0x6000000000200042
#endif

#define SIZE8  (1 << 16)
#define SIZE16 (2 << 16)
#define SIZE32 (3 << 16)

# Each case is represented by the corresponding bit in KEPT and FIRED.
# KEPT tracks whether the trigger configuration was accepted, and
# FIRED tracks whether the trigger fired.

# All triggers should be kept
#define EXPECTED_KEPT  0x1F
# Firing should follow spec
#define EXPECTED_FIRED 0x13

.macro CASE idx, t1val, t2val, op, val
  li    s2, 0
  csrw  tdata1, zero
  li    t1, \t2val
  csrw  tdata2, t1
  li    t2, \t1val
  csrw  tdata1, t2
  csrr  t3, tdata1
  bne   t3, t2, 1f
  ori   s1, s1, (1 << \idx)
1:
  li    a1, \val
  \op   a1, 0(a0)
  nop
  nop
  csrw  tdata1, zero
  beqz  s2, 2f
  ori   s0, s0, (1 << \idx)
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
  li    s0, 0                   # FIRED
  li    s1, 0                   # KEPT
  csrsi mstatus, 0x8            # MIE = 1 (interrupt-enable reentrancy)
  csrsi 0x7a5, 0x8              # tcontrol.MTE = 1 (tcontrol reentrancy); skipped if tcontrol is absent
  csrw  tselect, zero
  la    a0, scratch

case0:
#if __riscv_xlen == 32
  CASE 0, BASE|(0 << 7)|SIZE8,  0xFFFFFF55, sb, 0x55
#else
  CASE 0, BASE|(0 << 7)|SIZE8,  0xFFFFFFFFFFFFFF55, sb, 0x55
#endif

case1:
#if __riscv_xlen == 32
  CASE 1, BASE|(2 << 7)|SIZE8,  0xFFFFFF55, sb, 0x60
#else
  CASE 1, BASE|(2 << 7)|SIZE8,  0xFFFFFFFFFFFFFF55, sb, 0x60
#endif

case2:
#if __riscv_xlen == 32
  CASE 2, BASE|(3 << 7)|SIZE8,  0x00000155, sb, 0x60
#else
  CASE 2, BASE|(3 << 7)|SIZE8,  0x0000000000000155, sb, 0x60
#endif

case3:
#if __riscv_xlen == 32
  CASE 3, BASE|(8 << 7)|SIZE8,  0xFFFFFF55, sb, 0x55
#else
  CASE 3, BASE|(8 << 7)|SIZE8,  0xFFFFFFFFFFFFFF55, sb, 0x55
#endif

case4:
#if __riscv_xlen == 32
  CASE 4, BASE|(0 << 7)|SIZE16, 0xFFFF0055, sh, 0x55
#else
  CASE 4, BASE|(0 << 7)|SIZE32, 0xFFFFFFFF00000055, sw, 0x55
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
