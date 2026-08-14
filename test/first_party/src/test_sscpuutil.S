#include "common/encoding.h"

#define CSR_ACTTIME 0xC23
#define CSR_ACTTIMEH 0xCA3
#define CSR_MACTTIME 0xF00
#define CSR_MACTTIMEH 0xF80

#if __riscv_xlen == 64
#define CSR_MSTATEEN0_ACTTIME CSR_MSTATEEN0
#define STATEEN_ACTTIME (1ULL << 53)
#else
#define CSR_MSTATEEN0_ACTTIME CSR_MSTATEEN0H
#define STATEEN_ACTTIME (1U << 21)
#endif

.section .text

.global main
main:
  la t0, fail
  csrw mtvec, t0
  csrw medeleg, zero

#if __riscv_xlen == 32
1:
  csrr t0, CSR_MACTTIMEH
  csrr t1, CSR_ACTTIMEH
  bne t0, t1, fail
#endif

2:
  # macttime advances while the hart is active.
  csrr t0, CSR_MACTTIME
  addi t6, t6, 1
  csrr t1, CSR_MACTTIME
  bgeu t0, t1, fail

3:
  # macttime is M-mode only.
  la t0, test_3_trap_handler
  csrw mtvec, t0
  la a0, test_3_s_body
  j enter_s_mode

.balign 4
test_3_s_body:
  csrr t0, CSR_MACTTIME
  ecall

.balign 4
test_3_trap_handler:
  csrr t0, mcause
  li t1, CAUSE_ILLEGAL_INSTRUCTION
  bne t0, t1, fail
  la a0, 4f
  j return_to_m_mode

4:
  # mcountinhibit.CY stops mcycle but not macttime.
  li t2, 1
  csrw mcountinhibit, t2
  csrr t0, CSR_MCYCLE
  csrr t1, CSR_MACTTIME
  addi t6, t6, 1
  csrr t2, CSR_MCYCLE
  csrr t3, CSR_MACTTIME
  bne t0, t2, fail
  bgeu t1, t3, fail
  csrw mcountinhibit, zero

5:
  # mstateen0.ACTTIME gates S-mode shadow access.
  li t0, STATEEN_ACTTIME
  csrc CSR_MSTATEEN0_ACTTIME, t0
  li t0, 1
  csrs mcounteren, t0
  csrs scounteren, t0
  la t0, test_5_trap_handler
  csrw mtvec, t0
  la a0, test_5_s_body
  j enter_s_mode

.balign 4
test_5_s_body:
  csrr t0, CSR_ACTTIME
  ecall

.balign 4
test_5_trap_handler:
  csrr t0, mcause
  li t1, CAUSE_ILLEGAL_INSTRUCTION
  bne t0, t1, fail
  la a0, 6f
  j return_to_m_mode

6:
  # mstateen0.ACTTIME gates U-mode shadow access.
  li t0, STATEEN_ACTTIME
  csrc CSR_MSTATEEN0_ACTTIME, t0
  li t0, 1
  csrs mcounteren, t0
  csrs scounteren, t0
  la t0, test_6_trap_handler
  csrw mtvec, t0
  la a0, test_6_u_body
  j enter_u_mode

.balign 4
test_6_u_body:
  csrr t0, CSR_ACTTIME
  ecall

.balign 4
test_6_trap_handler:
  csrr t0, mcause
  li t1, CAUSE_ILLEGAL_INSTRUCTION
  bne t0, t1, fail
  la a0, 7f
  j return_to_m_mode

7:
  # With stateen enabled, U-mode also needs mcounteren.CY.
  li t0, STATEEN_ACTTIME
  csrs CSR_MSTATEEN0_ACTTIME, t0
  li t0, 1
  csrc mcounteren, t0
  csrs scounteren, t0
  la t0, test_7_trap_handler
  csrw mtvec, t0
  la a0, test_7_u_body
  j enter_u_mode

.balign 4
test_7_u_body:
  csrr t0, CSR_ACTTIME
  ecall

.balign 4
test_7_trap_handler:
  csrr t0, mcause
  li t1, CAUSE_ILLEGAL_INSTRUCTION
  bne t0, t1, fail
  la a0, 8f
  j return_to_m_mode

8:
  # With mcounteren enabled, U-mode still needs scounteren.CY.
  li t0, 1
  csrs CSR_MSTATEEN0_ACTTIME, t0
  csrs mcounteren, t0
  csrc scounteren, t0
  la t0, test_8_trap_handler
  csrw mtvec, t0
  la a0, test_8_u_body
  j enter_u_mode

.balign 4
test_8_u_body:
  csrr t0, CSR_ACTTIME
  ecall

.balign 4
test_8_trap_handler:
  csrr t0, mcause
  li t1, CAUSE_ILLEGAL_INSTRUCTION
  bne t0, t1, fail
  la a0, 9f
  j return_to_m_mode

9:
  # S-mode succeeds with all gates enabled.
  li t0, STATEEN_ACTTIME
  csrs CSR_MSTATEEN0_ACTTIME, t0
  li t0, 1
  csrs mcounteren, t0
  csrs scounteren, t0
  la t0, test_9_trap_handler
  csrw mtvec, t0
  la a0, test_9_s_body
  j enter_s_mode

.balign 4
test_9_s_body:
  csrr s1, CSR_ACTTIME
  csrr s2, CSR_ACTTIME
  ecall

.balign 4
test_9_trap_handler:
  csrr t0, mcause
  li t1, CAUSE_SUPERVISOR_ECALL
  bne t0, t1, fail
  bltu s2, s1, fail
  la a0, 10f
  j return_to_m_mode

10:
  # U-mode succeeds with all gates enabled.
  li t0, STATEEN_ACTTIME
  csrs CSR_MSTATEEN0_ACTTIME, t0
  li t0, 1
  csrs mcounteren, t0
  csrs scounteren, t0
  la t0, test_10_trap_handler
  csrw mtvec, t0
  la a0, test_10_u_body
  j enter_u_mode

.balign 4
test_10_u_body:
  csrr s1, CSR_ACTTIME
  csrr s2, CSR_ACTTIME
  ecall

.balign 4
test_10_trap_handler:
  csrr t0, mcause
  li t1, CAUSE_USER_ECALL
  bne t0, t1, fail
  bltu s2, s1, fail
  la a0, 11f
  j return_to_m_mode

11:
  # WFI stops macttime and mcycle.
  csrr t0, CSR_TIME
  csrr t1, CSR_MCYCLE
  csrr t2, CSR_MACTTIME
  wfi
  csrr t3, CSR_TIME
  csrr t4, CSR_MCYCLE
  csrr t5, CSR_MACTTIME
  addi t1, t1, 3
  bltu t1, t4, fail
  sub t0, t3, t0
  sub t2, t5, t2
  sub t0, t0, t2
  # max_time_to_wait=10
  # time = macttime + 10
  li t2, 10
  bne t0, t2, fail

pass:
  li a0, 0
  ret

fail:
  li a0, 1
  ret

enter_s_mode:
  csrr t0, mstatus
  li t1, ~MSTATUS_MPP
  and t0, t0, t1
  li t1, (MSTATUS_MPP & (MSTATUS_MPP >> 1))
  or t0, t0, t1
  csrw mstatus, t0
  csrw mepc, a0
  mret

enter_u_mode:
  csrr t0, mstatus
  li t1, ~MSTATUS_MPP
  and t0, t0, t1
  csrw mstatus, t0
  csrw mepc, a0
  mret

return_to_m_mode:
  csrw mepc, a0
  csrr t0, mstatus
  li t1, ~MSTATUS_MPP
  and t0, t0, t1
  li t1, MSTATUS_MPP
  or t0, t0, t1
  csrw mstatus, t0
  mret
