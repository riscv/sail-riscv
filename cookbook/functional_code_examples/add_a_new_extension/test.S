// vim: tabstop=2  shiftwidth=2  expandtab
// --------------------------------------------------------------------------------------------
/// @file       test.S
///
///
/// @brief      RISC-V asm code for testing  an example custom instruction
///
/// @author     Bill McSpadden (RISC-V Internation) (bill@riscv.org)
// --------------------------------------------------------------------------------------------

#ifndef CONFIG_BASE
#error The C pre-processor variable, CONFIG_BASE, must be set.
#endif

// --------------------------------------------------------
// Support for a custom extension

#define X_XMPL_OPCODE   (0x2b)    // inst[6:5] == 01, inst[4:2] == 1011  -->  custom-0
#define X_XMPL(__imm__)  .word (__imm__ << 7)  | (X_XMPL_OPCODE << 0)

#define XO    (0)
#define X1    (1)
#define X2    (2)
#define X3    (3)
#define X4    (4)
#define X5    (5)
#define X6    (6)
#define X7    (7)
#define X8    (8)
#define X9    (9)
#define X10   (10)
#define X11   (11)
#define X12   (12)
#define X13   (13)
#define X14   (14)
#define X15   (15)
#define X16   (16)
#define X17   (17)
#define X18   (18)
#define X19   (19)
#define X20   (20)
#define X21   (21)
#define X22   (22)
#define X23   (23)
#define X24   (24)
#define X25   (25)
#define X26   (26)
#define X27   (27)
#define X28   (28)
#define X29   (29)
#define X30   (30)
#define X31   (31)




// --------------------------------------------------------
// Memory-mapped machine timer registers and other support
//  for generating a timer interrupt

//#define MMR_MTIMEL      (CONFIG_BASE + 0x0000)
//#define MMR_MTIMEH      (CONFIG_BASE + 0x0004)
//#define MMR_MTIMECMPL   (CONFIG_BASE + 0x0008)
//#define MMR_MTIMECMPH   (CONFIG_BASE + 0x000C)

#define MMR_MTIMEL      (CONFIG_BASE + 0xbff8)
#define MMR_MTIMEH      (CONFIG_BASE + 0xbffc)
#define MMR_MTIMECMPL   (CONFIG_BASE + 0x4000)
#define MMR_MTIMECMPH   (CONFIG_BASE + 0x4004)

#define TIMER_COUNT     (100)
#define WATCHDOG_COUNT  (100000)

#define MSTATUS_MIE     0x00000008
#define MSTATUS_FS      0x00006000
#define MSTATUS_XS      0x00018000

#define MIE_MTIE        0x80


// --------------------------------------------------------
// mcause bit definitions

#define MCAUSE_SUPERVISOR_SOFTWARE_INTERRUPT    (0x1 << (__riscv_xlen - 1) + 1)
#define MCAUSE_MACHINE_TIMER_INTERRUPT          (0x1 << (__riscv_xlen - 1) + 7)
#define MCAUSE_ILLEGAL_INSTRUCTION              (0x0 << (__riscv_xlen - 1) + 2)

// --------------------------------------------------------
// Support for tohost/fromhost

#define PASS_CODE       1
#define FAIL_CODE       1337


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

#define XMPL_CSR    (0xfc0)
#define XMPL_CSR_2  (0xfc1)

// --------------------------------------------------------
// Following power-on reset, we start executing at _start.
//  We jump to "reset_vector"
//
  .section ".text.init"
  .globl _start
_start:
  la    x5,   reset_vector
  jr    x5
// --------------------------------------------------------


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
// initialize machine trap vector
  la    x5,       machine_trap_entry
  csrw  mtvec,    x5


// --------------------------------------------------------
//  The test!

the_test_begin:
  X_XMPL(0x0dead)
  csrr  x3, XMPL_CSR_2

//  li    x4, 0x76543210
//  csrw  XMPL_CSR_2, x4    // Q: What happens to a write to a read-only csr?
//                          // A: illegal_instruction trap
the_test_end:




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
// In support of vectored interrupt,  although it's not
//  being used in this test.

  .align 4
machine_trap_entry:
  j     machine_trap_entry_0
  .align 2
  j     machine_trap_entry_1
  .align 2
  j      machine_trap_entry_2
  .align 2
  j      machine_trap_entry_3
  .align 2
  j      machine_trap_entry_4
  .align 2
  j      machine_trap_entry_5
  .align 2
  j      machine_trap_entry_6
  .align 2
  j      machine_trap_entry_7
  .align 2
  j      machine_trap_entry_8
  .align 2
  j      machine_trap_entry_9
  .align 2
  j      machine_trap_entry_10
  .align 2
  j      machine_trap_entry_11
// --------------------------------------------------------


// --------------------------------------------------------
  .align 2
machine_trap_entry_0:
  csrr    x7,       mcause
  li      x6,       MCAUSE_MACHINE_TIMER_INTERRUPT
  bne     x7,       x6,     not_a_timer_interrupt
  li      x6,       0x1
  la      x7,       timer_interrupt_flag
  sw      x6,       0(x7)

  // Turn off timer interrupt. No longer needed
  addi    x7,       x0,     MIE_MTIE
  csrc    mie,      x7
  
  // Clear interrupt
  li      x7,       MSTATUS_MIE
  csrc    mstatus,  x7

  // and return
  mret

not_a_timer_interrupt:
  // Do not try and correct the opcode,  and do not
  //    do an mret. This should probably be the last
  //    part of this simple test.
  csrr    x7,       mcause
  li      x6,       MCAUSE_ILLEGAL_INSTRUCTION
  j       j_target_end_fail
// --------------------------------------------------------

// --------------------------------------------------------
// None of these machine traps should have been taken
//  Jump to test failure
machine_trap_entry_1:
machine_trap_entry_2:
machine_trap_entry_3:
machine_trap_entry_4:
machine_trap_entry_5:
machine_trap_entry_6:
machine_trap_entry_7:
machine_trap_entry_8:
machine_trap_entry_9:
machine_trap_entry_10:
machine_trap_entry_11:
  csrr    x7,       mcause        // Do the read so that it appears in the log file for debug.
  j       j_target_end_fail
// --------------------------------------------------------



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




