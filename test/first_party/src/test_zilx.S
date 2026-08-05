#define ZILX_UNSCALED 0x12
#define ZILX_SCALED 0x1a
#define ZILX_SCALED_UW 0x1e

.macro zilx funct5, funct3
  .4byte ((\funct5 << 27) | (5 << 20) | (6 << 15) | (\funct3 << 12) | (7 << 7) | 0x2f)
.endm

.macro test_zilx funct5, funct3, target, index, offset, expected
  la t0, \target
  addi t0, t0, -\offset
  li t1, \index
  zilx \funct5, \funct3
  li t3, \expected
  bne t2, t3, fail
.endm

.global main
main:
  test_zilx ZILX_UNSCALED, 1, signed_half, 3, 3, -32767
  test_zilx ZILX_UNSCALED, 2, signed_word, 5, 5, -2147483647
  test_zilx ZILX_UNSCALED, 5, unsigned_half, 7, 7, 32769

  test_zilx ZILX_SCALED, 0, signed_byte, 3, 3, -128
  test_zilx ZILX_SCALED, 1, signed_half, 3, 6, -32767
  test_zilx ZILX_SCALED, 2, signed_word, 3, 12, -2147483647
  test_zilx ZILX_SCALED, 4, unsigned_byte, 3, 3, 128
  test_zilx ZILX_SCALED, 5, unsigned_half, 3, 6, 32769

#if __riscv_xlen == 64
  test_zilx ZILX_UNSCALED, 3, signed_double, 9, 9, 0x8000000000000001
  test_zilx ZILX_UNSCALED, 6, unsigned_word, 11, 11, 0x80000001

  test_zilx ZILX_SCALED, 3, signed_double, 3, 24, 0x8000000000000001
  test_zilx ZILX_SCALED, 6, unsigned_word, 3, 12, 0x80000001

  test_zilx ZILX_SCALED_UW, 0, signed_byte, 0xffffffff00000003, 3, -128
  test_zilx ZILX_SCALED_UW, 1, signed_half, 0xffffffff00000003, 6, -32767
  test_zilx ZILX_SCALED_UW, 2, signed_word, 0xffffffff00000003, 12, -2147483647
  test_zilx ZILX_SCALED_UW, 3, signed_double, 0xffffffff00000003, 24, 0x8000000000000001
  test_zilx ZILX_SCALED_UW, 4, unsigned_byte, 0xffffffff00000003, 3, 128
  test_zilx ZILX_SCALED_UW, 5, unsigned_half, 0xffffffff00000003, 6, 32769
  test_zilx ZILX_SCALED_UW, 6, unsigned_word, 0xffffffff00000003, 12, 0x80000001
#endif

  li a0, 0
  ret

fail:
  li a0, 1
  ret

.section .rodata
.balign 8
signed_byte:
  .byte 0x80
.balign 2
signed_half:
  .2byte 0x8001
.balign 4
signed_word:
  .4byte 0x80000001
.balign 8
signed_double:
  .8byte 0x8000000000000001
unsigned_byte:
  .byte 0x80
.balign 2
unsigned_half:
  .2byte 0x8001
.balign 4
unsigned_word:
  .4byte 0x80000001
