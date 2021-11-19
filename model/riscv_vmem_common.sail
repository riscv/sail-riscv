/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2021                                                              */
/*    Prashanth Mundkur                                                                  */
/*    Rishiyur S. Nikhil and Bluespec, Inc.                                              */
/*    Jon French                                                                         */
/*    Brian Campbell                                                                     */
/*    Robert Norton-Wright                                                               */
/*    Alasdair Armstrong                                                                 */
/*    Thomas Bauereiss                                                                   */
/*    Shaked Flur                                                                        */
/*    Christopher Pulte                                                                  */
/*    Peter Sewell                                                                       */
/*    Alexander Richardson                                                               */
/*    Hesham Almatary                                                                    */
/*    Jessica Clarke                                                                     */
/*    Microsoft, for contributions by Robert Norton-Wright and Nathaniel Wesley Filardo  */
/*    Peter Rugg                                                                         */
/*    Aril Computer Corp., for contributions by Scott Johnson                            */
/*                                                                                       */
/*  All rights reserved.                                                                 */
/*                                                                                       */
/*  This software was developed by the above within the Rigorous                         */
/*  Engineering of Mainstream Systems (REMS) project, partly funded by                   */
/*  EPSRC grant EP/K008528/1, at the Universities of Cambridge and                       */
/*  Edinburgh.                                                                           */
/*                                                                                       */
/*  This software was developed by SRI International and the University of               */
/*  Cambridge Computer Laboratory (Department of Computer Science and                    */
/*  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and                 */
/*  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA                 */
/*  SSITH research programme.                                                            */
/*                                                                                       */
/*  This project has received funding from the European Research Council                 */
/*  (ERC) under the European Union’s Horizon 2020 research and innovation                */
/*  programme (grant agreement 789108, ELVER).                                           */
/*                                                                                       */
/*                                                                                       */
/*  Redistribution and use in source and binary forms, with or without                   */
/*  modification, are permitted provided that the following conditions                   */
/*  are met:                                                                             */
/*  1. Redistributions of source code must retain the above copyright                    */
/*     notice, this list of conditions and the following disclaimer.                     */
/*  2. Redistributions in binary form must reproduce the above copyright                 */
/*     notice, this list of conditions and the following disclaimer in                   */
/*     the documentation and/or other materials provided with the                        */
/*     distribution.                                                                     */
/*                                                                                       */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''                   */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                    */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A                      */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR                  */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,                         */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT                     */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF                     */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND                  */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,                   */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                   */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF                   */
/*  SUCH DAMAGE.                                                                         */
/*=======================================================================================*/

/* Shared definitions for supervisor-mode page-table-entries and permission checks.
 *
 * These definitions are independent of xlen and do not involve
 * accessing physical memory.
 */

/* PageSize */

let PAGESIZE_BITS = 12

/*
 * Definitions for RV32, which has a single address translation mode: Sv32.
 */

type vaddr32 = bits(32)
type paddr32 = bits(34)
type pte32   = bits(32)
type asid32 = bits(9)

/* Sv32 parameters and bitfield layouts */

let SV32_LEVEL_BITS = 10
let SV32_LEVELS     = 2
let PTE32_LOG_SIZE  = 2
let PTE32_SIZE      = 4

bitfield SV32_Vaddr : vaddr32 = {
  VPNi  : 31 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV32_Paddr : paddr32 = {
  PPNi  : 33 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV32_PTE : pte32 = {
  PPNi  : 31 .. 10,
  RSW   : 9  .. 8,
  BITS  : 7  .. 0
}

/*
 * Definitions for RV64, which has two defined address translation modes: Sv39 and Sv48.
 */

/* Sv48 and Sv64 are reserved but not defined.  The size of the VPN
 * increases by 9 bits through Sv39, Sv48 and Sv57, but not for Sv64.
 * Also, the 45-bit size of the VPN for Sv57 exceeds the 44-bit size
 * of the PPN in satp64.  Due to these corner cases, it is unlikely
 * that definitions can be shared across all four schemes, so separate
 * definitions might eventually be needed for each translation mode.
 *
 * But to keep things simple for now, since Sv39 and Sv48 have the
 * same PPN size, we share some definitions.
 */

type paddr64 = bits(56)
type pte64   = bits(64)
type asid64 = bits(16)

/* Sv39 parameters and bitfield layouts */

let SV39_LEVEL_BITS = 9
let SV39_LEVELS     = 3
let PTE39_LOG_SIZE  = 3
let PTE39_SIZE      = 8

type vaddr39 = bits(39)

bitfield SV39_Vaddr : vaddr39 = {
  VPNi  : 38 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV39_Paddr : paddr64 = {
  PPNi  : 55 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV39_PTE : pte64 = {
  Ext   : 63 .. 54,
  PPNi  : 53 .. 10,
  RSW   : 9  .. 8,
  BITS  : 7  .. 0
}

/* Sv48 parameters and bitfield layouts */

let SV48_LEVEL_BITS = 9
let SV48_LEVELS     = 4
let PTE48_LOG_SIZE  = 3
let PTE48_SIZE      = 8

type vaddr48 = bits(48)
type pte48   = bits(64)

bitfield SV48_Vaddr : vaddr48 = {
  VPNi  : 47 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV48_Paddr : paddr64 = {
  PPNi  : 55 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV48_PTE : pte48 = {
  Ext   : 63 .. 54,
  PPNi  : 53 .. 10,
  RSW   : 9  .. 8,
  BITS  : 7  .. 0
}

/* The types below are parameterized by 'paddr and 'pte to support
 * various architectural widths (e.g. RV32, RV64).  ext_ptw supports
 * extensions to the default address translation and page-table-walk.
 */

/* Result of a page-table walk.  */

union PTW_Result('paddr : Type, 'pte : Type) = {
  PTW_Success: ('paddr, 'pte, 'paddr, nat, bool, ext_ptw),
  PTW_Failure: (PTW_Error, ext_ptw)
}

/* Result of address translation */

union TR_Result('paddr : Type, 'failure : Type) = {
  TR_Address : ('paddr, ext_ptw),
  TR_Failure : ('failure, ext_ptw)
}
