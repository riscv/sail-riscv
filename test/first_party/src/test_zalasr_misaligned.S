#include "common/encoding.h"

// Tests that misaligned Zalasr load-acquire and store-release
// instructions follow the AMO misaligned exception setting rather than
// the scalar load/store one.  This test is run with
// `zalasr_misaligned.json`, which allows misaligned scalar loads/stores
// but raises address-misaligned exceptions for misaligned AMOs.
//
// The instructions are emitted as raw encodings so that the test does
// not depend on assembler support for Zalasr.

#define ZALASR_LOAD_FUNCT5 0x06
#define ZALASR_STORE_FUNCT5 0x07

#define WIDTH_B 0
#define WIDTH_H 1
#define WIDTH_W 2
#define WIDTH_D 3

// Register numbers: t0 = x5 (address), t1 = x6 (store data), t2 = x7 (load dest).
#define REG_ADDR 5
#define REG_DATA 6
#define REG_DEST 7

// l{b,h,w,d}.{aq,aqrl} t2, (t0)
#define LOAD_ACQUIRE_ENC(rl, width) \
  ((ZALASR_LOAD_FUNCT5 << 27) | (1 << 26) | ((rl) << 25) | \
   (REG_ADDR << 15) | ((width) << 12) | (REG_DEST << 7) | 0x2f)

// s{b,h,w,d}.{rl,aqrl} t1, (t0)
#define STORE_RELEASE_ENC(aq, width) \
  ((ZALASR_STORE_FUNCT5 << 27) | ((aq) << 26) | (1 << 25) | (REG_DATA << 20) | \
   (REG_ADDR << 15) | ((width) << 12) | 0x2f)

#if __riscv_xlen == 64
#define REG_S sd
#define REG_L ld
#else
#define REG_S sw
#define REG_L lw
#endif

// Execute `word` with t0 = buf + `offset` and check that it raises
// exception `cause` with mtval equal to the address.
.macro check_misaligned word, offset, cause
  la t0, buf
  addi t0, t0, \offset
  li s4, 0
  .4byte \word
  beqz s4, fail
  li t3, \cause
  bne s5, t3, fail
  bne s6, t0, fail
.endm

// Execute `word` with t0 = buf + `offset` and check that it does not trap.
.macro check_no_trap word, offset
  la t0, buf
  addi t0, t0, \offset
  li s4, 0
  .4byte \word
  bnez s4, fail
.endm

.global main
main:
  addi sp, sp, -48
  REG_S ra, 0(sp)
  REG_S s0, 8(sp)
  REG_S s4, 16(sp)
  REG_S s5, 24(sp)
  REG_S s6, 32(sp)
  csrr s0, mtvec
  la t0, trap_handler
  csrw mtvec, t0

  // Misaligned load-acquire raises a load address-misaligned exception.
  check_misaligned LOAD_ACQUIRE_ENC(0, WIDTH_H), 1, CAUSE_MISALIGNED_LOAD
  check_misaligned LOAD_ACQUIRE_ENC(1, WIDTH_H), 1, CAUSE_MISALIGNED_LOAD
  check_misaligned LOAD_ACQUIRE_ENC(0, WIDTH_W), 2, CAUSE_MISALIGNED_LOAD
  check_misaligned LOAD_ACQUIRE_ENC(1, WIDTH_W), 1, CAUSE_MISALIGNED_LOAD

  // Misaligned store-release raises a store/AMO address-misaligned exception.
  li t1, 0x12345678
  check_misaligned STORE_RELEASE_ENC(0, WIDTH_H), 1, CAUSE_MISALIGNED_STORE
  check_misaligned STORE_RELEASE_ENC(1, WIDTH_H), 1, CAUSE_MISALIGNED_STORE
  check_misaligned STORE_RELEASE_ENC(0, WIDTH_W), 2, CAUSE_MISALIGNED_STORE
  check_misaligned STORE_RELEASE_ENC(1, WIDTH_W), 1, CAUSE_MISALIGNED_STORE

#if __riscv_xlen == 64
  check_misaligned LOAD_ACQUIRE_ENC(0, WIDTH_D), 4, CAUSE_MISALIGNED_LOAD
  check_misaligned STORE_RELEASE_ENC(0, WIDTH_D), 4, CAUSE_MISALIGNED_STORE
#endif

  // The faulting stores must not have modified memory.
  la t0, buf
  lw t3, 0(t0)
  bnez t3, fail
  lw t3, 4(t0)
  bnez t3, fail

  // Byte accesses and aligned accesses never fault.
  check_no_trap LOAD_ACQUIRE_ENC(0, WIDTH_B), 1
  check_no_trap STORE_RELEASE_ENC(0, WIDTH_B), 3
  check_no_trap LOAD_ACQUIRE_ENC(1, WIDTH_W), 4
  check_no_trap STORE_RELEASE_ENC(1, WIDTH_H), 6

  // Ordinary misaligned loads/stores are still allowed by the scalar setting.
  la t0, buf
  li s4, 0
  lw t3, 1(t0)
  sw t3, 1(t0)
  bnez s4, fail

pass:
  li a0, 0
  j done
fail:
  li a0, 1
done:
  csrw mtvec, s0
  REG_L ra, 0(sp)
  REG_L s0, 8(sp)
  REG_L s4, 16(sp)
  REG_L s5, 24(sp)
  REG_L s6, 32(sp)
  addi sp, sp, 48
  ret

// Record mcause in s5 and mtval in s6, set s4, and skip the instruction.
.p2align 6
trap_handler:
  csrr s5, mcause
  csrr s6, mtval
  li s4, 1
  csrr t5, mepc
  addi t5, t5, 4
  csrw mepc, t5
  mret

.data
.balign 8
buf:
  .8byte 0
  .8byte 0
