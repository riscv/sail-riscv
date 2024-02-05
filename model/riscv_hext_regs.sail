/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2023                                                              */
/*    Prashanth Mundkur                                                                  */
/*    Rishiyur S. Nikhil and Bluespec, Inc.                                              */
/*    Jon French                                                                         */
/*    Brian Campbell                                                                     */
/*    Robert Norton-Wright                                                               */
/*    Alasdair Armstrong                                                                 */
/*    Thomas Bauereiss                                                                   */
/*    Shaked Flur                                                                        */
/*    Christopher Pulte                                                                  */
/*    Peter Sewell                                                                       */
/*    Alexander Richardson                                                               */
/*    Hesham Almatary                                                                    */
/*    Jessica Clarke                                                                     */
/*    Microsoft, for contributions by Robert Norton-Wright and Nathaniel Wesley Filardo  */
/*    Peter Rugg                                                                         */
/*    Aril Computer Corp., for contributions by Scott Johnson                            */
/*    Philipp Tomsich                                                                    */
/*    VRULL GmbH, for contributions by its employees                                     */
/*                                                                                       */
/*  All rights reserved.                                                                 */
/*                                                                                       */
/*  This software was developed by the above within the Rigorous                         */
/*  Engineering of Mainstream Systems (REMS) project, partly funded by                   */
/*  EPSRC grant EP/K008528/1, at the Universities of Cambridge and                       */
/*  Edinburgh.                                                                           */
/*                                                                                       */
/*  This software was developed by SRI International and the University of               */
/*  Cambridge Computer Laboratory (Department of Computer Science and                    */
/*  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and                 */
/*  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA                 */
/*  SSITH research programme.                                                            */
/*                                                                                       */
/*  This project has received funding from the European Research Council                 */
/*  (ERC) under the European Union’s Horizon 2020 research and innovation                */
/*  programme (grant agreement 789108, ELVER).                                           */
/*                                                                                       */
/*                                                                                       */
/*  Redistribution and use in source and binary forms, with or without                   */
/*  modification, are permitted provided that the following conditions                   */
/*  are met:                                                                             */
/*  1. Redistributions of source code must retain the above copyright                    */
/*     notice, this list of conditions and the following disclaimer.                     */
/*  2. Redistributions in binary form must reproduce the above copyright                 */
/*     notice, this list of conditions and the following disclaimer in                   */
/*     the documentation and/or other materials provided with the                        */
/*     distribution.                                                                     */
/*                                                                                       */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''                   */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                    */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A                      */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR                  */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,                         */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT                     */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF                     */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND                  */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,                   */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                   */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF                   */
/*  SUCH DAMAGE.                                                                         */
/*=======================================================================================*/

/* **************************************************************** */
/* Virtualization Mode                                              */

register cur_virtualization : Virtualization

/* **************************************************************** */
/* Hypervisor Status Register                                       */

bitfield Hstatus : xlenbits = {
  /* VSXL only exists if HSXLEN == 64 so it's modelled via explicit an getter and setter below.*/
  /* VSXL : 33 .. 32 */
  VTSR  : 22,
  VTW   : 21,
  VTVM  : 20,
  VGEIN : 17 .. 12,
  HU    : 9,
  SPVP  : 8,
  SPV   : 7,
  GVA   : 6,
  VSBE  : 5
}
register hstatus : Hstatus

function get_hstatus_VSXL(h : Hstatus) -> arch_xlen = {
  if sizeof(xlen) == 32
  then arch_to_bits(RV32)
  else h.bits()[33 .. 32]
}

function set_hstatus_VSXL(h : Hstatus, a : arch_xlen) -> Hstatus = {
  if sizeof(xlen) == 32
  then h
  else {
    let h = vector_update_subrange(h.bits(), 33, 32, a);
    Mk_Hstatus(h)
  }
}

function legalize_hstatus(o : Hstatus, v : xlenbits) -> Hstatus = {
  let v = Mk_Hstatus(v);
  let h = Mk_Hstatus(zero_extend(0b0));

  let h = update_VTSR(h, v.VTSR());
  let h = update_VTW(h, v.VTW());
  let h = update_VTVM(h, v.VTVM());
  let h = update_VGEIN(h, v.VGEIN());  /* Note: 0 <= hstatus.VGEIN <= GEILEN */
  let h = update_HU(h, v.HU());
  let h = update_SPVP(h, v.SPVP());
  let h = update_SPV(h, v.SPV());
  let h = update_GVA(h, v.GVA());
  let h = update_VSBE(h, v.VSBE());

  /* Dynamic XLEN changes are not (yet) supported */
  let h = set_hstatus_VSXL(h, get_hstatus_VSXL(o));

  h
}

/* **************************************************************** */
/* Hypervisor Trap Delegation Registers                             */

register hedeleg : Medeleg

function legalize_hedeleg(o: Medeleg, v: xlenbits) -> Medeleg = {
  let h = Mk_Medeleg(v);
  /* Mask read-only zero bits */
  let h = update_SAMO_GPage_Fault(h, 0b0);
  let h = update_Virtual_Instr(h, 0b0);
  let h = update_Load_GPage_Fault(h, 0b0);
  let h = update_Fetch_GPage_Fault(h, 0b0);
  let h = update_MEnvCall(h, 0b0);
  let h = update_VSEnvCall(h, 0b0);
  let h = update_HSEnvCall(h, 0b0);
  h
}

register hideleg : Minterrupts /* Delegation to VS-mode */

function legalize_hideleg(h : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  /* VS-level interrupts can be delegated */
  let h = update_VSEI(h, v.VSEI());
  let h = update_VSTI(h, v.VSTI());
  let h = update_VSSI(h, v.VSSI());
  /* Other interrupts can't be delegated to VS-mode */
  h
}


/* **************************************************************** */
/* Hypervisor Interrupt enable/pending registers                    */

/* hvip is a view of mip, so there is no register defined. */

/*! Returns new mip from the previous mip (m) and the written hvip (v) */
function legalize_hvip(m: Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  let m = update_VSEI(m, v.VSEI());
  let m = update_VSTI(m, v.VSTI());
  let m = update_VSSI(m, v.VSSI());
  // TODO: Update non-standard portion
  m
}

/*! Returns hvip view of mip (m) */
function lower_mip_to_hvip(m : Minterrupts) -> Minterrupts = {
  let h = Mk_Minterrupts(zeros());
  let h = update_VSEI(h, m.VSEI());
  let h = update_VSTI(h, m.VSTI());
  let h = update_VSSI(h, m.VSSI());
  // TODO: Read non-standard portion
  h
}

/* hip is a view of mip, so there is no register defined. */

/*! Returns new mip from the previous mip (m) and the written hip (v) */
function legalize_hip(m : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  let m = update_VSSI(m, v.VSSI());
  // TODO: Update non-standard portion
  m
}

/*! Returns hip view of mip (m) */
function lower_mip_to_hip(m : Minterrupts) -> Minterrupts = {
  let h = Mk_Minterrupts(zeros());
  let h = update_SGEI(h, m.SGEI());
  let h = update_VSEI(h, m.VSEI());
  let h = update_VSTI(h, m.VSTI());
  let h = update_VSSI(h, m.VSSI());
  // TODO: Read non-standard portion
  h
}

/* hie is a view of mie, so there is no register defined. */

/*! Returns new mie from the previous mie (m) and the written hie (v) */
function legalize_hie(m : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  let m = update_SGEI(m, v.SGEI());
  let m = update_VSEI(m, v.VSEI());
  let m = update_VSTI(m, v.VSTI());
  let m = update_VSSI(m, v.VSSI());
  /* Note: Writable bits in sie are read-only zero in hie */
  // TODO: Update non-standard portion
  m
}

/*! Returns hie view of mie */
function lower_mie_to_hie(m : Minterrupts) -> Minterrupts = {
  let h = Mk_Minterrupts(zeros());
  let h = update_SGEI(h, m.SGEI());
  let h = update_VSEI(h, m.VSEI());
  let h = update_VSTI(h, m.VSTI());
  let h = update_VSSI(h, m.VSSI());
  /* Note: Writable bits in sie are read-only zero in hie */
  // TODO: Read non-standard portion
  h
}

/* **************************************************************** */
/* Hypervisor environment configuration register                    */

register henvcfg : Envcfg

/* **************************************************************** */
/* Hypervisor hpm-related registers                                 */

register hcounteren : Counteren

function legalize_hcounteren(c : Counteren, v : xlenbits) -> Counteren = {
  legalize_counteren(c, v)
}

register htimedelta : bits(64)

/* **************************************************************** */
/* Hypervisor Guest External Interrupts                             */

register hgeie : xlenbits
register hgeip : xlenbits
// TODO: hgeip should be written by interrupt controller
// TODO: hip.SGEI is 1 if bitwise and of hgeip and hgeie is nonzero in any bit
// TODO: hip.VSEI is 1 if hgeip[hstatus.VGEIN] is 1

function legalize_hgeie(v : xlenbits) -> xlenbits = {
  [v with 0 = bitzero]
}

/* **************************************************************** */
/* Machine & Hypervisor trap information                            */

register mtinst : xlenbits
register mtval2 : xlenbits

register htinst : xlenbits
register htval  : xlenbits

/* **************************************************************** */
/* Hypervisor Guest Address Translation and Protection              */

bitfield Hgatp64 : bits(64) = {
  Mode : 63 .. 60,
  Vmid : 57 .. 44,
  PPN  : 43 .. 0
}

function legalize_hgatp64(a : Architecture, o : bits(64), v : bits(64)) -> bits(64) = {
  let h = Mk_Hgatp64(v[63 .. 60] @ 0b00 @ v[57 .. 44] @ v[43 .. 2] @ 0b00);
  match hgatp64Mode_of_bits(a, h.Mode()) {
    Some(Bare)   => h.Mode() @ zeros(60), /* remaining fields should be zero when hgatp.Mode is Bare */
    Some(Sv32x4) => o,                    /* Sv32x4 is currently unsupported for satp64 */
    Some(Sv39x4) => h.bits(),
    Some(Sv48x4) => h.bits(),
    Some(Sv57x4) => o,                    /* Sv57x4 is not yet implemented */
    _            => o,                    /* (V)S-stage modes are illegal for satp */
  }
}

bitfield Hgatp32 : bits(32) = {
  Mode : 31,
  Vmid : 28 .. 22,
  PPN  : 21 .. 0
}

function legalize_hgatp32(a : Architecture, o : bits(32), v : bits(32)) -> bits(32) = {
  let h = Mk_Hgatp32(v[31 .. 31] @ 0b00 @ v[28 .. 22] @ v[21 .. 2] @ 0b00);
  match hgatp64Mode_of_bits(a, zero_extend(h.Mode())) {
    None()       => o,
    Some(Bare) => h.Mode() @ zeros(31), /* remaining fields should be zero when hgatp.Mode is Bare */
    Some(_)    => h.bits()
  }
}

/* **************************************************************** */
/* Virtual Supervisor Status Register                               */

bitfield Vsstatus : xlenbits = {
  SD   : xlen - 1,
  /* UXL only exists if HSXLEN == 64 so it's modelled via explicit an getter and setter below.*/
  /* UXL  : 33 .. 32 */
  MXR  : 19,
  SUM  : 18,
  XS   : 16 .. 15,
  FS   : 14 .. 13,
  VS   : 10 .. 9,
  SPP  : 8,
  UBE  : 6,
  SPIE : 5,
  SIE  : 1
}
register vsstatus : Vsstatus

function get_vsstatus_UXL(v : Vsstatus) -> arch_xlen = {
  if sizeof(xlen) == 32
  then arch_to_bits(RV32)
  else v.bits()[33 .. 32]
}

function set_vsstatus_UXL(v : Vsstatus, a : arch_xlen) -> Vsstatus = {
  if sizeof(xlen) == 32
  then v
  else {
    let v = vector_update_subrange(v.bits(), 33, 32, a);
    Mk_Vsstatus(v)
  }
}

function legalize_vsstatus(vs: Vsstatus, v: xlenbits) -> Vsstatus = {
  let m = Mk_Mstatus(vs.bits());  /* Convert to Mstatus   */
  let s = legalize_sstatus(m, v); /* Legalize for Sstatus */
  Mk_Vsstatus(s.bits())           /* Convert back to Vsstatus  */
}

/* **************************************************************** */
/* Virtual Supervisor Trap Vector Base Address Register             */

register vstvec : Mtvec

/* **************************************************************** */
/* Virtual Supervisor Scratch Register                              */

register vsscratch : xlenbits

/* **************************************************************** */
/* Virtual Supervisor Exception Program Counter                     */

register vsepc : xlenbits

/* **************************************************************** */
/* Virtual Supervisor Cause Register                                */

register vscause : Mcause

/* **************************************************************** */
/* Virtual Supervisor Trap Value Register                           */

register vstval : xlenbits

/* **************************************************************** */
/* Virtual Supervisor interrupt enable/pending registers            */

/* vsip is a view of mip, so there is no register defined. */

/*! Returns new mip from the previous mip (m) and the written vsip (v) as delegated by hideleg (d) */
function legalize_vsip(m: Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  /* Since S-mode bits in vsip are aliases for their corresponding VS-mode bits
     in hip when delegated by hideleg, only vsip.SSIP (hip.VSSIP) might be writable */
  let m = update_VSSI(m, v.SSI() & d.VSSI());
  m
}

/*! Returns vsip view of mip (m) as delegated by hideleg (d) */
function lower_mip_to_vsip(m : Minterrupts, d : Minterrupts) -> Minterrupts = {
  let vs = Mk_Minterrupts(zeros());
  /* Standard S-mode bits in vsip are aliases of corresponding VS-mode bits in
     hip if delegated by hideleg */
  let vs = update_SEI(vs, m.VSEI() & d.VSEI());
  let vs = update_STI(vs, m.VSTI() & d.VSTI());
  let vs = update_SSI(vs, m.VSSI() & d.VSSI());
  vs
}

/* hie is a view of vsie, so there is no register defined. */

/*! Returns new mie from previous mie (m) and the written vsie (v) as delegated by hideleg (d) */
function legalize_vsie(m : Minterrupts, d : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  let m = update_VSEI(m, v.SEI() & d.VSEI());
  let m = update_VSTI(m, v.STI() & d.VSTI());
  let m = update_VSSI(m, v.SSI() & d.VSSI());
  m
}

/*! Returns vsie view of mie (m) as delegated by hideleg (d) */
function lower_mie_to_vsie(m : Minterrupts, d : Minterrupts) -> Minterrupts = {
  let vs = Mk_Minterrupts(zeros());
  /* Standard S-mode bits in vsie are aliases of corresponding VS-mode bits in
    hie if delegated by hideleg */
  let vs = update_SEI(vs, m.VSEI() & d.VSEI());
  let vs = update_STI(vs, m.VSTI() & d.VSTI());
  let vs = update_SSI(vs, m.VSSI() & d.VSSI());
  vs
}

/* **************************************************************** */
/* Virtual Supervisor address translation & Protection              */

register vsatp : xlenbits
