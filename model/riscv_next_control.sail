/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Functional specification for the 'N' user-level interrupts standard extension. */

function clause ext_is_CSR_defined(0x000) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // ustatus
function clause ext_is_CSR_defined(0x004) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // uie
function clause ext_is_CSR_defined(0x005) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // utvec
function clause ext_is_CSR_defined(0x040) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // uscratch
function clause ext_is_CSR_defined(0x041) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // uepc
function clause ext_is_CSR_defined(0x042) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // ucause
function clause ext_is_CSR_defined(0x043) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // utval
function clause ext_is_CSR_defined(0x044) = extensionEnabled(Ext_U) & extensionEnabled(Ext_N) // uip

function clause ext_read_CSR(0x000) = Some(lower_sstatus(lower_mstatus(mstatus)).bits)
function clause ext_read_CSR(0x004) = Some(lower_sie(lower_mie(mie, mideleg), sideleg).bits)
function clause ext_read_CSR(0x005) = Some(get_utvec())
function clause ext_read_CSR(0x040) = Some(uscratch)
function clause ext_read_CSR(0x041) = Some(get_xret_target(User) & pc_alignment_mask())
function clause ext_read_CSR(0x042) = Some(ucause.bits)
function clause ext_read_CSR(0x043) = Some(utval)
function clause ext_read_CSR(0x044) = Some(lower_sip(lower_mip(mip, mideleg), sideleg).bits)

function clause ext_write_CSR(0x000, value) = { mstatus = legalize_ustatus(mstatus, value); Some(mstatus.bits) }
function clause ext_write_CSR(0x004, value) = { let sie = legalize_uie(lower_mie(mie, mideleg), sideleg, value);
                                                 mie = lift_sie(mie, mideleg, sie);
                                                 Some(mie.bits) }
function clause ext_write_CSR(0x005, value) = { Some(set_utvec(value)) }
function clause ext_write_CSR(0x040, value) = { uscratch = value; Some(uscratch) }
function clause ext_write_CSR(0x041, value) = { Some(set_xret_target(User, value)) }
function clause ext_write_CSR(0x042, value) = { ucause.bits = value; Some(ucause.bits) }
function clause ext_write_CSR(0x043, value) = { utval = value; Some(utval) }
function clause ext_write_CSR(0x044, value) = { let sip = legalize_uip(lower_mip(mip, mideleg), sideleg, value);
                                                 mip = lift_sip(mip, mideleg, sip);
                                                 Some(mip.bits) }
