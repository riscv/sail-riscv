/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_V) = (misa[V] == 0b1) & (mstatus[VS] != 0b00)

mapping clause csr_name_map = 0x008  <-> "vstart"
mapping clause csr_name_map = 0x009  <-> "vxsat"
mapping clause csr_name_map = 0x00A  <-> "vxrm"
mapping clause csr_name_map = 0x00F  <-> "vcsr"
mapping clause csr_name_map = 0xC20  <-> "vl"
mapping clause csr_name_map = 0xC21  <-> "vtype"
mapping clause csr_name_map = 0xC22  <-> "vlenb"

function clause is_CSR_defined (0x008) = extensionEnabled(Ext_V) // vstart
function clause is_CSR_defined (0x009) = extensionEnabled(Ext_V) // vxsat
function clause is_CSR_defined (0x00A) = extensionEnabled(Ext_V) // vxrm
function clause is_CSR_defined (0x00F) = extensionEnabled(Ext_V) // vcsr
function clause is_CSR_defined (0xC20) = extensionEnabled(Ext_V) // vl
function clause is_CSR_defined (0xC21) = extensionEnabled(Ext_V) // vtype
function clause is_CSR_defined (0xC22) = extensionEnabled(Ext_V) // vlenb

function clause read_CSR(0x008) = zero_extend(vstart)
function clause read_CSR(0x009) = zero_extend(vcsr[vxsat])
function clause read_CSR(0x00A) = zero_extend(vcsr[vxrm])
function clause read_CSR(0x00F) = zero_extend(vcsr.bits)
function clause read_CSR(0xC20) = vl
function clause read_CSR(0xC21) = vtype.bits
function clause read_CSR(0xC22) = get_vlenb()

function clause write_CSR(0x008, value) = { dirty_v_context(); let vstart_length = get_vlen_pow(); vstart = zero_extend(16, value[(vstart_length - 1) .. 0]); zero_extend(vstart) }
function clause write_CSR(0x009, value) = { ext_write_vcsr (vcsr[vxrm], value[0 .. 0]); zero_extend(vcsr[vxsat]) }
function clause write_CSR(0x00A, value) = { ext_write_vcsr (value[1 .. 0], vcsr[vxsat]); zero_extend(vcsr[vxrm]) }
function clause write_CSR(0x00F, value) = { ext_write_vcsr (value [2 .. 1], value [0 .. 0]); zero_extend(vcsr.bits) }
