/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Smcsrind) = hartSupports(Ext_Smcsrind) & currentlyEnabled(Ext_Zicsr)
function clause currentlyEnabled(Ext_Sscsrind) = (hartSupports(Ext_Sscsrind) | currentlyEnabled(Ext_Smcsrind)) & currentlyEnabled(Ext_Zicsr) & currentlyEnabled(Ext_S)

bitfield Iselect : xlenbits = {
    csr : 11 .. 0
}

register miselect : Iselect
register siselect : Iselect

enum IregType = { Mireg, Sireg }

function legalize_iselect(v : xlenbits) -> Iselect = Mk_Iselect(zero_extend(v[11 .. 0]))

function is_ireg_accessible(i: Iselect, ireg : IregType) -> bool =
    match ireg {
        Mireg => match i[csr] {
            _ => false
        },
        Sireg => match i[csr] {
            _ => false
        },
    }

function get_ireg(ireg : IregType, i : range(0, 6)) -> xlenbits = zeros()
function set_ireg(ireg : IregType, i : range(0, 6), value : xlenbits) -> xlenbits = zeros()

/* Machine indirect register select and alias CSRs */
mapping clause csr_name_map = 0x350  <-> "miselect"
mapping clause csr_name_map = 0x351  <-> "mireg"
mapping clause csr_name_map = 0x352  <-> "mireg2"
mapping clause csr_name_map = 0x353  <-> "mireg3"
mapping clause csr_name_map = 0x355  <-> "mireg4"
mapping clause csr_name_map = 0x356  <-> "mireg5"
mapping clause csr_name_map = 0x357  <-> "mireg6"

/* supervisor indirect register select and alias CSRs */
mapping clause csr_name_map = 0x150  <-> "siselect"
mapping clause csr_name_map = 0x151  <-> "sireg"
mapping clause csr_name_map = 0x152  <-> "sireg2"
mapping clause csr_name_map = 0x153  <-> "sireg3"
mapping clause csr_name_map = 0x155  <-> "sireg4"
mapping clause csr_name_map = 0x156  <-> "sireg5"
mapping clause csr_name_map = 0x157  <-> "sireg6"

function clause is_CSR_accessible(0x350, _, _) = currentlyEnabled(Ext_Smcsrind)
function clause is_CSR_accessible(0x351, _, _) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)
function clause is_CSR_accessible(0x352, _, _) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)
function clause is_CSR_accessible(0x353, _, _) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)
function clause is_CSR_accessible(0x355, _, _) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)
function clause is_CSR_accessible(0x356, _, _) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)
function clause is_CSR_accessible(0x357, _, _) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)

function clause is_CSR_accessible(0x150, _, _) = currentlyEnabled(Ext_Sscsrind)
function clause is_CSR_accessible(0x151, _, _) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)
function clause is_CSR_accessible(0x152, _, _) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)
function clause is_CSR_accessible(0x153, _, _) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)
function clause is_CSR_accessible(0x155, _, _) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)
function clause is_CSR_accessible(0x156, _, _) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)
function clause is_CSR_accessible(0x157, _, _) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)

function clause read_CSR(0x350) = miselect.bits
function clause read_CSR(0x351) = get_ireg(Mireg, 1)
function clause read_CSR(0x352) = get_ireg(Mireg, 2)
function clause read_CSR(0x353) = get_ireg(Mireg, 3)
function clause read_CSR(0x355) = get_ireg(Mireg, 4)
function clause read_CSR(0x356) = get_ireg(Mireg, 5)
function clause read_CSR(0x357) = get_ireg(Mireg, 6)

function clause read_CSR(0x150) = siselect.bits
function clause read_CSR(0x151) = get_ireg(Sireg, 1)
function clause read_CSR(0x152) = get_ireg(Sireg, 2)
function clause read_CSR(0x153) = get_ireg(Sireg, 3)
function clause read_CSR(0x155) = get_ireg(Sireg, 4)
function clause read_CSR(0x156) = get_ireg(Sireg, 5)
function clause read_CSR(0x157) = get_ireg(Sireg, 6)

function clause write_CSR(0x350, value) = { miselect = legalize_iselect(value); Ok(miselect.bits) }
function clause write_CSR(0x351, value) = Ok(set_ireg(Mireg, 1, value))
function clause write_CSR(0x352, value) = Ok(set_ireg(Mireg, 2, value))
function clause write_CSR(0x353, value) = Ok(set_ireg(Mireg, 3, value))
function clause write_CSR(0x355, value) = Ok(set_ireg(Mireg, 4, value))
function clause write_CSR(0x356, value) = Ok(set_ireg(Mireg, 5, value))
function clause write_CSR(0x357, value) = Ok(set_ireg(Mireg, 6, value))

function clause write_CSR(0x150, value) = { siselect = legalize_iselect(value); Ok(siselect.bits) }
function clause write_CSR(0x151, value) = Ok(set_ireg(Sireg, 1, value))
function clause write_CSR(0x152, value) = Ok(set_ireg(Sireg, 2, value))
function clause write_CSR(0x153, value) = Ok(set_ireg(Sireg, 3, value))
function clause write_CSR(0x155, value) = Ok(set_ireg(Sireg, 4, value))
function clause write_CSR(0x156, value) = Ok(set_ireg(Sireg, 5, value))
function clause write_CSR(0x157, value) = Ok(set_ireg(Sireg, 6, value))
