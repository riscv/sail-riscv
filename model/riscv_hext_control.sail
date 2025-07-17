/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// TODO: Ext_H depends on RV32I or RV64I, not RV32E or RV64E.
function clause currentlyEnabled(Ext_H) = hartSupports(Ext_H) & misa[H] == 0b1 & virtual_memory_supported()

/* extra machine registers */
mapping clause csr_name_map = 0x34A  <-> "mtinst"
mapping clause csr_name_map = 0x34B  <-> "mtval2"

/* hypervisor trap setup */
mapping clause csr_name_map = 0x600  <-> "hstatus"
mapping clause csr_name_map = 0x602  <-> "hedeleg"
mapping clause csr_name_map = 0x603  <-> "hideleg"
mapping clause csr_name_map = 0x604  <-> "hie"
mapping clause csr_name_map = 0x606  <-> "hcounteren"
mapping clause csr_name_map = 0x607  <-> "hgeie"

/* hypervisor counter/timer virtualization */
mapping clause csr_name_map = 0x605  <-> "htimedelta"
mapping clause csr_name_map = 0x615  <-> "htimedeltah"

/* hypervisor config */
mapping clause csr_name_map = 0x60A  <-> "henvcfg"
mapping clause csr_name_map = 0x61A  <-> "henvcfgh"

/* hypervisor trap handling */
mapping clause csr_name_map = 0x643  <-> "htval"
mapping clause csr_name_map = 0x644  <-> "hip"
mapping clause csr_name_map = 0x645  <-> "hvip"
mapping clause csr_name_map = 0x64A  <-> "htinst"
mapping clause csr_name_map = 0xE12  <-> "hgeip"

/* hypervisor protection and translation */
mapping clause csr_name_map = 0x680  <-> "hgatp"

/* virtual supervisor registers */
mapping clause csr_name_map = 0x200  <-> "vsstatus"
mapping clause csr_name_map = 0x204  <-> "vsie"
mapping clause csr_name_map = 0x205  <-> "vstvec"
mapping clause csr_name_map = 0x240  <-> "vsscratch"
mapping clause csr_name_map = 0x241  <-> "vsepc"
mapping clause csr_name_map = 0x242  <-> "vscause"
mapping clause csr_name_map = 0x243  <-> "vstval"
mapping clause csr_name_map = 0x244  <-> "vsip"
mapping clause csr_name_map = 0x280  <-> "vsatp"

function clause is_CSR_defined(0x34A) = currentlyEnabled(Ext_H) // mtinst
function clause is_CSR_defined(0x34B) = currentlyEnabled(Ext_H) // mtval2
function clause is_CSR_defined(0x600) = currentlyEnabled(Ext_H) // hstatus
function clause is_CSR_defined(0x602) = currentlyEnabled(Ext_H) // hedeleg
function clause is_CSR_defined(0x603) = currentlyEnabled(Ext_H) // hideleg
function clause is_CSR_defined(0x604) = currentlyEnabled(Ext_H) // hie
function clause is_CSR_defined(0x606) = currentlyEnabled(Ext_H) // hcounteren
function clause is_CSR_defined(0x607) = currentlyEnabled(Ext_H) // hgeie
function clause is_CSR_defined(0x643) = currentlyEnabled(Ext_H) // htval
function clause is_CSR_defined(0x644) = currentlyEnabled(Ext_H) // hip
function clause is_CSR_defined(0x645) = currentlyEnabled(Ext_H) // hvip
function clause is_CSR_defined(0x64A) = currentlyEnabled(Ext_H) // htinst
function clause is_CSR_defined(0xE12) = currentlyEnabled(Ext_H) // hgeip
function clause is_CSR_defined(0x60A) = currentlyEnabled(Ext_H) // henvcfg
function clause is_CSR_defined(0x61A) = currentlyEnabled(Ext_H) // henvcfgh
function clause is_CSR_defined(0x680) = currentlyEnabled(Ext_H) // hgatp
function clause is_CSR_defined(0x605) = currentlyEnabled(Ext_H) // htimedelta
function clause is_CSR_defined(0x615) = currentlyEnabled(Ext_H) // htimedeltah
function clause is_CSR_defined(0x200) = currentlyEnabled(Ext_H) // vsstatus
function clause is_CSR_defined(0x204) = currentlyEnabled(Ext_H) // vsie
function clause is_CSR_defined(0x205) = currentlyEnabled(Ext_H) // vstvec
function clause is_CSR_defined(0x240) = currentlyEnabled(Ext_H) // vsscratch
function clause is_CSR_defined(0x241) = currentlyEnabled(Ext_H) // vsepc
function clause is_CSR_defined(0x242) = currentlyEnabled(Ext_H) // vscause
function clause is_CSR_defined(0x243) = currentlyEnabled(Ext_H) // vstval
function clause is_CSR_defined(0x244) = currentlyEnabled(Ext_H) // vsip
function clause is_CSR_defined(0x280) = currentlyEnabled(Ext_H) // vsatp
