#include "common/encoding.h"

// Tests for the Zalasr load-acquire and store-release instructions.
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

// l{b,h,w,d}.{aq,aqrl} t2, (t0), with an optional (reserved) non-zero rs2 field.
#define LOAD_ACQUIRE_ENC(aq, rl, rs2, width) \
  ((ZALASR_LOAD_FUNCT5 << 27) | ((aq) << 26) | ((rl) << 25) | ((rs2) << 20) | \
   (REG_ADDR << 15) | ((width) << 12) | (REG_DEST << 7) | 0x2f)

// s{b,h,w,d}.{rl,aqrl} t1, (t0), with an optional (reserved) non-zero rd field.
#define STORE_RELEASE_ENC(aq, rl, rd, width) \
  ((ZALASR_STORE_FUNCT5 << 27) | ((aq) << 26) | ((rl) << 25) | (REG_DATA << 20) | \
   (REG_ADDR << 15) | ((width) << 12) | ((rd) << 7) | 0x2f)

#if __riscv_xlen == 64
#define REG_S sd
#define REG_L ld
#else
#define REG_S sw
#define REG_L lw
#endif

// Load `target` with a load-acquire and check the sign-extended result.
.macro test_load_acquire rl, width, target, expected
  la t0, \target
  li t2, 0
  .4byte LOAD_ACQUIRE_ENC(1, \rl, 0, \width)
  li t3, \expected
  bne t2, t3, fail
.endm

// Fill `store_buf` with 0xff bytes, store-release `value` into it, and
// check that only the low `width` bytes were written.
.macro test_store_release aq, width, value
  la t0, store_buf
  li t3, -1
  sw t3, 0(t0)
  sw t3, 4(t0)
  sw t3, 8(t0)
  li t1, \value
  .4byte STORE_RELEASE_ENC(\aq, 1, 0, \width)
  call check_store_\width
.endm

// Execute `word` and check that it raises an illegal-instruction exception.
.macro check_illegal word
  li s4, 0
  .4byte \word
  beqz s4, fail
.endm

.global main
main:
  addi sp, sp, -32
  REG_S ra, 0(sp)
  REG_S s0, 8(sp)
  REG_S s4, 16(sp)
  csrr s0, mtvec
  la t0, illegal_handler
  csrw mtvec, t0

  // Load-acquire: results are always sign-extended.
  test_load_acquire 0, WIDTH_B, signed_byte, -128
  test_load_acquire 1, WIDTH_B, signed_byte, -128
  test_load_acquire 0, WIDTH_H, signed_half, -32767
  test_load_acquire 1, WIDTH_H, signed_half, -32767
  test_load_acquire 0, WIDTH_W, signed_word, -2147483647
  test_load_acquire 1, WIDTH_W, signed_word, -2147483647
  test_load_acquire 0, WIDTH_B, positive_byte, 0x7f
  test_load_acquire 1, WIDTH_H, positive_half, 0x7ffe

  // Store-release: only the low bits of rs2 are stored.
  test_store_release 0, WIDTH_B, 0x5a
  test_store_release 1, WIDTH_B, 0x5a
  test_store_release 0, WIDTH_H, 0x5aa5
  test_store_release 1, WIDTH_H, 0x5aa5
  test_store_release 0, WIDTH_W, 0x12345678
  test_store_release 1, WIDTH_W, 0x12345678

  // Reserved load-acquire encodings without aq.
  check_illegal LOAD_ACQUIRE_ENC(0, 0, 0, WIDTH_W)
  check_illegal LOAD_ACQUIRE_ENC(0, 1, 0, WIDTH_W)
  // rs2 must be zero for load-acquire.
  check_illegal LOAD_ACQUIRE_ENC(1, 0, 1, WIDTH_W)
  // Reserved store-release encodings without rl.
  check_illegal STORE_RELEASE_ENC(0, 0, 0, WIDTH_W)
  check_illegal STORE_RELEASE_ENC(1, 0, 0, WIDTH_W)
  // rd must be zero for store-release.
  check_illegal STORE_RELEASE_ENC(0, 1, 1, WIDTH_W)

#if __riscv_xlen == 64
  test_load_acquire 0, WIDTH_D, signed_double, 0x8000000000000001
  test_load_acquire 1, WIDTH_D, signed_double, 0x8000000000000001
  test_load_acquire 0, WIDTH_W, signed_word, 0xffffffff80000001
  test_store_release 0, WIDTH_D, 0x0123456789abcdef
  test_store_release 1, WIDTH_D, 0x0123456789abcdef
  // The upper bits of rs2 are ignored for narrower stores.
  test_store_release 0, WIDTH_W, 0xdeadbeef12345678
#else
  // ld.{aq,aqrl} and sd.{rl,aqrl} are RV64-only.
  check_illegal LOAD_ACQUIRE_ENC(1, 0, 0, WIDTH_D)
  check_illegal LOAD_ACQUIRE_ENC(1, 1, 0, WIDTH_D)
  check_illegal STORE_RELEASE_ENC(0, 1, 0, WIDTH_D)
  check_illegal STORE_RELEASE_ENC(1, 1, 0, WIDTH_D)
#endif

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
  addi sp, sp, 32
  ret

// Each checker verifies the stored bytes in `store_buf` and that the
// following bytes still hold 0xff. On entry t1 holds the stored value.
check_store_0:
  la t0, store_buf
  lbu t3, 0(t0)
  andi t4, t1, 0xff
  bne t3, t4, fail
  lbu t3, 1(t0)
  li t4, 0xff
  bne t3, t4, fail
  ret

check_store_1:
  la t0, store_buf
  lhu t3, 0(t0)
  slli t4, t1, (__riscv_xlen - 16)
  srli t4, t4, (__riscv_xlen - 16)
  bne t3, t4, fail
  lbu t3, 2(t0)
  li t4, 0xff
  bne t3, t4, fail
  ret

check_store_2:
  la t0, store_buf
  lw t3, 0(t0)
#if __riscv_xlen == 64
  sext.w t4, t1
#else
  mv t4, t1
#endif
  bne t3, t4, fail
  lbu t3, 4(t0)
  li t4, 0xff
  bne t3, t4, fail
  ret

#if __riscv_xlen == 64
check_store_3:
  la t0, store_buf
  ld t3, 0(t0)
  bne t3, t1, fail
  lbu t3, 8(t0)
  li t4, 0xff
  bne t3, t4, fail
  ret
#endif

.p2align 6
illegal_handler:
  csrr t5, mcause
  li t6, CAUSE_ILLEGAL_INSTRUCTION
  bne t5, t6, fail
  li s4, 1
  csrr t5, mepc
  addi t5, t5, 4
  csrw mepc, t5
  mret

.section .rodata
.balign 8
signed_double:
  .8byte 0x8000000000000001
signed_word:
  .4byte 0x80000001
signed_half:
  .2byte 0x8001
signed_byte:
  .byte 0x80
positive_byte:
  .byte 0x7f
.balign 2
positive_half:
  .2byte 0x7ffe

.data
.balign 8
store_buf:
  .8byte 0
  .8byte 0
