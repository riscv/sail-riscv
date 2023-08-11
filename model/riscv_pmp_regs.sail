/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2023                                                              */
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
/*    Philipp Tomsich                                                                    */
/*    VRULL GmbH, for contributions by its employees                                     */
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

/* PMP configuration entries */

enum PmpAddrMatchType = {OFF, TOR, NA4, NAPOT}

val pmpAddrMatchType_of_bits : bits(2) -> PmpAddrMatchType
function pmpAddrMatchType_of_bits(bs) = {
  match bs {
    0b00 => OFF,
    0b01 => TOR,
    0b10 => NA4,
    0b11 => NAPOT
  }
}

val pmpAddrMatchType_to_bits : PmpAddrMatchType -> bits(2)
function pmpAddrMatchType_to_bits(bs) = {
  match bs {
    OFF   => 0b00,
    TOR   => 0b01,
    NA4   => 0b10,
    NAPOT => 0b11
  }
}

bitfield Pmpcfg_ent : bits(8) = {
  L : 7,        /* locking */
  A : 4 .. 3,   /* address match type, encoded as above */

  /* permissions */
  X : 2,        /* execute */
  W : 1,        /* write */
  R : 0         /* read */
}

register pmp0cfg  : Pmpcfg_ent
register pmp1cfg  : Pmpcfg_ent
register pmp2cfg  : Pmpcfg_ent
register pmp3cfg  : Pmpcfg_ent
register pmp4cfg  : Pmpcfg_ent
register pmp5cfg  : Pmpcfg_ent
register pmp6cfg  : Pmpcfg_ent
register pmp7cfg  : Pmpcfg_ent
register pmp8cfg  : Pmpcfg_ent
register pmp9cfg  : Pmpcfg_ent
register pmp10cfg : Pmpcfg_ent
register pmp11cfg : Pmpcfg_ent
register pmp12cfg : Pmpcfg_ent
register pmp13cfg : Pmpcfg_ent
register pmp14cfg : Pmpcfg_ent
register pmp15cfg : Pmpcfg_ent

/* PMP address configuration */

register pmpaddr0  : xlenbits
register pmpaddr1  : xlenbits
register pmpaddr2  : xlenbits
register pmpaddr3  : xlenbits
register pmpaddr4  : xlenbits
register pmpaddr5  : xlenbits
register pmpaddr6  : xlenbits
register pmpaddr7  : xlenbits
register pmpaddr8  : xlenbits
register pmpaddr9  : xlenbits
register pmpaddr10 : xlenbits
register pmpaddr11 : xlenbits
register pmpaddr12 : xlenbits
register pmpaddr13 : xlenbits
register pmpaddr14 : xlenbits
register pmpaddr15 : xlenbits

/* Packing and unpacking pmpcfg regs for xlen-width accesses */

val pmpReadCfgReg : forall 'n, 0 <= 'n < 4 . (atom('n)) -> xlenbits
function pmpReadCfgReg(n) = {
  if   sizeof(xlen) == 32
  then match n {
         0 => append(pmp3cfg.bits(),  append(pmp2cfg.bits(),  append(pmp1cfg.bits(),  pmp0cfg.bits()))),
         1 => append(pmp7cfg.bits(),  append(pmp6cfg.bits(),  append(pmp5cfg.bits(),  pmp4cfg.bits()))),
         2 => append(pmp11cfg.bits(), append(pmp10cfg.bits(), append(pmp9cfg.bits(),  pmp8cfg.bits()))),
         3 => append(pmp15cfg.bits(), append(pmp14cfg.bits(), append(pmp13cfg.bits(), pmp12cfg.bits()))),
         _ => internal_error(__FILE__, __LINE__, "Unexpected pmp config reg read")
       }
  else match n { //  sizeof(xlen) >= 64
         0 => append(pmp7cfg.bits(),  append(pmp6cfg.bits(),  append(pmp5cfg.bits(),  append(pmp4cfg.bits(),  append(pmp3cfg.bits(),  append(pmp2cfg.bits(),  append(pmp1cfg.bits(),  pmp0cfg.bits()))))))),
         2 => append(pmp15cfg.bits(), append(pmp14cfg.bits(), append(pmp13cfg.bits(), append(pmp12cfg.bits(), append(pmp11cfg.bits(), append(pmp10cfg.bits(), append(pmp9cfg.bits(),  pmp8cfg.bits()))))))),
         _ => internal_error(__FILE__, __LINE__, "Unexpected pmp config reg read")
       }
}

/* Helpers to handle locked entries */
function pmpLocked(cfg: Pmpcfg_ent) -> bool =
   cfg.L() == 0b1

function pmpTORLocked(cfg: Pmpcfg_ent) -> bool =
   (cfg.L() == 0b1) & (pmpAddrMatchType_of_bits(cfg.A()) == TOR)

function pmpWriteCfg(cfg: Pmpcfg_ent, v: bits(8)) -> Pmpcfg_ent =
  if pmpLocked(cfg) then cfg
  else Mk_Pmpcfg_ent(v & 0x9f)  // Bits 5 and 6 are zero.

val pmpWriteCfgReg : forall 'n, 0 <= 'n < 4 . (atom('n), xlenbits) -> unit
function pmpWriteCfgReg(n, v) = {
  if   sizeof(xlen) == 32
  then match n {
         0 => { pmp0cfg  = pmpWriteCfg(pmp0cfg,  v[7 ..0]);
                pmp1cfg  = pmpWriteCfg(pmp1cfg,  v[15..8]);
                pmp2cfg  = pmpWriteCfg(pmp2cfg,  v[23..16]);
                pmp3cfg  = pmpWriteCfg(pmp3cfg,  v[31..24]);
              },
         1 => { pmp4cfg  = pmpWriteCfg(pmp4cfg,  v[7 ..0]);
                pmp5cfg  = pmpWriteCfg(pmp5cfg,  v[15..8]);
                pmp6cfg  = pmpWriteCfg(pmp6cfg,  v[23..16]);
                pmp7cfg  = pmpWriteCfg(pmp7cfg,  v[31..24]);
              },
         2 => { pmp8cfg  = pmpWriteCfg(pmp8cfg,  v[7 ..0]);
                pmp9cfg  = pmpWriteCfg(pmp9cfg,  v[15..8]);
                pmp10cfg = pmpWriteCfg(pmp10cfg, v[23..16]);
                pmp11cfg = pmpWriteCfg(pmp11cfg, v[31..24]);
              },
         3 => { pmp12cfg = pmpWriteCfg(pmp12cfg, v[7 ..0]);
                pmp13cfg = pmpWriteCfg(pmp13cfg, v[15..8]);
                pmp14cfg = pmpWriteCfg(pmp14cfg, v[23..16]);
                pmp15cfg = pmpWriteCfg(pmp15cfg, v[31..24]);
              },
         _ => internal_error(__FILE__, __LINE__, "Unexpected pmp config reg write")
       }
  else if sizeof(xlen) >= 64
  then match n {
         0 => { pmp0cfg  = pmpWriteCfg(pmp0cfg,  v[7 ..0]);
                pmp1cfg  = pmpWriteCfg(pmp1cfg,  v[15..8]);
                pmp2cfg  = pmpWriteCfg(pmp2cfg,  v[23..16]);
                pmp3cfg  = pmpWriteCfg(pmp3cfg,  v[31..24]);
                pmp4cfg  = pmpWriteCfg(pmp4cfg,  v[39..32]);
                pmp5cfg  = pmpWriteCfg(pmp5cfg,  v[47..40]);
                pmp6cfg  = pmpWriteCfg(pmp6cfg,  v[55..48]);
                pmp7cfg  = pmpWriteCfg(pmp7cfg,  v[63..56])
              },
         2 => { pmp8cfg  = pmpWriteCfg(pmp8cfg,  v[7 ..0]);
                pmp9cfg  = pmpWriteCfg(pmp9cfg,  v[15..8]);
                pmp10cfg = pmpWriteCfg(pmp10cfg, v[23..16]);
                pmp11cfg = pmpWriteCfg(pmp11cfg, v[31..24]);
                pmp12cfg = pmpWriteCfg(pmp12cfg, v[39..32]);
                pmp13cfg = pmpWriteCfg(pmp13cfg, v[47..40]);
                pmp14cfg = pmpWriteCfg(pmp14cfg, v[55..48]);
                pmp15cfg = pmpWriteCfg(pmp15cfg, v[63..56])
              },
         _ => internal_error(__FILE__, __LINE__, "Unexpected pmp config reg write")
       }
}

function pmpWriteAddr(locked: bool, tor_locked: bool, reg: xlenbits, v: xlenbits) -> xlenbits =
  if   sizeof(xlen) == 32
  then { if (locked | tor_locked) then reg else v }
  else { if (locked | tor_locked) then reg else zero_extend(v[53..0]) }
