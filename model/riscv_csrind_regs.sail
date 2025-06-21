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

function legalize_miselect(i: Iselect, v: xlenbits) -> Iselect = { Mk_Iselect(zeros()) }

/*
 * Different from miselect, An extension may be considered not to be implemented at supervisor level
 * if machine level has disabled the extension for S-mode,
 * such as by the settings of certain fields in CSR menvcfg, for example.
 * So this may need to be checked in the future.
 */
function legalize_siselect(i: Iselect, v: xlenbits) -> Iselect = { Mk_Iselect(zeros()) }

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

function clause is_CSR_defined(0x350) = currentlyEnabled(Ext_Smcsrind)
function clause is_CSR_defined(0x351) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)
function clause is_CSR_defined(0x352) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)
function clause is_CSR_defined(0x353) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)
function clause is_CSR_defined(0x355) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)
function clause is_CSR_defined(0x356) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)
function clause is_CSR_defined(0x357) = currentlyEnabled(Ext_Smcsrind) & is_ireg_accessible(miselect, Mireg)

function clause is_CSR_defined(0x150) = currentlyEnabled(Ext_Sscsrind)
function clause is_CSR_defined(0x151) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)
function clause is_CSR_defined(0x152) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)
function clause is_CSR_defined(0x153) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)
function clause is_CSR_defined(0x155) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)
function clause is_CSR_defined(0x156) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)
function clause is_CSR_defined(0x157) = currentlyEnabled(Ext_Sscsrind) & is_ireg_accessible(siselect, Sireg)

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

function clause write_CSR(0x350, value) = { miselect = legalize_miselect(miselect, value); miselect.bits }
function clause write_CSR(0x351, value) = set_ireg(Mireg, 1, value)
function clause write_CSR(0x352, value) = set_ireg(Mireg, 2, value)
function clause write_CSR(0x353, value) = set_ireg(Mireg, 3, value)
function clause write_CSR(0x355, value) = set_ireg(Mireg, 4, value)
function clause write_CSR(0x356, value) = set_ireg(Mireg, 5, value)
function clause write_CSR(0x357, value) = set_ireg(Mireg, 6, value)

function clause write_CSR(0x150, value) = { siselect = legalize_siselect(siselect, value); siselect.bits }
function clause write_CSR(0x151, value) = set_ireg(Sireg, 1, value)
function clause write_CSR(0x152, value) = set_ireg(Sireg, 2, value)
function clause write_CSR(0x153, value) = set_ireg(Sireg, 3, value)
function clause write_CSR(0x155, value) = set_ireg(Sireg, 4, value)
function clause write_CSR(0x156, value) = set_ireg(Sireg, 5, value)
function clause write_CSR(0x157, value) = set_ireg(Sireg, 6, value)
