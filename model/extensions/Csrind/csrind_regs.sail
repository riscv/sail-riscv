// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Smcsrind) = hartSupports(Ext_Smcsrind) & currentlyEnabled(Ext_Zicsr)
function clause currentlyEnabled(Ext_Sscsrind) = (hartSupports(Ext_Sscsrind) | currentlyEnabled(Ext_Smcsrind)) & currentlyEnabled(Ext_Zicsr) & currentlyEnabled(Ext_S)

bitfield Iselect : xlenbits = {
  value : 11 .. 0,
}

register miselect  : Iselect
register siselect  : Iselect
register vsiselect : Iselect

enum IregType = { Mireg, Sireg, Vsireg }

function legalize_iselect(v : xlenbits) -> Iselect = Mk_Iselect(zero_extend(v[11 .. 0]))

// True when sel maps to a register reachable via *ireg*.
// NOTE: no dependent extension uses the window yet, so this is always false.
function indirect_reg_implemented(_ireg : IregType, _sel : Iselect, _i : range(1, 6)) -> bool =
  false

// Access the selected register, dispatched on sel. Unreachable until a select
// is implemented. set_ireg returns Err(()) for an illegal access.
function get_ireg(_ireg : IregType, _sel : Iselect, _i : range(1, 6)) -> xlenbits =
  zeros()

function set_ireg(_ireg : IregType, _sel : Iselect, _i : range(1, 6), _value : xlenbits) -> result(xlenbits, unit) =
  Err(())

function read_siselect() -> xlenbits = if inVirtualPrivilege() then vsiselect.bits else siselect.bits

function write_siselect(value : xlenbits) -> result(xlenbits, unit) =
  if inVirtualPrivilege()
  then { vsiselect = legalize_iselect(value); Ok(vsiselect.bits) }
  else { siselect  = legalize_iselect(value); Ok(siselect.bits) }

function read_sireg(i : range(1, 6)) -> xlenbits =
  if inVirtualPrivilege()
  then get_ireg(Vsireg, vsiselect, i)
  else get_ireg(Sireg, siselect, i)

function write_sireg(i : range(1, 6), value : xlenbits) -> result(xlenbits, unit) =
  if inVirtualPrivilege()
  then set_ireg(Vsireg, vsiselect, i, value)
  else set_ireg(Sireg, siselect, i, value)

function sireg_accessible(i : range(1, 6)) -> bool =
  if inVirtualPrivilege()
  then indirect_reg_implemented(Vsireg, vsiselect, i)
  else indirect_reg_implemented(Sireg, siselect, i)

// vsireg* is reachable only from M/HS.
function vsireg_accessible(i : range(1, 6)) -> bool =
  not(inVirtualPrivilege()) & indirect_reg_implemented(Vsireg, vsiselect, i)

// Picks virtual vs illegal for a failed sireg* access from VS/VU.
// NOTE: "the hypervisor extension's usual rules for when to raise a
// virtual-instruction exception (based on whether an instruction is
// HS-qualified) are not applicable" here.
// TODO: VS access should also be virtual when vsiselect "holds a value that is
// implemented at HS level but not at VS level". Unreachable for now as no select
// is implemented at either level.
function is_sireg_exception_virtual(priv : Privilege) -> bool =
  match priv {
    VirtualUser       => mstateen0_csrind(),
    VirtualSupervisor => mstateen0_csrind() & not(hstateen0_csrind()),
    _                 => false,
  }

// Machine indirect register select and alias CSRs
mapping clause csr_name_map = 0x350  <-> "miselect"
mapping clause csr_name_map = 0x351  <-> "mireg"
mapping clause csr_name_map = 0x352  <-> "mireg2"
mapping clause csr_name_map = 0x353  <-> "mireg3"
mapping clause csr_name_map = 0x355  <-> "mireg4"
mapping clause csr_name_map = 0x356  <-> "mireg5"
mapping clause csr_name_map = 0x357  <-> "mireg6"

// Supervisor indirect register select and alias CSRs
mapping clause csr_name_map = 0x150  <-> "siselect"
mapping clause csr_name_map = 0x151  <-> "sireg"
mapping clause csr_name_map = 0x152  <-> "sireg2"
mapping clause csr_name_map = 0x153  <-> "sireg3"
mapping clause csr_name_map = 0x155  <-> "sireg4"
mapping clause csr_name_map = 0x156  <-> "sireg5"
mapping clause csr_name_map = 0x157  <-> "sireg6"

// Virtual-supervisor indirect register select and alias CSRs
mapping clause csr_name_map = 0x250  <-> "vsiselect"
mapping clause csr_name_map = 0x251  <-> "vsireg"
mapping clause csr_name_map = 0x252  <-> "vsireg2"
mapping clause csr_name_map = 0x253  <-> "vsireg3"
mapping clause csr_name_map = 0x255  <-> "vsireg4"
mapping clause csr_name_map = 0x256  <-> "vsireg5"
mapping clause csr_name_map = 0x257  <-> "vsireg6"

// *iselect always exists. The *ireg* aliases exist only when the select is implemented.
function clause is_CSR_accessible(0x350, _, _) = currentlyEnabled(Ext_Smcsrind)
function clause is_CSR_accessible(0x351, _, _) = currentlyEnabled(Ext_Smcsrind) & indirect_reg_implemented(Mireg, miselect, 1)
function clause is_CSR_accessible(0x352, _, _) = currentlyEnabled(Ext_Smcsrind) & indirect_reg_implemented(Mireg, miselect, 2)
function clause is_CSR_accessible(0x353, _, _) = currentlyEnabled(Ext_Smcsrind) & indirect_reg_implemented(Mireg, miselect, 3)
function clause is_CSR_accessible(0x355, _, _) = currentlyEnabled(Ext_Smcsrind) & indirect_reg_implemented(Mireg, miselect, 4)
function clause is_CSR_accessible(0x356, _, _) = currentlyEnabled(Ext_Smcsrind) & indirect_reg_implemented(Mireg, miselect, 5)
function clause is_CSR_accessible(0x357, _, _) = currentlyEnabled(Ext_Smcsrind) & indirect_reg_implemented(Mireg, miselect, 6)

function clause is_CSR_accessible(0x150, _, _) = currentlyEnabled(Ext_Sscsrind)
function clause is_CSR_accessible(0x151, _, _) = currentlyEnabled(Ext_Sscsrind) & sireg_accessible(1)
function clause is_CSR_accessible(0x152, _, _) = currentlyEnabled(Ext_Sscsrind) & sireg_accessible(2)
function clause is_CSR_accessible(0x153, _, _) = currentlyEnabled(Ext_Sscsrind) & sireg_accessible(3)
function clause is_CSR_accessible(0x155, _, _) = currentlyEnabled(Ext_Sscsrind) & sireg_accessible(4)
function clause is_CSR_accessible(0x156, _, _) = currentlyEnabled(Ext_Sscsrind) & sireg_accessible(5)
function clause is_CSR_accessible(0x157, _, _) = currentlyEnabled(Ext_Sscsrind) & sireg_accessible(6)

function clause is_CSR_accessible(0x250, _, _) = currentlyEnabled(Ext_Sscsrind) & currentlyEnabled(Ext_H)
function clause is_CSR_accessible(0x251, _, _) = currentlyEnabled(Ext_Sscsrind) & currentlyEnabled(Ext_H) & vsireg_accessible(1)
function clause is_CSR_accessible(0x252, _, _) = currentlyEnabled(Ext_Sscsrind) & currentlyEnabled(Ext_H) & vsireg_accessible(2)
function clause is_CSR_accessible(0x253, _, _) = currentlyEnabled(Ext_Sscsrind) & currentlyEnabled(Ext_H) & vsireg_accessible(3)
function clause is_CSR_accessible(0x255, _, _) = currentlyEnabled(Ext_Sscsrind) & currentlyEnabled(Ext_H) & vsireg_accessible(4)
function clause is_CSR_accessible(0x256, _, _) = currentlyEnabled(Ext_Sscsrind) & currentlyEnabled(Ext_H) & vsireg_accessible(5)
function clause is_CSR_accessible(0x257, _, _) = currentlyEnabled(Ext_Sscsrind) & currentlyEnabled(Ext_H) & vsireg_accessible(6)

function clause is_CSR_exception_virtual(0x150, priv, _) = is_sireg_exception_virtual(priv)
function clause is_CSR_exception_virtual(0x151, priv, _) = is_sireg_exception_virtual(priv)
function clause is_CSR_exception_virtual(0x152, priv, _) = is_sireg_exception_virtual(priv)
function clause is_CSR_exception_virtual(0x153, priv, _) = is_sireg_exception_virtual(priv)
function clause is_CSR_exception_virtual(0x155, priv, _) = is_sireg_exception_virtual(priv)
function clause is_CSR_exception_virtual(0x156, priv, _) = is_sireg_exception_virtual(priv)
function clause is_CSR_exception_virtual(0x157, priv, _) = is_sireg_exception_virtual(priv)

// NOTE: "if mstateen0[60] = 1, a virtual-instruction exception is raised ... for
// all attempts from VS-mode or VU-mode to directly access vsiselect or vsireg*".
function clause is_CSR_exception_virtual(0x250, _, _) = mstateen0_csrind()
function clause is_CSR_exception_virtual(0x251, _, _) = mstateen0_csrind()
function clause is_CSR_exception_virtual(0x252, _, _) = mstateen0_csrind()
function clause is_CSR_exception_virtual(0x253, _, _) = mstateen0_csrind()
function clause is_CSR_exception_virtual(0x255, _, _) = mstateen0_csrind()
function clause is_CSR_exception_virtual(0x256, _, _) = mstateen0_csrind()
function clause is_CSR_exception_virtual(0x257, _, _) = mstateen0_csrind()

function clause read_CSR(0x350) = miselect.bits
function clause read_CSR(0x351) = get_ireg(Mireg, miselect, 1)
function clause read_CSR(0x352) = get_ireg(Mireg, miselect, 2)
function clause read_CSR(0x353) = get_ireg(Mireg, miselect, 3)
function clause read_CSR(0x355) = get_ireg(Mireg, miselect, 4)
function clause read_CSR(0x356) = get_ireg(Mireg, miselect, 5)
function clause read_CSR(0x357) = get_ireg(Mireg, miselect, 6)

function clause read_CSR(0x150) = read_siselect()
function clause read_CSR(0x151) = read_sireg(1)
function clause read_CSR(0x152) = read_sireg(2)
function clause read_CSR(0x153) = read_sireg(3)
function clause read_CSR(0x155) = read_sireg(4)
function clause read_CSR(0x156) = read_sireg(5)
function clause read_CSR(0x157) = read_sireg(6)

function clause read_CSR(0x250) = vsiselect.bits
function clause read_CSR(0x251) = get_ireg(Vsireg, vsiselect, 1)
function clause read_CSR(0x252) = get_ireg(Vsireg, vsiselect, 2)
function clause read_CSR(0x253) = get_ireg(Vsireg, vsiselect, 3)
function clause read_CSR(0x255) = get_ireg(Vsireg, vsiselect, 4)
function clause read_CSR(0x256) = get_ireg(Vsireg, vsiselect, 5)
function clause read_CSR(0x257) = get_ireg(Vsireg, vsiselect, 6)

function clause write_CSR(0x350, value) = { miselect = legalize_iselect(value); Ok(miselect.bits) }
function clause write_CSR(0x351, value) = set_ireg(Mireg, miselect, 1, value)
function clause write_CSR(0x352, value) = set_ireg(Mireg, miselect, 2, value)
function clause write_CSR(0x353, value) = set_ireg(Mireg, miselect, 3, value)
function clause write_CSR(0x355, value) = set_ireg(Mireg, miselect, 4, value)
function clause write_CSR(0x356, value) = set_ireg(Mireg, miselect, 5, value)
function clause write_CSR(0x357, value) = set_ireg(Mireg, miselect, 6, value)

function clause write_CSR(0x150, value) = write_siselect(value)
function clause write_CSR(0x151, value) = write_sireg(1, value)
function clause write_CSR(0x152, value) = write_sireg(2, value)
function clause write_CSR(0x153, value) = write_sireg(3, value)
function clause write_CSR(0x155, value) = write_sireg(4, value)
function clause write_CSR(0x156, value) = write_sireg(5, value)
function clause write_CSR(0x157, value) = write_sireg(6, value)

function clause write_CSR(0x250, value) = { vsiselect = legalize_iselect(value); Ok(vsiselect.bits) }
function clause write_CSR(0x251, value) = set_ireg(Vsireg, vsiselect, 1, value)
function clause write_CSR(0x252, value) = set_ireg(Vsireg, vsiselect, 2, value)
function clause write_CSR(0x253, value) = set_ireg(Vsireg, vsiselect, 3, value)
function clause write_CSR(0x255, value) = set_ireg(Vsireg, vsiselect, 4, value)
function clause write_CSR(0x256, value) = set_ireg(Vsireg, vsiselect, 5, value)
function clause write_CSR(0x257, value) = set_ireg(Vsireg, vsiselect, 6, value)
