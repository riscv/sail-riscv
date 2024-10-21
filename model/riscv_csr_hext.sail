/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/
/* Mapping of hypervisor extension CSR addresses to their names. */

/* extra machine registers */
mapping clause csr_name_map = 0x34B  <-> "mtval2"
mapping clause csr_name_map = 0x34A  <-> "mtinst"

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
