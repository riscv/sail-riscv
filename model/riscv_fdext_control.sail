/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* **************************************************************** */
/* Floating point register file and accessors for F, D extensions   */
/* Floating point CSR and accessors                                 */
/* **************************************************************** */

/* Original version written by Rishiyur S. Nikhil, Sept-Oct 2019    */

/* **************************************************************** */

function clause extensionEnabled(Ext_F) = (misa[F] == 0b1) & (mstatus[FS] != 0b00)
function clause extensionEnabled(Ext_D) = (misa[D] == 0b1) & (mstatus[FS] != 0b00) & flen >= 64
function clause extensionEnabled(Ext_Zfinx) = sys_enable_zfinx()

/* Floating Point CSRs */
mapping clause csr_name_map = 0x001  <-> "fflags"
mapping clause csr_name_map = 0x002  <-> "frm"
mapping clause csr_name_map = 0x003  <-> "fcsr"

function clause is_CSR_defined (0x001) = extensionEnabled(Ext_F) | extensionEnabled(Ext_Zfinx)
function clause is_CSR_defined (0x002) = extensionEnabled(Ext_F) | extensionEnabled(Ext_Zfinx)
function clause is_CSR_defined (0x003) = extensionEnabled(Ext_F) | extensionEnabled(Ext_Zfinx)

function clause read_CSR (0x001) = zero_extend(fcsr[FFLAGS])
function clause read_CSR (0x002) = zero_extend(fcsr[FRM])
function clause read_CSR (0x003) = zero_extend(fcsr.bits)

function clause write_CSR (0x001, value) = { write_fcsr(fcsr[FRM], value[4..0]); zero_extend(fcsr[FFLAGS]) }
function clause write_CSR (0x002, value) = { write_fcsr(value[2..0], fcsr[FFLAGS]); zero_extend(fcsr[FRM]) }
function clause write_CSR (0x003, value) = { write_fcsr(value[7..5], value[4..0]); zero_extend(fcsr.bits) }

/* **************************************************************** */
