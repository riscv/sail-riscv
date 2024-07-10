/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause is_CSR_defined(0x34A) = extensionEnabled(Ext_H) // mtinst
function clause is_CSR_defined(0x34B) = extensionEnabled(Ext_H) // mtval2
function clause is_CSR_defined(0x600) = extensionEnabled(Ext_H) // hstatus
function clause is_CSR_defined(0x602) = extensionEnabled(Ext_H) // hedeleg
function clause is_CSR_defined(0x603) = extensionEnabled(Ext_H) // hideleg
function clause is_CSR_defined(0x604) = extensionEnabled(Ext_H) // hie
function clause is_CSR_defined(0x606) = extensionEnabled(Ext_H) // hcounteren
function clause is_CSR_defined(0x607) = extensionEnabled(Ext_H) // hgeie
function clause is_CSR_defined(0x643) = extensionEnabled(Ext_H) // htval
function clause is_CSR_defined(0x644) = extensionEnabled(Ext_H) // hip
function clause is_CSR_defined(0x645) = extensionEnabled(Ext_H) // hvip
function clause is_CSR_defined(0x64A) = extensionEnabled(Ext_H) // htinst
function clause is_CSR_defined(0xE12) = extensionEnabled(Ext_H) // hgeip
function clause is_CSR_defined(0x60A) = extensionEnabled(Ext_H) // henvcfg
function clause is_CSR_defined(0x61A) = extensionEnabled(Ext_H) // henvcfgh
function clause is_CSR_defined(0x680) = extensionEnabled(Ext_H) // hgatp
function clause is_CSR_defined(0x605) = extensionEnabled(Ext_H) // htimedelta
function clause is_CSR_defined(0x615) = extensionEnabled(Ext_H) // htimedeltah
function clause is_CSR_defined(0x200) = extensionEnabled(Ext_H) // vsstatus
function clause is_CSR_defined(0x204) = extensionEnabled(Ext_H) // vsie
function clause is_CSR_defined(0x205) = extensionEnabled(Ext_H) // vstvec
function clause is_CSR_defined(0x240) = extensionEnabled(Ext_H) // vsscratch
function clause is_CSR_defined(0x241) = extensionEnabled(Ext_H) // vsepc
function clause is_CSR_defined(0x242) = extensionEnabled(Ext_H) // vscause
function clause is_CSR_defined(0x243) = extensionEnabled(Ext_H) // vstval
function clause is_CSR_defined(0x244) = extensionEnabled(Ext_H) // vsip
function clause is_CSR_defined(0x280) = extensionEnabled(Ext_H) // vsatp

function clause read_CSR(0x34A) = mtinst
function clause read_CSR(0x34B) = mtval2
function clause read_CSR(0x600) = hstatus.bits
function clause read_CSR(0x602) = hedeleg.bits
function clause read_CSR(0x603) = hideleg.bits
function clause read_CSR(0x604) = lower_mie_to_hie(mie).bits
function clause read_CSR(0x606) = zero_extend(hcounteren.bits)
function clause read_CSR(0x607) = hgeie
function clause read_CSR(0x643) = htval
function clause read_CSR(0x644) = lower_mip_to_hip(mip).bits
function clause read_CSR(0x645) = lower_mip_to_hvip(mip).bits
function clause read_CSR(0x64A) = htinst
function clause read_CSR(0xE12) = hgeip
function clause read_CSR(0x60A) = henvcfg.bits[sizeof(xlen) - 1 .. 0]
function clause read_CSR(0x61A if xlen == 32) = henvcfg.bits[63 .. 32]
// function clause ext_read_CSR(0x680) = Some(hgatp) // TODO: Second Level Address Translation
function clause read_CSR(0x605) = htimedelta[sizeof(xlen) - 1 .. 0]
function clause read_CSR(0x615 if xlen == 32) = htimedelta[63 .. 32]
function clause read_CSR(0x200) = vsstatus.bits[sizeof(xlen) - 1 .. 0]
function clause read_CSR(0x204) = lower_mie_to_vsie(mie, hideleg).bits
function clause read_CSR(0x205) = vstvec.bits
function clause read_CSR(0x240) = vsscratch
function clause read_CSR(0x241) = vsepc
function clause read_CSR(0x242) = vscause.bits
function clause read_CSR(0x243) = vstval
function clause read_CSR(0x244) = lower_mip_to_vsip(mip, hideleg).bits
function clause read_CSR(0x280) = vsatp

function clause write_CSR(0x34A, value) = { mtinst = value; mtinst }
function clause write_CSR(0x34B, value) = { mtval2 = value; mtval2 }
function clause write_CSR(0x600, value) = { hstatus = legalize_hstatus(hstatus, value); hstatus.bits }
function clause write_CSR(0x602, value) = { hedeleg = legalize_hedeleg(hedeleg, value); hedeleg.bits }
function clause write_CSR(0x603, value) = { hideleg = legalize_hideleg(hideleg, value); hideleg.bits }
function clause write_CSR(0x604, value) = { mie = legalize_hie(mie, value); lower_mie_to_hie(mie).bits }
function clause write_CSR(0x606, value) = { hcounteren = legalize_hcounteren(hcounteren, value); zero_extend(hcounteren.bits) }
function clause write_CSR(0x607, value) = { hgeie = legalize_hgeie(value); hgeie }
function clause write_CSR((0x60A, value) if xlen == 32) = { henvcfg = legalize_henvcfg(henvcfg, henvcfg.bits[63 .. 32] @ value); henvcfg.bits[(sizeof(xlen) - 1) .. 0] }
function clause write_CSR((0x60A, value) if xlen == 64) = { henvcfg = legalize_henvcfg(henvcfg, value); henvcfg.bits[(sizeof(xlen) - 1) .. 0] }
function clause write_CSR((0x61A, value) if xlen == 32) = { henvcfg = legalize_henvcfg(henvcfg, value @ henvcfg.bits[31 .. 0]); henvcfg.bits[63 .. 32]}
function clause write_CSR(0x643, value) = { htval = value; htval }
function clause write_CSR(0x644, value) = { mip = legalize_hip(mip, value); lower_mip_to_hip(mip).bits }
function clause write_CSR(0x645, value) = { mip = legalize_hvip(mip, value); lower_mip_to_hvip(mip).bits }
function clause write_CSR(0x64A, value) = { htinst = value; htinst }
// function clause ext_write_CSR(0xE12,     _) = None() // hgeip is read-only
// function clause ext_write_CSR(0x680, value) = { hgatp = legalize_hgatp(cur_Architecture(), hgatp, value); Some(hgatp) } // TODO: Second Level Address Translation
function clause write_CSR(0x605, value) = { htimedelta[(sizeof(xlen) - 1) .. 0] = value; htimedelta[(sizeof(xlen) - 1) .. 0] }
function clause write_CSR((0x615, value) if xlen == 32) = {htimedelta[63 .. 32] = value; htimedelta[63 .. 32] }
function clause write_CSR(0x200, value) = { vsstatus = legalize_vsstatus(vsstatus, value); vsstatus.bits[(sizeof(xlen) - 1) .. 0] }
function clause write_CSR(0x204, value) = { mie = legalize_vsie(mie, hideleg, value); lower_mie_to_vsie(mie, hideleg).bits }
function clause write_CSR(0x205, value) = { vstvec = Mk_Mtvec(value); vstvec.bits }
function clause write_CSR(0x240, value) = { vsscratch = value; vsscratch }
function clause write_CSR(0x241, value) = { vsepc = value; vsepc }
function clause write_CSR(0x242, value) = { vscause = Mk_Mcause(value); vscause.bits }
function clause write_CSR(0x243, value) = { vstval = value; vstval }
function clause write_CSR(0x244, value) = { mip = legalize_vsip(mip, hideleg, value); lower_mip_to_vsip(mip, hideleg).bits }
function clause write_CSR(0x280, value) = { vsatp = value; vsatp }

/*! Initialize hypervisor extension */
function init_hext() -> unit = {
  /* Start with V=0 */

  cur_virtualization = V0;

  /* Init H-extension specific fields of M-mode CRSs */

  mstatus[MPV] = virtMode_to_bits(cur_virtualization);
  mstatus[GVA] = 0b0;

  mtinst = zeros();
  mtval2 = zeros();

  mideleg = [mideleg with VSEI = 0b1, VSTI = 0b1, VSSI = 0b1];
  mideleg = [mideleg with SGEI = 0b1]; /* Note: SGEI is "read-only one" only if GEILEN > 0 */

  /* Init H-extension specific HS-mode CSRs */

  hstatus = Mk_Hstatus(zeros());
  hstatus = set_hstatus_VSXL(hstatus, misa[MXL]); /* Dynamic XLEN changes are not (yet) supported */

  hedeleg = Mk_Medeleg(zeros());
  hideleg = Mk_Minterrupts(zeros());
  hcounteren = Mk_Counteren(zeros());
  htval = zeros();
  htval = zeros();
  hgeie = legalize_hgeie(zeros());
  hgeip = zeros();
  henvcfg = Mk_HEnvcfg(zeros());
  htimedelta = zeros();

  /* Init VS-mode CSRs */

  vsstatus = Mk_Sstatus(zeros());
  vsstatus = set_sstatus_UXL(vsstatus, misa[MXL]); /* Dynamic XLEN changes are not (yet) supported */

  vstvec = Mk_Mtvec(zeros());
  vsscratch = zeros();
  vsepc = zeros();
  vscause = Mk_Mcause(zeros());
  vstval = zeros();
  vsatp = zeros();
}
