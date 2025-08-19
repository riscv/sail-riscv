/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zihintntl) = hartSupports(Ext_Zihintntl)

/* ****************************************************************** */

union clause instruction = NTL : ntl_type

// NTL is encoded as an ADD
mapping clause encdec = NTL(op)
  <-> 0b0000000 @ encdec_ntl(op) @ 0b00000 @ 0b000 @ 0b00000 @ 0b0110011
  when currentlyEnabled(Ext_Zihintntl)

// NTL is a hint
function clause execute NTL(_) = RETIRE_SUCCESS

mapping clause assembly = NTL(op) <-> "ntl." ^ ntl_name(op)

/* ****************************************************************** */

union clause instruction = C_NTL : ntl_type

// C.NTL is encoded as an C.ADD
mapping clause encdec_compressed = C_NTL(op)
  <-> 0b100 @ 0b1 @ 0b00000 @ encdec_ntl(op) @ 0b10
  when currentlyEnabled(Ext_Zihintntl) & currentlyEnabled(Ext_Zca)

// C.NTL is a hint
function clause execute C_NTL(_) = RETIRE_SUCCESS

mapping clause assembly = C_NTL(op) <-> "c.ntl." ^ ntl_name(op)
