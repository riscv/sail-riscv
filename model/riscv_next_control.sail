/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Functional specification for the 'N' user-level interrupts standard extension. */

function clause is_CSR_defined(0x000) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // ustatus
function clause is_CSR_defined(0x004) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // uie
function clause is_CSR_defined(0x005) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // utvec
function clause is_CSR_defined(0x040) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // uscratch
function clause is_CSR_defined(0x041) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // uepc
function clause is_CSR_defined(0x042) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // ucause
function clause is_CSR_defined(0x043) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // utval
function clause is_CSR_defined(0x044) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // uip

function clause read_CSR(0x000) = lower_sstatus(lower_mstatus(mstatus)).bits
function clause read_CSR(0x004) = lower_sie(lower_mie(mie, mideleg), sideleg).bits
function clause read_CSR(0x005) = get_utvec()
function clause read_CSR(0x040) = uscratch
function clause read_CSR(0x041) = get_xret_target(User) & pc_alignment_mask()
function clause read_CSR(0x042) = ucause.bits
function clause read_CSR(0x043) = utval
function clause read_CSR(0x044) = lower_sip(lower_mip(mip, mideleg), sideleg).bits

function clause write_CSR(0x000, value) = { mstatus = legalize_ustatus(mstatus, value); mstatus.bits }
function clause write_CSR(0x004, value) = { let sie = legalize_uie(lower_mie(mie, mideleg), sideleg, value);
                                                 mie = lift_sie(mie, mideleg, sie);
                                                 mie.bits }
function clause write_CSR(0x005, value) = { set_utvec(value) }
function clause write_CSR(0x040, value) = { uscratch = value; uscratch }
function clause write_CSR(0x041, value) = { set_xret_target(User, value) }
function clause write_CSR(0x042, value) = { ucause.bits = value; ucause.bits }
function clause write_CSR(0x043, value) = { utval = value; utval }
function clause write_CSR(0x044, value) = { let sip = legalize_uip(lower_mip(mip, mideleg), sideleg, value);
                                                 mip = lift_sip(mip, mideleg, sip);
                                                 mip.bits }
