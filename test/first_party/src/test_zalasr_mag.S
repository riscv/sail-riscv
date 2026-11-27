#include "common/encoding.h"

// Tests misaligned Zalasr load-acquire and store-release instructions
// against the misaligned atomicity granule (MAG) PMA, using the default
// configuration. In that configuration, RAM has a 16-byte MAG, misaligned
// scalar loads/stores are allowed (and may be split), and misaligned AMOs
// outside the MAG raise an access fault.
//
// The spec requires a misaligned Zalasr access to be performed atomically
// if it lies within a MAG, and to raise an exception otherwise, so these
// instructions must behave like AMOs rather than ordinary loads/stores.
//
// The instructions are emitted as raw encodings so that the test does
// not depend on assembler support for Zalasr.

#define ZALASR_LOAD_FUNCT5 0x06
#define ZALASR_STORE_FUNCT5 0x07

#define WIDTH_H 1
#define WIDTH_W 2
#define WIDTH_D 3

// Register numbers: t0 = x5 (address), t1 = x6 (store data), t2 = x7 (load dest).
#define REG_ADDR 5
#define REG_DATA 6
#define REG_DEST 7

// l{h,w,d}.{aq,aqrl} t2, (t0)
#define LOAD_ACQUIRE_ENC(rl, width) \
  ((ZALASR_LOAD_FUNCT5 << 27) | (1 << 26) | ((rl) << 25) | \
   (REG_ADDR << 15) | ((width) << 12) | (REG_DEST << 7) | 0x2f)

// s{h,w,d}.{rl,aqrl} t1, (t0)
#define STORE_RELEASE_ENC(aq, width) \
  ((ZALASR_STORE_FUNCT5 << 27) | ((aq) << 26) | (1 << 25) | (REG_DATA << 20) | \
   (REG_ADDR << 15) | ((width) << 12) | 0x2f)

// amoadd.w t2, t1, (t0)
#define AMOADD_W_ENC 0x0062a3af

#if __riscv_xlen == 64
#define REG_S sd
#define REG_L ld
#else
#define REG_S sw
#define REG_L lw
#endif

// Execute `word` with t0 = buf + `offset` and check that it raises
// exception `cause` with mtval equal to the address.
.macro check_fault word, offset, cause
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

// Check that buf is still all zeros (faulting stores wrote nothing).
.macro check_buf_zero
  la t0, buf
  lw t3, 0(t0)
  bnez t3, fail
  lw t3, 4(t0)
  bnez t3, fail
  lw t3, 8(t0)
  bnez t3, fail
  lw t3, 12(t0)
  bnez t3, fail
  lw t3, 16(t0)
  bnez t3, fail
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

  // Misaligned accesses that cross a 16-byte granule raise an access
  // fault, as for AMOs. buf is 16-byte aligned.
  li t1, 0x12345678
  check_fault LOAD_ACQUIRE_ENC(0, WIDTH_H), 15, CAUSE_LOAD_ACCESS
  check_fault LOAD_ACQUIRE_ENC(1, WIDTH_W), 14, CAUSE_LOAD_ACCESS
  check_fault STORE_RELEASE_ENC(0, WIDTH_H), 15, CAUSE_STORE_ACCESS
  check_fault STORE_RELEASE_ENC(1, WIDTH_W), 13, CAUSE_STORE_ACCESS
#if __riscv_xlen == 64
  check_fault LOAD_ACQUIRE_ENC(0, WIDTH_D), 12, CAUSE_LOAD_ACCESS
  check_fault STORE_RELEASE_ENC(0, WIDTH_D), 9, CAUSE_STORE_ACCESS
#endif
  check_buf_zero

  // Reference: an AMO crossing the granule raises the same exception.
  check_fault AMOADD_W_ENC, 14, CAUSE_STORE_ACCESS
  check_buf_zero

  // Misaligned accesses within a granule succeed (atomically).
  li t1, 0x11223344
  check_no_trap STORE_RELEASE_ENC(0, WIDTH_W), 1
  li t2, 0
  check_no_trap LOAD_ACQUIRE_ENC(0, WIDTH_W), 1
  li t3, 0x11223344
  bne t2, t3, fail
  li t1, 0x5566
  check_no_trap STORE_RELEASE_ENC(1, WIDTH_H), 7
  li t2, 0
  check_no_trap LOAD_ACQUIRE_ENC(1, WIDTH_H), 7
  li t3, 0x5566
  bne t2, t3, fail
#if __riscv_xlen == 64
  li t1, 0x0123456789abcdef
  check_no_trap STORE_RELEASE_ENC(0, WIDTH_D), 20
  li t2, 0
  check_no_trap LOAD_ACQUIRE_ENC(0, WIDTH_D), 20
  bne t2, t1, fail
#endif

  // Ordinary misaligned loads/stores crossing the granule are still
  // allowed (they may be split).
  la t0, buf
  li s4, 0
  lw t3, 14(t0)
  sw t3, 14(t0)
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
.balign 16
buf:
  .fill 32, 1, 0
