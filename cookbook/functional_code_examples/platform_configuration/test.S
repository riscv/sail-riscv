// vim: tabstop=2  shiftwidth=2  expandtab
// --------------------------------------------------------------------------------------------
// File:          test.S
//
// Description:
//
// Author:        Bill McSpadden (bill@riscv.org)
// --------------------------------------------------------------------------------------------

// --------------------------------------------------------
// Support for 32/64 bit compilation.

#if __riscv_xlen == 64
# define LREG ld
# define SREG sd
# define REGBYTES 8
#else
# define LREG lw
# define SREG sw
# define REGBYTES 4
#endif


// --------------------------------------------------------
// Support for tohost/fromhost

#define PASS_CODE       1
#define FAIL_CODE       1337


// --------------------------------------------------------
// Following power-on reset, we start executing at _start.
//  We jump to "reset_vector"
//
//  .section ".text.init"
  .section ".rotext.init"
  .globl _start
_start:
// The following is a re-write of the "rom" code that is
//  in riscv_sim.c (around lines 509-521).  I want to get
//  rid of that bit of code in riscv_sim.c

//  auipc t0,       0x0
  auipc x5,       0x0
//  addi  a1,       t0, &dtb    // What is dtb???
  addi  x11,      x5, (8 * 4)   // What is the purpose of this instruction?
//  csrr  a0,       mhartid
  csrr  x10,       mhartid
//  LREG  t0,       24(t0)
  la    t0,       reset_vector
  jr    t0



// --------------------------------------------------------


//  .section ".text"
  .section ".text.begin"
  .global reset_vector    // This pushed the symbol, reset_vector, to 0x80000000
// --------------------------------------------------------
// Initialization of the processor, starting with the 
//  register file.
reset_vector:

  li    x1,       0
  li    x2,       0
  li    x3,       0
  li    x4,       0
  li    x5,       0
  li    x6,       0
  li    x7,       0
  li    x8,       0
  li    x9,       0
  li    x10,      0
  li    x11,      0
  li    x12,      0
  li    x13,      0
  li    x14,      0
  li    x15,      0
  li    x16,      0
  li    x17,      0
  li    x18,      0
  li    x19,      0
  li    x20,      0
  li    x21,      0
  li    x22,      0
  li    x23,      0
  li    x24,      0
  li    x25,      0
  li    x26,      0
  li    x27,      0
  li    x28,      0
  li    x29,      0
  li    x30,      0
  li    x31,      0

// --------------------------------------------------------
// PMP configuration

  # configure pmp to enable all accesses
  li    t0,       0x1f
  csrw  pmpcfg0,  t0
  li    t0,       0xffffffff
  csrw  pmpaddr0, t0


// --------------------------------------------------------
// PASS: The end of the test,  if successful
j_target_end_pass:
  // exit code construction
  li    x10,      PASS_CODE
  la    x13,      tohost
  sw    x10,      0(x13)
  la    x5,       j_target_end_pass
  jalr  x5
  j     j_target_end_fail                       // should never be taken

// --------------------------------------------------------

// --------------------------------------------------------
// FAIL: The end of the test,  if unsuccessful
j_target_end_fail:
  // exit code construction
  li    x10,      FAIL_CODE
  la    x13,      tohost
  sw    x10,      0(x13)
  la    x5,       j_target_end_fail
  jalr  x5


// --------------------------------------------------------
// Memory locations for specific usage.
.section ".tdata.begin"
.globl _tdata_begin
_tdata_begin:

.section ".tdata.end"
.globl _tdata_end
_tdata_end:

.section ".tbss.end"
.globl _tbss_end
_tbss_end:

.section ".tohost","aw",@progbits
.align 6
.globl tohost
tohost: .dword 0

.section ".fromhost","aw",@progbits
.align 6
.globl fromhost
fromhost: .dword 0

.align 6
.global timer_interrupt_flag
timer_interrupt_flag: .dword 0




