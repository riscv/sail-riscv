// Self-checking test for the Zimt memory tagging extension (v0.2, DRAFT).
// Runs in M-mode with mseccfg.MT_MODE enabled and the Smvatag tag table.
//
// NOTE: the CSR addresses of mvitt and mmtagexclude0 are PLACEHOLDERS;
// the draft specification has not allocated CSR addresses yet (see
// model/extensions/Zimt/zimt_regs.sail).

#define CSR_MSECCFG      0x747
#define CSR_MMTAGEXCL0   0x7C0
#define CSR_MVITT        0x7C4

// mseccfg.MT_MODE: bits 35:34; mseccfg.PMM: bits 33:32.
#define MT_MODE_SHIFT    34
#define MT_MODE_TAG4     2
#define PMM_SHIFT        32
#define PMM_PMLEN_7      2

// Zimt instructions are encoded directly (Zimop MOP.RR space, SYSTEM
// opcode, funct3 100) since toolchains do not support Zimt yet.
// Register arguments are architectural register numbers.
.macro gentag rd
  .4byte ((0x43 << 25) | (0x4 << 12) | (\rd << 7) | 0x73)
.endm
.macro addtag rd, rs1, imm4
  .4byte ((0x43 << 25) | (\imm4 << 20) | (\rs1 << 15) | (0x4 << 12) | (\rd << 7) | 0x73)
.endm
.macro checktag rs1, imm4
  .4byte ((0x43 << 25) | (\imm4 << 20) | (\rs1 << 15) | (0x4 << 12) | 0x73)
.endm
.macro settag rs1, imm4
  .4byte ((0x41 << 25) | (\imm4 << 20) | (\rs1 << 15) | (0x4 << 12) | 0x73)
.endm

#define CAUSE_SOFTWARE_CHECK 18
#define SWCHECK_TVAL_MEM_TAG 4

.global main
main:
#if __riscv_xlen == 64
    mv s11, ra

    // ------------------------------------------------------------------
    // 1. Enable pointer masking (PMLEN=7) and memory tagging (4-bit
    //    tags) in M-mode. If MT_MODE reads back 0, Zimt is not present
    //    (e.g. experimental extensions disabled): pass trivially.
    li t0, (MT_MODE_TAG4 << MT_MODE_SHIFT) | (PMM_PMLEN_7 << PMM_SHIFT)
    csrs CSR_MSECCFG, t0
    csrr t1, CSR_MSECCFG
    srli t1, t1, MT_MODE_SHIFT
    andi t1, t1, 3
    li t2, MT_MODE_TAG4
    bne t1, t2, pass

    // The reserved MT_MODE value 0b01 must not stick (WARL keep-old).
    li t0, (3 << MT_MODE_SHIFT)
    csrc CSR_MSECCFG, t0
    li t0, (1 << MT_MODE_SHIFT)
    csrs CSR_MSECCFG, t0
    csrr t1, CSR_MSECCFG
    srli t1, t1, MT_MODE_SHIFT
    andi t1, t1, 3
    li t2, 1
    beq t1, t2, fail
    li t0, (MT_MODE_TAG4 << MT_MODE_SHIFT)
    csrs CSR_MSECCFG, t0

    // ------------------------------------------------------------------
    // 2. Point the M-mode tag table (VITT) so that the tag byte of
    //    data_buf lands inside tag_region:
    //      mc_tag_va = mvitt + (va >> 5)        (4-bit tags)
    //    mvitt = (tag_anchor - (data_buf >> 5)) & ~0xFFF, which puts
    //    the tag byte within (tag_anchor - 4096, tag_anchor].
    la t0, tag_region
    li t1, 4096
    add t0, t0, t1         // tag_anchor = tag_region + 4096
    la t2, data_buf
    srli t2, t2, 5
    sub t0, t0, t2
    csrw CSR_MVITT, t0
    // mvitt is 4K-aligned WARL: low 12 bits must read back zero.
    csrr t1, CSR_MVITT
    slli t1, t1, 52
    bnez t1, fail

    // ------------------------------------------------------------------
    // 3. gentag with an exclusion mask permitting only tag value 5
    //    must deterministically generate pointer_tag = 5 (in bits
    //    63:60), with the rest of rd cleared.
    li t0, 0xFFDF          // exclude all 4-bit tags except 5
    csrw CSR_MMTAGEXCL0, t0
    gentag 5               // t0 <- generated tagged (null) pointer
    li t1, 5
    slli t1, t1, 60
    bne t0, t1, fail

    // The exclusion mask is WARL: at least one bit of [15:0] must
    // remain clear.
    li t0, 0xFFFF
    csrw CSR_MMTAGEXCL0, t0
    csrr t1, CSR_MMTAGEXCL0
    li t2, 0xFFFF
    beq t1, t2, fail
    csrw CSR_MMTAGEXCL0, zero

    // ------------------------------------------------------------------
    // 4. addtag: in-place tag arithmetic in bits 63:60.
    li t0, 5
    slli t0, t0, 60
    la t2, data_buf
    or t0, t0, t2          // t0 = data_buf tagged with 5
    addtag 6, 5, 2         // t1 <- t0 with pointer_tag += 2
    li t3, 7
    slli t3, t3, 60
    or t3, t3, t2
    bne t1, t3, fail

    // ------------------------------------------------------------------
    // 5. settag/checktag round trip: tag chunk 0 of data_buf with 5;
    //    a matching checktag must not trap.
    settag 5, 0            // t0 still = data_buf tagged with 5
    checktag 5, 0

    // ------------------------------------------------------------------
    // 6. checktag with a mismatching pointer_tag must raise a
    //    software-check exception (cause 18) with xtval = 4.
    la t3, expect_swcheck
    csrr s10, mtvec
    csrw mtvec, t3
    li s9, 0               // trap-seen flag
    addtag 6, 5, 1         // t1 = data_buf tagged with 6
    mv t0, t1
    checktag 5, 0          // mismatch: must trap
    beqz s9, fail
    li s9, 0

    // ------------------------------------------------------------------
    // 7. Implicit checks (paging disabled => every data page is a
    //    tagged-data page):
    //    a. load through a matching tagged pointer succeeds,
    li t0, 5
    slli t0, t0, 60
    la t2, data_buf
    or t0, t0, t2
    ld t4, 0(t0)
    //    b. load through a mismatching pointer traps with tval = 4,
    addtag 6, 5, 3         // t1 = data_buf tagged with 8
    ld t4, 0(t1)
    beqz s9, fail
    li s9, 0
    //    c. store through a mismatching pointer traps as well,
    sd t4, 0(t1)
    beqz s9, fail
    li s9, 0
    //    d. an access via the stack pointer (x2) is never checked.
    mv s8, sp
    mv sp, t1              // sp = mismatching tagged pointer
    ld t4, 0(sp)
    mv sp, s8
    bnez s9, fail

    csrw mtvec, s10

    // ------------------------------------------------------------------
    // 8. Disable memory tagging: gentag must fall back to Zimop
    //    behavior and zero its destination.
    li t0, (3 << MT_MODE_SHIFT)
    csrc CSR_MSECCFG, t0
    li t0, 42
    gentag 5
    bnez t0, fail

pass:
    mv ra, s11
    li a0, 0
    ret
fail:
    mv ra, s11
    li a0, 1
    ret

// Trap handler: expect a software-check exception with tval = 4, set
// the flag in s9 and resume at mepc + 4.
.p2align 6
expect_swcheck:
    csrr t4, mcause
    li t5, CAUSE_SOFTWARE_CHECK
    bne t4, t5, fail
    csrr t4, mtval
    li t5, SWCHECK_TVAL_MEM_TAG
    bne t4, t5, fail
    li s9, 1
    csrr t4, mepc
    addi t4, t4, 4
    csrw mepc, t4
    mret
#else
    // Zimt is RV64-only; pass trivially on RV32.
    li a0, 0
    ret
#endif

#if __riscv_xlen == 64
.section .data
.p2align 12
tag_region:
    .fill 8192, 1, 0
data_buf:
    .fill 64, 1, 0
#endif
