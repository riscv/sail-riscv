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
