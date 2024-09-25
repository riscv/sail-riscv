/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause is_CSR_defined (0x008) = true
function clause is_CSR_defined (0xC20) = true
function clause is_CSR_defined (0xC21) = true
function clause is_CSR_defined (0xC22) = true

function clause is_CSR_defined (0x009) = true
function clause is_CSR_defined (0x00A) = true
function clause is_CSR_defined (0x00F) = true

function clause read_CSR (0x009) = zero_extend(vcsr[vxsat])
function clause read_CSR (0x00A) = zero_extend(vcsr[vxrm])
function clause read_CSR (0x00F) = zero_extend(vcsr.bits)

function clause read_CSR (0x009) = zero_extend(vcsr[vxsat])
function clause read_CSR (0x00A) = zero_extend(vcsr[vxrm])
function clause read_CSR (0x00F) = zero_extend(vcsr.bits)

function clause write_CSR (0x009, value) = { ext_write_vcsr (vcsr[vxrm], value[0 .. 0]); zero_extend(vcsr[vxsat]) }
function clause write_CSR (0x00A, value) = { ext_write_vcsr (value[1 .. 0], vcsr[vxsat]); zero_extend(vcsr[vxrm]) }
function clause write_CSR (0x00F, value) = { ext_write_vcsr (value [2 .. 1], value [0 .. 0]); zero_extend(vcsr.bits) }
