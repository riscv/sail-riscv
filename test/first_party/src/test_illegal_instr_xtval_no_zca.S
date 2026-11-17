#include "common/encoding.h"

// When Zca is disabled (misa.C = 0), IALIGN is 32 and there are no 16-bit
// instructions, so an encoding whose low two bits are not 0b11 is a 32-bit
// illegal instruction. The illegal-instruction exception must write all 32
// bits of it to mtval, not just the low 16 bits.
// See https://github.com/riscv/sail-riscv/issues/2122

#define MISA_C_BIT (1 << ('C' - 'A'))

// Everything here runs with misa.C cleared, so it must not use compressed
// instructions.
.option norvc

// Execute `word` and check that it raises an illegal-instruction exception
// with mtval == word and mepc pointing at it.
.macro check_illegal word
  li s2, \word
  la s3, 1f
  li s4, 0
1:
  .word \word
  beqz s4, fail
.endm

.balign 4
.global main
main:
  csrr s0, mtvec
  la t0, illegal_handler
  csrw mtvec, t0

  // Disable C. The write takes effect because the next PC is 4-byte aligned.
  li s1, MISA_C_BIT
  csrc misa, s1
  csrr t0, misa
  and t0, t0, s1
  bnez t0, fail

  // Low bits 0b00, 0b01 and 0b10 with non-zero upper halves.
  check_illegal 0x12340000
  check_illegal 0x56780001
  check_illegal 0x7abcfffe
  // Bits [15:0] are all zero, which is still a 32-bit instruction without Zca.
  check_illegal 0x00010000

pass:
  li a0, 0
  j done
fail:
  li a0, 1
done:
  // Restore C and the original trap handler before returning to the
  // (compressed) runtime.
  csrs misa, s1
  csrw mtvec, s0
  ret

.p2align 6
illegal_handler:
  csrr t0, mcause
  li t1, CAUSE_ILLEGAL_INSTRUCTION
  bne t0, t1, fail
  csrr t0, mepc
  bne t0, s3, fail
  csrr t0, mtval
  bne t0, s2, fail
  li s4, 1
  addi t0, s3, 4
  csrw mepc, t0
  mret
