#include "encoding.h"

#define MSTATUS_MPP_OFFSET 11

#define SYSCALL_SET_PRIVILEGE 0x541100
#define SYSCALL_GET_PRIVILEGE 0x541101

.section .text

.global _start
_start:
    j reset_handler

init_pmp:
    // Save the current mtvec before changing it
    csrr s1, mtvec
    // Set a trap handler that would just jump to 1:, in case PMPs are not supported
    la t0, 1f
    csrw mtvec, t0
    // Set a full match pmp address
    li t0, (1 << (31 + (__riscv_xlen / 64) * (53 - 31))) - 1
    csrw pmpaddr0, t0
    // Configure the above pmp to have full access
    li t0, PMP_NAPOT | PMP_R | PMP_W | PMP_X
    csrw pmpcfg0, t0
    // Fence and flush all virtual addresses
    sfence.vma
    // Align target address stored in mtvec to 64 bytes, in case CLIC is present.
    .balign 64
    1:
    // Restore mtvec to the previous value and return
    csrw mtvec, s1
    csrw mcause, x0
    ret

// Switch to an arbitrary privilege mode. Mode is given in a0 (0, 1, 3).
.global syscall_set_privilege
syscall_set_privilege:
    li t0, 0x4
    blt a0, t0, 1f
    li a0, 1002
    j htif_exit
    1:
    li t0, MSTATUS_MPP
    csrc mstatus, t0
    slli t0, a0, MSTATUS_MPP_OFFSET
    csrs mstatus, t0
    mret

// Get Privilege mode(0: user, 1: supervisor, 3: machine)
.global syscall_get_privilege
syscall_get_privilege:
    li t0, CAUSE_USER_ECALL
    csrr t1, mcause
    sub t1, t1, t0
    mv a0, t1
    mret

// Trap handler is stored in mtvec and must be 4-byte aligned for CLINT but
// must be aligned to 2^6 for compatibility with CLIC.
.p2align 6
.global trap_handler
trap_handler:
    // For some reason when compiling with riscv64-unknown-elf-gcc it
    // will happily compile `printf()` etc and just assume it's running
    // on Linux. This means it does a `write()` syscall which means
    // writing the syscall number to a7, and then `ecall`. We can
    // emulate Linux for `write()` to stdout or stderr so that
    // `printf()` works.
    csrr t5, mcause
    // Clear bits [xlen-2 .. 16], since CLIC puts some irrelevant stuff there.
    li t6, 0x1FFFF
    not t6, t6
    srli t6, t6, 1
    not t6, t6
    and t5, t5, t6

    li t6, CAUSE_USER_ECALL
    beq t5, t6, ecall_handler
    li t6, CAUSE_SUPERVISOR_ECALL
    beq t5, t6, ecall_handler
    li t6, CAUSE_MACHINE_ECALL
    beq t5, t6, ecall_handler

    // Unhandled trap.
    li a0, 1001
    tail htif_exit

.global ecall_handler
ecall_handler:
    // Handle syscalls.

    // We're going to mret from this so mret to the following instructions.
    csrr t6, mepc
    addi t6, t6, 4
    csrw mepc, t6

    // Syscall number is in a7, arguments are in a0..a6, return values in
    // a0, a1. See https://man7.org/linux/man-pages/man2/syscall.2.html

    li t5, SYSCALL_SET_PRIVILEGE
    beq a7, t5, syscall_set_privilege

    li t5, SYSCALL_GET_PRIVILEGE
    beq a7, t5, syscall_get_privilege

    // syscalls return -1 on failure.
    li a0, -1
    mret

.global reset_handler
reset_handler:
    // Initialise registers to avoid X issues.
    li x1, 0
    li x2, 0
    li x3, 0
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0
    li x9, 0
    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0

// Init float registers to avoid X issues. This requires enabling the
// FPU, but we also have to skip it if fmv.w.x is an illegal instruction.
// Note this can be true even if mstatus[FS] is non-zero, to allow for
// emulation. We also restore the original value of mstatus so that
// tests that check its initial value still work.
#ifdef __riscv_flen
    la t0, 9f
    csrw mtvec, t0
    li t0, MSTATUS_FS
    csrrs t0, mstatus, t0
    fmv.w.x f0, x0
    fmv.w.x f1, x0
    fmv.w.x f2, x0
    fmv.w.x f3, x0
    fmv.w.x f4, x0
    fmv.w.x f5, x0
    fmv.w.x f6, x0
    fmv.w.x f7, x0
    fmv.w.x f8, x0
    fmv.w.x f9, x0
    fmv.w.x f10, x0
    fmv.w.x f11, x0
    fmv.w.x f12, x0
    fmv.w.x f13, x0
    fmv.w.x f14, x0
    fmv.w.x f15, x0
    fmv.w.x f16, x0
    fmv.w.x f17, x0
    fmv.w.x f18, x0
    fmv.w.x f19, x0
    fmv.w.x f20, x0
    fmv.w.x f21, x0
    fmv.w.x f22, x0
    fmv.w.x f23, x0
    fmv.w.x f24, x0
    fmv.w.x f25, x0
    fmv.w.x f26, x0
    fmv.w.x f27, x0
    fmv.w.x f28, x0
    fmv.w.x f29, x0
    fmv.w.x f30, x0
    fmv.w.x f31, x0
.p2align 6
9:
#endif

    // Initialize pmp
    call init_pmp

    // Initialise trap handler.
    la t0, trap_handler
    csrw mtvec, t0

    // Initialise stack pointer.
    csrr a0, mhartid

    lui tp, %hi(_stack)
    addi tp, tp, %lo(_stack)

  # give each core 128KB of stack + TLS
#define STKSHIFT 17
    add sp, a0, 1
    sll sp, sp, STKSHIFT
    add sp, sp, tp
    sll a2, a0, STKSHIFT
    add tp, tp, a2

    // Initialize global pointer
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    // Store a frame pointer on the stack. This is necessary if you don't use
    // -fomit-frame-pointer because main() will load it.
    // For simplicity unconditionally store 8 bytes even on RV32.
    addi sp, sp, -8
    sw zero, 0(sp)
    sw zero, 4(sp)

    call main

    // Main return value is in a0 which we pass straight to htif_exit.
    tail htif_exit




// HTIF (Host Target InterFace) MMIO device.
//
// bitfield htif_cmd : bits(64) = {
//   device  : 63 .. 56,
//   cmd     : 55 .. 48,
//   payload : 47 .. 0
// }
//
// The upper byte must be written second if doing two 4-byte writes.
// Device is:
//
//   0 (syscall-proxy): if payload[0] is 1, exit with code payload[..1]
//                      otherwise do nothing.
//   1 (terminal): if command is 0, terminal input (unimplemented in Sail)
//                 if command is 1, terminal output (write lowest byte of payload)

.section .bss.mmio

.balign 8
.global tohost
tohost:
    .fill 8

.section .text

.global htif_exit
htif_exit:
    la t0, tohost
1:
    sll a0, a0, 1
    or a0, a0, 1
    sw a0, 0(t0)
    sw zero, 4(t0)
    j 1b

.global htif_putc
htif_putc:
    la t0, tohost
    sw a0, 0(t0)
    // device=1 (terminal), cmd=1 (output)
    li a0, 0x01010000
    sw a0, 4(t0)
    ret
