// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// TODO: Ext_H depends on RV32I or RV64I, not RV32E or RV64E.
function clause currentlyEnabled(Ext_H) = hartSupports(Ext_H) & misa[H] == 0b1 & virtual_memory_supported() & currentlyEnabled(Ext_U)

// extra machine registers
// mapping clause csr_name_map = 0x34A  <-> "mtinst"
// mapping clause csr_name_map = 0x34B  <-> "mtval2"

// function clause is_CSR_accessible(0x34A) = currentlyEnabled(Ext_H) // mtinst
// function clause is_CSR_accessible(0x34B) = currentlyEnabled(Ext_H) // mtval2

// Hypervisor Trap Setup

// mapping clause csr_name_map = 0x604  <-> "hie"
// mapping clause csr_name_map = 0x606  <-> "hcounteren"
// mapping clause csr_name_map = 0x607  <-> "hgeie"
// mapping clause csr_name_map = 0x612  <-> "hedelegh"


// function clause is_CSR_accessible(0x604) = currentlyEnabled(Ext_H) // hie
// function clause is_CSR_accessible(0x606) = currentlyEnabled(Ext_H) // hcounteren
// function clause is_CSR_accessible(0x607) = currentlyEnabled(Ext_H) // hgeie
// function clause is_CSR_accessible(0x612) = currentlyEnabled(Ext_H) & xlen == 32 // hedelegh

// Hypervisor Trap Handling
// mapping clause csr_name_map = 0x643  <-> "htval"
// mapping clause csr_name_map = 0x644  <-> "hip"
// mapping clause csr_name_map = 0x645  <-> "hvip"
// mapping clause csr_name_map = 0x64A  <-> "htinst"
// mapping clause csr_name_map = 0xE12  <-> "hgeip"

// function clause is_CSR_accessible(0x643) = currentlyEnabled(Ext_H) // htval
// function clause is_CSR_accessible(0x644) = currentlyEnabled(Ext_H) // hip
// function clause is_CSR_accessible(0x645) = currentlyEnabled(Ext_H) // hvip
// function clause is_CSR_accessible(0x64A) = currentlyEnabled(Ext_H) // htinst
// function clause is_CSR_accessible(0xE12) = currentlyEnabled(Ext_H) // hgeip

// Hypervisor Configuration
// mapping clause csr_name_map = 0x60A  <-> "henvcfg"
// mapping clause csr_name_map = 0x61A  <-> "henvcfgh"

// function clause is_CSR_accessible(0x60A) = currentlyEnabled(Ext_H) // henvcfg
// function clause is_CSR_accessible(0x61A) = currentlyEnabled(Ext_H) & xlen == 32 // henvcfgh

// Hypervisor Protection and Translation
// mapping clause csr_name_map = 0x680  <-> "hgatp"

// function clause is_CSR_accessible(0x680) = currentlyEnabled(Ext_H) // hgatp

// Debug/Trace Registers
// mapping clause csr_name_map = 0x6A8  <-> "hcontext"

// function clause is_CSR_accessible(0x6A8) = currentlyEnabled(Ext_H) // hcontext

// Virtual Supervisor Registers

// mapping clause csr_name_map = 0x204  <-> "vsie"
// mapping clause csr_name_map = 0x240  <-> "vsscratch"
// mapping clause csr_name_map = 0x244  <-> "vsip"
// mapping clause csr_name_map = 0x280  <-> "vsatp"

// function clause is_CSR_accessible(0x204) = currentlyEnabled(Ext_H) // vsie
// function clause is_CSR_accessible(0x240) = currentlyEnabled(Ext_H) & xlen == 32 // vsscratch
// function clause is_CSR_accessible(0x244) = currentlyEnabled(Ext_H) // vsip
// function clause is_CSR_accessible(0x280) = currentlyEnabled(Ext_H) // vsatp

// // Hypervisor Counter/Timer Virtualization Registers
// mapping clause csr_name_map = 0x605  <-> "htimedelta"
// mapping clause csr_name_map = 0x615  <-> "htimedeltah"

// function clause is_CSR_accessible(0x605) = currentlyEnabled(Ext_H) // htimedelta
// function clause is_CSR_accessible(0x615) = currentlyEnabled(Ext_H) // htimedeltah

// Hypervisor State Enable Registers
// mapping clause csr_name_map = 0x60C  <-> "hstateen0"
// mapping clause csr_name_map = 0x60D  <-> "hstateen1"
// mapping clause csr_name_map = 0x60E  <-> "hstateen2"
// mapping clause csr_name_map = 0x60F  <-> "hstateen3"
// mapping clause csr_name_map = 0x61C  <-> "hstateen0h"
// mapping clause csr_name_map = 0x61D  <-> "hstateen1h"
// mapping clause csr_name_map = 0x61E  <-> "hstateen2h"
// mapping clause csr_name_map = 0x61F  <-> "hstateen3h"

// function clause is_CSR_accessible(0x60C) = currentlyEnabled(Ext_H) // hstateen0
// function clause is_CSR_accessible(0x60D) = currentlyEnabled(Ext_H) // hstateen1
// function clause is_CSR_accessible(0x60E) = currentlyEnabled(Ext_H) // hstateen2
// function clause is_CSR_accessible(0x60F) = currentlyEnabled(Ext_H) // hstateen3
// function clause is_CSR_accessible(0x61C) = currentlyEnabled(Ext_H) & xlen == 32 // hstateen0h
// function clause is_CSR_accessible(0x61D) = currentlyEnabled(Ext_H) & xlen == 32 // hstateen1h
// function clause is_CSR_accessible(0x61E) = currentlyEnabled(Ext_H) & xlen == 32 // hstateen2h
// function clause is_CSR_accessible(0x61F) = currentlyEnabled(Ext_H) & xlen == 32 // hstateen3h

// Virtual Supervisor Indirect
// mapping clause csr_name_map = 0x250  <-> "vsiselect"
// mapping clause csr_name_map = 0x251  <-> "vsireg"
// mapping clause csr_name_map = 0x252  <-> "vsireg1"
// mapping clause csr_name_map = 0x253  <-> "vsireg2"
// mapping clause csr_name_map = 0x254  <-> "vsireg3"
// mapping clause csr_name_map = 0x255  <-> "vsireg4"
// mapping clause csr_name_map = 0x256  <-> "vsireg5"
// mapping clause csr_name_map = 0x257  <-> "vsireg6"

// function clause is_CSR_accessible(0x250) = currentlyEnabled(Ext_H) // "vsiselect"
// function clause is_CSR_accessible(0x251) = currentlyEnabled(Ext_H) // "vsireg"
// function clause is_CSR_accessible(0x252) = currentlyEnabled(Ext_H) // "vsireg1"
// function clause is_CSR_accessible(0x253) = currentlyEnabled(Ext_H) // "vsireg2"
// function clause is_CSR_accessible(0x254) = currentlyEnabled(Ext_H) // "vsireg3"
// function clause is_CSR_accessible(0x255) = currentlyEnabled(Ext_H) // "vsireg4"
// function clause is_CSR_accessible(0x256) = currentlyEnabled(Ext_H) // "vsireg5"
// function clause is_CSR_accessible(0x257) = currentlyEnabled(Ext_H) // "vsireg6"

// // Virtual Supervisor Timer Compare
// mapping clause csr_name_map = 0x24D  <-> "vstimecmp"
// mapping clause csr_name_map = 0x25D  <-> "vstimecmph"

// function clause is_CSR_accessible(0x24D) = currentlyEnabled(Ext_H) // "vstimecmp"
// function clause is_CSR_accessible(0x25D) = currentlyEnabled(Ext_H) & xlen == 32 // "vstimecmph"


// // Virtual Supervisor Control Transfer Records Configuration
// mapping clause csr_name_map = 0x24E  <-> "vsctrctl"
// function clause is_CSR_accessible(0x24E) = currentlyEnabled(Ext_H) // "vsctrctl"

// ! Returns new mip from the previous mip (m) and the written hvip (v)
// function legalize_hvip(m: Minterrupts, v : xlenbits) -> Minterrupts = {
//   let v = Mk_Minterrupts(v);
//   let m = [m with VSEI = v[VSEI]];
//   let m = [m with VSTI = v[VSTI]];
//   let m = [m with VSSI = v[VSSI]];
//   // TODO: Hook to update non-standard portion
//   m
// }



// Hypervisor Status Register

bitfield Hstatus : bits(64) = {
  HUPMM : 49 .. 48,
  VSXL  : 33 .. 32,

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

function get_hstatus_VSXL(h : Hstatus) -> arch_xlen = {
  if sizeof(xlen) == 32
  then architecture_bits(RV32)
  else h[VSXL]
}

function legalize_hstatus(o : Hstatus, v : bits(64)) -> Hstatus = {
  let v = Mk_Hstatus(v);

  [o with
    VTSR  = v[VTSR],
    VTW   = v[VTW],
    VTVM  = v[VTVM],
    VGEIN = v[VGEIN], // Note: 0 <= hstatus.VGEIN <= GEILEN
    HU    = v[HU],
    SPVP  = v[SPVP],
    SPV   = v[SPV],
    GVA   = v[GVA],
    VSBE  = v[VSBE],
  ];
}

register hstatus : Hstatus = [ Mk_Hstatus(zeros()) with
    // These fields do not exist on RV32 and are read-only zero
    // if the corresponding mode is not supported.
    VSXL = architecture_bits(if xlen == 32 then RV32 else RV64)
  ]

mapping clause csr_name_map = 0x600  <-> "hstatus"
function clause is_CSR_accessible(0x600, _, _) = currentlyEnabled(Ext_H) // hstatus
function clause read_CSR(0x600) = hstatus.bits[xlen - 1 .. 0]
function clause write_CSR((0x600, value)  if xlen == 64) = { hstatus = legalize_hstatus(hstatus, value); Ok(hstatus.bits) }
function clause write_CSR((0x600, value)  if xlen == 32) = { hstatus = legalize_hstatus(hstatus, hstatus.bits[63 .. 32] @ value); Ok(hstatus.bits[31 .. 0]) }

// Hypervisor Trap Delegation (hedeleg and hideleg) Registers

function legalize_hedeleg(o: Medeleg, v: bits(64)) -> Medeleg = {
  let h = Mk_Medeleg(v);
  // Mask read-only zero bits
  let h = [h with SAMO_GPage_Fault  = 0b0];
  let h = [h with Virtual_Instr     = 0b0];
  let h = [h with Load_GPage_Fault  = 0b0];
  let h = [h with Fetch_GPage_Fault = 0b0];
  let h = [h with MEnvCall          = 0b0];
  let h = [h with VSEnvCall         = 0b0];
  let h = [h with SEnvCall          = 0b0];
  h
}

function legalize_hideleg(h : Minterrupts, v : xlenbits) -> Minterrupts = {
  let v = Mk_Minterrupts(v);
  // VS-level interrupts can be delegated
  let h = [h with SGEI  = v[SGEI],
     VSEI = v[VSEI],
     VSTI = v[VSTI],
     VSSI = v[VSSI],
  ];
  // Other interrupts can't be delegated to VS-mode
  h
}

register hedeleg : Medeleg     // Exception delegation to S-mode
register hideleg : Minterrupts // Interrupt delegation to S-mode

mapping clause csr_name_map = 0x602  <-> "hedeleg"
mapping clause csr_name_map = 0x612  <-> "hedelegh"
mapping clause csr_name_map = 0x603  <-> "hideleg"

function clause is_CSR_accessible(0x602, _, _) = currentlyEnabled(Ext_H) // hedeleg
function clause is_CSR_accessible(0x612, _, _) = currentlyEnabled(Ext_H) & xlen == 32 // hedelegh
function clause is_CSR_accessible(0x603, _, _) = currentlyEnabled(Ext_H) // hideleg

function clause read_CSR(0x602) = hedeleg.bits[xlen - 1 .. 0]
function clause read_CSR(0x612 if xlen == 32) = hedeleg.bits[63 .. 32]
function clause read_CSR(0x603) = hideleg.bits[xlen - 1 .. 0]

function clause write_CSR((0x602, value) if xlen == 64) = { hedeleg = legalize_hedeleg(hedeleg, value); Ok(hedeleg.bits) }
function clause write_CSR((0x602, value) if xlen == 32) = { hedeleg = legalize_hedeleg(hedeleg, hedeleg.bits[63 .. 32] @ value); Ok(hedeleg.bits[31 .. 0]) }
function clause write_CSR((0x612, value) if xlen == 32) = { hedeleg = legalize_hedeleg(hedeleg, value @ hedeleg.bits[31 .. 0]); Ok(hedeleg.bits[63 .. 32]) }
function clause write_CSR(0x603, value) = { hideleg = legalize_hideleg(hideleg, value); Ok(hideleg.bits) }

mapping clause csr_name_map = 0x200  <-> "vsstatus"
function clause is_CSR_accessible(0x200, _, _) = currentlyEnabled(Ext_H) // vsstatus
function clause read_CSR(0x200) = vsstatus.bits[xlen - 1 .. 0]
function clause write_CSR(0x200, value) = { vsstatus = legalize_vsstatus(vsstatus, zero_extend(value)); Ok(vsstatus.bits[xlen - 1 .. 0]) }

mapping clause csr_name_map = 0x242  <-> "vscause"
mapping clause csr_name_map = 0x241  <-> "vsepc"
mapping clause csr_name_map = 0x243  <-> "vstval"
mapping clause csr_name_map = 0x205  <-> "vstvec"

function clause is_CSR_accessible(0x242, _, _) = currentlyEnabled(Ext_H) // vscause
function clause is_CSR_accessible(0x241, _, _) = currentlyEnabled(Ext_H) // vsepc
function clause is_CSR_accessible(0x243, _, _) = currentlyEnabled(Ext_H) // vstval
function clause is_CSR_accessible(0x205, _, _) = currentlyEnabled(Ext_H) // vstvec

function clause read_CSR(0x242) = vscause.bits
function clause read_CSR(0x241) = get_xepc(VirtualSupervisor)
function clause read_CSR(0x243) = vstval
function clause read_CSR(0x205) = vstvec.bits

function clause write_CSR(0x242, value) = { vscause.bits = value; Ok(vscause.bits) }
function clause write_CSR(0x241, value) = { Ok(set_xepc(VirtualSupervisor, value)) }
function clause write_CSR(0x243, value) = { vstval = value; Ok(vstval) }
function clause write_CSR(0x205, value) = { vstvec.bits = value; Ok(vstvec.bits) }
