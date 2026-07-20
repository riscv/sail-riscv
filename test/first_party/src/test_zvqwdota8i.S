# Test for the unratified Zvqwdota8i extension (Phase 1 of ldot-bdot).
# Spec: https://github.com/aswaterman/riscv-misc/blob/main/isa/ldot-bdot/ldot-bdot.adoc
#
# Two instructions, both in major opcode 0x77 (OP-VE), funct3=000:
#   vqwdotau.vv  vd, vs2, vs1, vm    funct6=0x26   vs2 unsigned, vs1 unsigned (altfmt=0)
#   vqwdotas.vv  vd, vs2, vs1, vm    funct6=0x27   vs2 signed,   vs1 unsigned (altfmt=0)
#
# Instructions are hand-encoded with .4byte because no upstream assembler knows
# these mnemonics yet.
#
# Encoding for vd=v8, vs2=v4, vs1=v2, vm=1 (unmasked):
#   bits  31..26 25 24..20 19..15 14..12 11..7 6..0
#   field funct6 vm vs2    vs1    funct3 vd    opcode
#   vqwdotau.vv: 100110 1 00100 00010 000 01000 1110111 = 0x9A410477
#   vqwdotas.vv: 100111 1 00100 00010 000 01000 1110111 = 0x9E410477
#
# NOTE: This test exercises only the altfmt=0 case (vs1 unsigned) because
# vtype.altfmt is not yet in sail-riscv master.  See the TODO in
# model/extensions/Zvqwdota8i/zvqwdota8i_insts.sail and Zvfbfa PR:
#   https://github.com/riscv/sail-riscv/pull/1581
#
# This test requires `--enable-experimental-extensions` on the simulator
# command line.  CMakeLists.txt threads that flag in via experimental_tests.

.global main
main:
    # Enable mstatus.VS (bits 10:9) = Initial (0b01) so vector ops are legal.
    # crt0 only enables FS; VS stays Off without this.
    li t0, (1 << 9)
    csrs mstatus, t0

    # vsetvli zero, t0=8, e8, m1, ta, ma
    li t0, 8
    vsetvli zero, t0, e8, m1, ta, ma

    # vs1 = v2 = [1,2,3,4,5,6,7,8]  (unsigned)
    la a0, src_vs1
    vle8.v v2, (a0)

    # ----- Test 1: vqwdotau.vv with all-unsigned operands -----
    # vs2 = v4 = [1,2,3,4,5,6,7,8]
    la a1, src_vs2_u
    vle8.v v4, (a1)

    # vd = v8 = 0
    vmv.v.i v8, 0

    # vqwdotau.vv v8, v4, v2
    .4byte 0x9A410477

    # Read vd[0] as a 32-bit scalar
    vsetivli zero, 1, e32, m1, ta, ma
    vmv.x.s t0, v8
    li t1, 204                  # 1+4+9+16+25+36+49+64
    bne t0, t1, fail

    # ----- Test 2: vqwdotas.vv with signed vs2, unsigned vs1 -----
    li t0, 8
    vsetvli zero, t0, e8, m1, ta, ma
    la a1, src_vs2_s
    vle8.v v4, (a1)

    vsetivli zero, 1, e32, m1, ta, ma
    vmv.v.i v8, 0
    li t0, 8
    vsetvli zero, t0, e8, m1, ta, ma

    # vqwdotas.vv v8, v4, v2
    .4byte 0x9E410477

    vsetivli zero, 1, e32, m1, ta, ma
    vmv.x.s t0, v8
    li t1, 36                   # -1+4-9+16-25+36-49+64
    bne t0, t1, fail

pass:
    li a0, 0
    ret

fail:
    li a0, 1
    ret

.section .rodata
.align 4
src_vs1:   .byte 1, 2, 3, 4, 5, 6, 7, 8
src_vs2_u: .byte 1, 2, 3, 4, 5, 6, 7, 8
# Signed: -1, 2, -3, 4, -5, 6, -7, 8
src_vs2_s: .byte 0xff, 2, 0xfd, 4, 0xfb, 6, 0xf9, 8
