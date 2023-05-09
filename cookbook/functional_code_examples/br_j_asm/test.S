// vim: tabstop=2  shiftwidth=2  expandtab
// --------------------------------------------------------------------------------------------
/// @file       test.S
///
///             LICENSE:
///
///              Copyright 2021 Seagate Technology LLC and/or its Affiliates
///              
///              Licensed under the Apache License, Version 2.0 (the "License");
///              you may not use this file except in compliance with the License.
///              You may obtain a copy of the License at
///              
///                  http://www.apache.org/licenses/LICENSE-2.0
///              
///              Unless required by applicable law or agreed to in writing, software
///              distributed under the License is distributed on an "AS IS" BASIS,
///              WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///              See the License for the specific language governing permissions and
///              limitations under the License.
///
///
///
///
/// @brief      RISC-V asm code for testing code discontinuities with a RISC-V Trace encoder/decoder
///
///             This is a *simple-and-short* test for providing stimulus to the Trace Encoder Module.
///             Do we get the expected trace messages and can we create the instruction
///             trace from these messages? 
///
///             This test executes roughly 250 instructions.  It should generate most of
///             the basic trace messages.  It does NOT test the te_support and message_lost
///             messages.
///
///             The test generates a timer interrupt and a bad-opcode exception to check
///             for proper te_inst format 3 message behaviour.  The interrupt handler
///             uses an mret to return.  The bad-opcode exception handler does NOT perform
///             an 'mret';  instead it does a jump.
///
///             Assembly language tests are notoriously difficult to read.  This test is
///             worse than usual because I'm interested in testing forward and backward
///             branches and jumps.  So, target destinations are placed not for readability,
///             but to test certain aspects of the trace messages. Sorry.  
///
///             No stack is set up for use.
///
///             Threads are not used, supported or tested.
///
///             Privilege levels are not changed. Everything is run in machine mode.
///
///             With the exception of x0 (hardwired zero) and x1 (return address), all
///             registers are treated the same.  The programmer is responsible for
///             consistent use of the registers.  
///             
///             The convention for this test is to use the 'xN' nomenclature for register
///             names. This is to emphasize the fact that register usage is not
///             defined or enforced.
///
///             This test utilizes the Berkeley tohost / fromhost convention. The convention 
///             uses a pre-defined location in memory (label: 'tohost') to report
///             the success or failure of the test.  If M[tohost] == 1, the test passed.
///             If M[tohost] == 1337 (0x539), then the test failed.
///
///             One more important note:  the initialization of Trace module is beyond the 
///             scope of this test.  The user must properly configure the 
///             Trace module in order to get trace messages.
///
///
///
/// @author     Bill McSpadden (Seagate Technology)
// --------------------------------------------------------------------------------------------

#ifndef CONFIG_BASE
#error The C pre-processor variable, CONFIG_BASE, must be set.
#endif


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
// Other test support definitions...

#define BR_LOOP_COUNT   10    // For testing a simple br loop


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
// This block of code is placed (by placement in the code
//  stream,  not via the linker/loader) at a low address so
//  that we can test a backwards jump (ie - a jump that will
//  yield a negative offset).
   .section ".text"
j_target_0:
  nop
  nop
  la    x5,       j_target_2
  jalr  x5
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
// Initialization complete.  Now for a series of branches and jumps.

br_target_0:
  nop
  nop
  li    x5,       0
  beqz  x5,       br_target_1a      // This is a forward branch
  nop
  nop

br_target_1a:
  li    x5,       BR_LOOP_COUNT
  li    x6,       1
br_target_1:
  nop
  nop
  sub   x5,       x5,     x6
  bnez  x5,       br_target_1       // This is a backward branch
  nop
  nop

// --------------------------------------------------------
// Simple branches have been tested.  Now let's do some simple
//  tests of jumps.
br_target_2:
  nop
  nop
  j     j_target_1                  // forwards jump; tests for positive offset
  j     j_target_end_fail           // should never be taken

j_target_1:
  nop
  nop
  la    x5,       j_target_0        // backwards jump;  tests for negative offset
  jr    x5
  j     j_target_end_fail           // should never be taken
 
j_target_2:
  nop
  nop
  la    x5,       timer_interrupt_test
  jalr  x5
  j     j_target_end_fail           // should never be taken

j_exception_stimulus:
  //  Now,  jump to a location that has an opcode of 0
  //    This is an important test condition for RISC-V. The
  //    spec says that an except'd instruction is not retired.
  //    Yet, we really need to see the address of 'bad_opcode'.
  //    The trace spec handles this condition in that the address
  //    of the except'd instruction gets reported out in a message.
  //    Let's test it out....
  //
  //    Note that the excpetion handler for this case will *NOT* do an
  //    mret.  It will jump to 'illegal_instruction_exception_return'.  

  la    x5,       bad_opcode
  jr    x5
  j     j_target_end_fail           // should never be taken

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

illegal_instruction_exception_return:
  la    x5,       j_target_end_pass
  jalr  x5
  j     j_target_end_fail // should never be taken

// --------------------------------------------------------
timer_interrupt_return:
  la    x5,       j_exception_stimulus
  jalr  x5
  j     j_target_end_fail // should never be taken


// --------------------------------------------------------
// Now check to see if we can trace an interrupt.  We'll use
//  a timer to generate the interrupt.

timer_interrupt_test:
  addi  x7,       x0,     TIMER_COUNT
  
  lui   x8,       MMR_MTIMECMPL >> 12
  sw    x7,       (MMR_MTIMECMPL & 0xfff)(x8)

  lui   x8,       MMR_MTIMECMPH >> 12
  sw    x0,       (MMR_MTIMECMPH & 0xfff)(x8)

  addi  x7,       x0,     MIE_MTIE
  csrs  mie,      x7

  xor   x8,       x8,     x8                      // Clear the register
  csrr  x8,       mstatus

  addi  x7,       x0,     MSTATUS_MIE
  csrs  mstatus,  x7

  # Should get a timer interrupt sometime after setting mstatus.MIE

  li    x6,       WATCHDOG_COUNT                  // start count
  li    x4,       1                               // decrement value

timer_interrupt_long_loop:

  // Check to see if the timer interrupt handler wrote a memory
  //  location.
  la    x10,      timer_interrupt_flag
  lw    x10,      0(x10)
  li    x11,      0x1
  beq   x10,      x11, timer_interrupt_return     // this is the expected way to exit this loop.
                                                  //  a timer interrupt is taken somewhere in the execution of this loop.
                                                  //  the ISR for the timer will write the time interrupt flag to 1.

  sub   x6,       x6,     x4                      // decrement the loop count
  csrr  x8,       mip                             // show mip in trace for debug
  xor   x8,       x8,     x8
  csrr  x9,       mstatus                         // show mstatus in trace for debug
  xor   x9,       x9,     x9
  bnez  x6,       timer_interrupt_long_loop       // iterate again.....

  j     j_target_end_fail                         // If we get here, timer_interrupt_flag was never written.
                                                  //  this is probably due to the timer interrupt service routine
                                                  //  never being called, which is probably because the interrupt
                                                  //  never happened.  failure


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
  beq     x7,       x6,     illegal_instruction_exception_return
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
// Put a bad opcode (0x0000_0000) in memory as a bad opcode.
bad_opcode:
  .word  0
  j       j_target_end_fail   // Should never get here.
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




