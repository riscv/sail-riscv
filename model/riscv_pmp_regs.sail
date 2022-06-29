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
register pmp16cfg : Pmpcfg_ent
register pmp17cfg : Pmpcfg_ent
register pmp18cfg : Pmpcfg_ent
register pmp19cfg : Pmpcfg_ent
register pmp20cfg : Pmpcfg_ent
register pmp21cfg : Pmpcfg_ent
register pmp22cfg : Pmpcfg_ent
register pmp23cfg : Pmpcfg_ent
register pmp24cfg : Pmpcfg_ent
register pmp25cfg : Pmpcfg_ent
register pmp26cfg : Pmpcfg_ent
register pmp27cfg : Pmpcfg_ent
register pmp28cfg : Pmpcfg_ent
register pmp29cfg : Pmpcfg_ent
register pmp30cfg : Pmpcfg_ent
register pmp31cfg : Pmpcfg_ent
register pmp32cfg : Pmpcfg_ent
register pmp33cfg : Pmpcfg_ent
register pmp34cfg : Pmpcfg_ent
register pmp35cfg : Pmpcfg_ent
register pmp36cfg : Pmpcfg_ent
register pmp37cfg : Pmpcfg_ent
register pmp38cfg : Pmpcfg_ent
register pmp39cfg : Pmpcfg_ent
register pmp40cfg : Pmpcfg_ent
register pmp41cfg : Pmpcfg_ent
register pmp42cfg : Pmpcfg_ent
register pmp43cfg : Pmpcfg_ent
register pmp44cfg : Pmpcfg_ent
register pmp45cfg : Pmpcfg_ent
register pmp46cfg : Pmpcfg_ent
register pmp47cfg : Pmpcfg_ent
register pmp48cfg : Pmpcfg_ent
register pmp49cfg : Pmpcfg_ent
register pmp50cfg : Pmpcfg_ent
register pmp51cfg : Pmpcfg_ent
register pmp52cfg : Pmpcfg_ent
register pmp53cfg : Pmpcfg_ent
register pmp54cfg : Pmpcfg_ent
register pmp55cfg : Pmpcfg_ent
register pmp56cfg : Pmpcfg_ent
register pmp57cfg : Pmpcfg_ent
register pmp58cfg : Pmpcfg_ent
register pmp59cfg : Pmpcfg_ent
register pmp60cfg : Pmpcfg_ent
register pmp61cfg : Pmpcfg_ent
register pmp62cfg : Pmpcfg_ent
register pmp63cfg : Pmpcfg_ent

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
register pmpaddr16 : xlenbits
register pmpaddr17 : xlenbits
register pmpaddr18 : xlenbits
register pmpaddr19 : xlenbits
register pmpaddr20 : xlenbits
register pmpaddr21 : xlenbits
register pmpaddr22 : xlenbits
register pmpaddr23 : xlenbits
register pmpaddr24 : xlenbits
register pmpaddr25 : xlenbits
register pmpaddr26 : xlenbits
register pmpaddr27 : xlenbits
register pmpaddr28 : xlenbits
register pmpaddr29 : xlenbits
register pmpaddr30 : xlenbits
register pmpaddr31 : xlenbits
register pmpaddr32 : xlenbits
register pmpaddr33 : xlenbits
register pmpaddr34 : xlenbits
register pmpaddr35 : xlenbits
register pmpaddr36 : xlenbits
register pmpaddr37 : xlenbits
register pmpaddr38 : xlenbits
register pmpaddr39 : xlenbits
register pmpaddr40 : xlenbits
register pmpaddr41 : xlenbits
register pmpaddr42 : xlenbits
register pmpaddr43 : xlenbits
register pmpaddr44 : xlenbits
register pmpaddr45 : xlenbits
register pmpaddr46 : xlenbits
register pmpaddr47 : xlenbits
register pmpaddr48 : xlenbits
register pmpaddr49 : xlenbits
register pmpaddr50 : xlenbits
register pmpaddr51 : xlenbits
register pmpaddr52 : xlenbits
register pmpaddr53 : xlenbits
register pmpaddr54 : xlenbits
register pmpaddr55 : xlenbits
register pmpaddr56 : xlenbits
register pmpaddr57 : xlenbits
register pmpaddr58 : xlenbits
register pmpaddr59 : xlenbits
register pmpaddr60 : xlenbits
register pmpaddr61 : xlenbits
register pmpaddr62 : xlenbits
register pmpaddr63 : xlenbits

/* Packing and unpacking pmpcfg regs for xlen-width accesses */

val pmpReadCfgReg : forall 'n, 0 <= 'n < 16 . (atom('n)) -> xlenbits effect {rreg}
function pmpReadCfgReg(n) = {
  if   sizeof(xlen) == 32
  then match n {
         0 => append(pmp3cfg.bits(),  append(pmp2cfg.bits(),  append(pmp1cfg.bits(),  pmp0cfg.bits()))),
         1 => append(pmp7cfg.bits(),  append(pmp6cfg.bits(),  append(pmp5cfg.bits(),  pmp4cfg.bits()))),
         2 => append(pmp11cfg.bits(), append(pmp10cfg.bits(), append(pmp9cfg.bits(),  pmp8cfg.bits()))),
         3 => append(pmp15cfg.bits(), append(pmp14cfg.bits(), append(pmp13cfg.bits(), pmp12cfg.bits()))),
         4 => append(pmp19cfg.bits(), append(pmp18cfg.bits(), append(pmp17cfg.bits(), pmp16cfg.bits()))),
         5 => append(pmp23cfg.bits(), append(pmp22cfg.bits(), append(pmp21cfg.bits(), pmp20cfg.bits()))),
         6 => append(pmp27cfg.bits(), append(pmp26cfg.bits(), append(pmp25cfg.bits(), pmp24cfg.bits()))),
         7 => append(pmp31cfg.bits(), append(pmp30cfg.bits(), append(pmp29cfg.bits(), pmp28cfg.bits()))),
         8 => append(pmp35cfg.bits(), append(pmp34cfg.bits(), append(pmp33cfg.bits(), pmp32cfg.bits()))),
         9 => append(pmp39cfg.bits(), append(pmp38cfg.bits(), append(pmp37cfg.bits(), pmp36cfg.bits()))),
        10 => append(pmp43cfg.bits(), append(pmp42cfg.bits(), append(pmp41cfg.bits(), pmp40cfg.bits()))),
        11 => append(pmp47cfg.bits(), append(pmp46cfg.bits(), append(pmp45cfg.bits(), pmp44cfg.bits()))),
        12 => append(pmp51cfg.bits(), append(pmp50cfg.bits(), append(pmp49cfg.bits(), pmp48cfg.bits()))),
        13 => append(pmp55cfg.bits(), append(pmp54cfg.bits(), append(pmp53cfg.bits(), pmp52cfg.bits()))),
        14 => append(pmp59cfg.bits(), append(pmp58cfg.bits(), append(pmp57cfg.bits(), pmp56cfg.bits()))),
        15 => append(pmp63cfg.bits(), append(pmp62cfg.bits(), append(pmp61cfg.bits(), pmp60cfg.bits())))
       }
  else match n { //  sizeof(xlen) == 64
         0 => append(pmp7cfg.bits(),  append(pmp6cfg.bits(),  append(pmp5cfg.bits(),  append(pmp4cfg.bits(),  append(pmp3cfg.bits(),  append(pmp2cfg.bits(),  append(pmp1cfg.bits(),  pmp0cfg.bits()))))))),
         2 => append(pmp15cfg.bits(), append(pmp14cfg.bits(), append(pmp13cfg.bits(), append(pmp12cfg.bits(), append(pmp11cfg.bits(), append(pmp10cfg.bits(), append(pmp9cfg.bits(),  pmp8cfg.bits()))))))),
         4 => append(pmp23cfg.bits(), append(pmp22cfg.bits(), append(pmp21cfg.bits(), append(pmp20cfg.bits(), append(pmp19cfg.bits(), append(pmp18cfg.bits(), append(pmp17cfg.bits(), pmp16cfg.bits()))))))),
         6 => append(pmp31cfg.bits(), append(pmp30cfg.bits(), append(pmp29cfg.bits(), append(pmp28cfg.bits(), append(pmp27cfg.bits(), append(pmp26cfg.bits(), append(pmp25cfg.bits(), pmp24cfg.bits()))))))),
         8 => append(pmp39cfg.bits(), append(pmp38cfg.bits(), append(pmp37cfg.bits(), append(pmp36cfg.bits(), append(pmp35cfg.bits(), append(pmp34cfg.bits(), append(pmp33cfg.bits(), pmp32cfg.bits()))))))),
        10 => append(pmp47cfg.bits(), append(pmp46cfg.bits(), append(pmp45cfg.bits(), append(pmp44cfg.bits(), append(pmp43cfg.bits(), append(pmp42cfg.bits(), append(pmp41cfg.bits(), pmp40cfg.bits()))))))),
        12 => append(pmp55cfg.bits(), append(pmp54cfg.bits(), append(pmp53cfg.bits(), append(pmp52cfg.bits(), append(pmp51cfg.bits(), append(pmp50cfg.bits(), append(pmp49cfg.bits(), pmp48cfg.bits()))))))),
        14 => append(pmp63cfg.bits(), append(pmp62cfg.bits(), append(pmp61cfg.bits(), append(pmp60cfg.bits(), append(pmp59cfg.bits(), append(pmp58cfg.bits(), append(pmp57cfg.bits(), pmp56cfg.bits())))))))
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

val pmpWriteCfgReg : forall 'n, 0 <= 'n < 16 . (atom('n), xlenbits) -> unit effect {rreg, wreg}
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
         4 => { pmp16cfg = pmpWriteCfg(pmp16cfg, v[7 ..0]);
                pmp17cfg = pmpWriteCfg(pmp17cfg, v[15..8]);
                pmp18cfg = pmpWriteCfg(pmp18cfg, v[23..16]);
                pmp19cfg = pmpWriteCfg(pmp19cfg, v[31..24]);
              },
         5 => { pmp20cfg = pmpWriteCfg(pmp20cfg, v[7 ..0]);
                pmp21cfg = pmpWriteCfg(pmp21cfg, v[15..8]);
                pmp22cfg = pmpWriteCfg(pmp22cfg, v[23..16]);
                pmp23cfg = pmpWriteCfg(pmp23cfg, v[31..24]);
              },
         6 => { pmp24cfg = pmpWriteCfg(pmp24cfg, v[7 ..0]);
                pmp25cfg = pmpWriteCfg(pmp25cfg, v[15..8]);
                pmp26cfg = pmpWriteCfg(pmp26cfg, v[23..16]);
                pmp27cfg = pmpWriteCfg(pmp27cfg, v[31..24]);
              },
         7 => { pmp28cfg = pmpWriteCfg(pmp28cfg, v[7 ..0]);
                pmp29cfg = pmpWriteCfg(pmp29cfg, v[15..8]);
                pmp30cfg = pmpWriteCfg(pmp30cfg, v[23..16]);
                pmp31cfg = pmpWriteCfg(pmp31cfg, v[31..24]);
              },
         8 => { pmp32cfg = pmpWriteCfg(pmp32cfg, v[7 ..0]);
                pmp33cfg = pmpWriteCfg(pmp33cfg, v[15..8]);
                pmp34cfg = pmpWriteCfg(pmp34cfg, v[23..16]);
                pmp35cfg = pmpWriteCfg(pmp35cfg, v[31..24]);
              },
         9 => { pmp36cfg = pmpWriteCfg(pmp36cfg, v[7 ..0]);
                pmp37cfg = pmpWriteCfg(pmp37cfg, v[15..8]);
                pmp38cfg = pmpWriteCfg(pmp38cfg, v[23..16]);
                pmp39cfg = pmpWriteCfg(pmp39cfg, v[31..24]);
              },
        10 => { pmp40cfg = pmpWriteCfg(pmp40cfg, v[7 ..0]);
                pmp41cfg = pmpWriteCfg(pmp41cfg, v[15..8]);
                pmp42cfg = pmpWriteCfg(pmp42cfg, v[23..16]);
                pmp43cfg = pmpWriteCfg(pmp43cfg, v[31..24]);
              },
        11 => { pmp44cfg = pmpWriteCfg(pmp44cfg, v[7 ..0]);
                pmp45cfg = pmpWriteCfg(pmp45cfg, v[15..8]);
                pmp46cfg = pmpWriteCfg(pmp46cfg, v[23..16]);
                pmp47cfg = pmpWriteCfg(pmp47cfg, v[31..24]);
              },
        12 => { pmp48cfg = pmpWriteCfg(pmp48cfg, v[7 ..0]);
                pmp49cfg = pmpWriteCfg(pmp49cfg, v[15..8]);
                pmp50cfg = pmpWriteCfg(pmp50cfg, v[23..16]);
                pmp51cfg = pmpWriteCfg(pmp51cfg, v[31..24]);
              },
        13 => { pmp52cfg = pmpWriteCfg(pmp52cfg, v[7 ..0]);
                pmp53cfg = pmpWriteCfg(pmp53cfg, v[15..8]);
                pmp54cfg = pmpWriteCfg(pmp54cfg, v[23..16]);
                pmp55cfg = pmpWriteCfg(pmp55cfg, v[31..24]);
              },
        14 => { pmp56cfg = pmpWriteCfg(pmp56cfg, v[7 ..0]);
                pmp57cfg = pmpWriteCfg(pmp57cfg, v[15..8]);
                pmp58cfg = pmpWriteCfg(pmp58cfg, v[23..16]);
                pmp59cfg = pmpWriteCfg(pmp59cfg, v[31..24]);
              },
        15 => { pmp60cfg = pmpWriteCfg(pmp60cfg, v[7 ..0]);
                pmp61cfg = pmpWriteCfg(pmp61cfg, v[15..8]);
                pmp62cfg = pmpWriteCfg(pmp62cfg, v[23..16]);
                pmp63cfg = pmpWriteCfg(pmp63cfg, v[31..24]);
              }
       }
  else if sizeof(xlen) == 64
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
         4 => { pmp16cfg = pmpWriteCfg(pmp16cfg, v[7 ..0]);
                pmp17cfg = pmpWriteCfg(pmp17cfg, v[15..8]);
                pmp18cfg = pmpWriteCfg(pmp18cfg, v[23..16]);
                pmp19cfg = pmpWriteCfg(pmp19cfg, v[31..24]);
                pmp20cfg = pmpWriteCfg(pmp20cfg, v[39..32]);
                pmp21cfg = pmpWriteCfg(pmp21cfg, v[47..40]);
                pmp22cfg = pmpWriteCfg(pmp22cfg, v[55..48]);
                pmp23cfg = pmpWriteCfg(pmp23cfg, v[63..56]);
              },
         6 => { pmp24cfg = pmpWriteCfg(pmp24cfg, v[7 ..0]);
                pmp25cfg = pmpWriteCfg(pmp25cfg, v[15..8]);
                pmp26cfg = pmpWriteCfg(pmp26cfg, v[23..16]);
                pmp27cfg = pmpWriteCfg(pmp27cfg, v[31..24]);
                pmp28cfg = pmpWriteCfg(pmp28cfg, v[39..32]);
                pmp29cfg = pmpWriteCfg(pmp29cfg, v[47..40]);
                pmp30cfg = pmpWriteCfg(pmp30cfg, v[55..48]);
                pmp31cfg = pmpWriteCfg(pmp31cfg, v[63..56]);
              },
         8 => { pmp32cfg = pmpWriteCfg(pmp32cfg, v[7 ..0]);
                pmp33cfg = pmpWriteCfg(pmp33cfg, v[15..8]);
                pmp34cfg = pmpWriteCfg(pmp34cfg, v[23..16]);
                pmp35cfg = pmpWriteCfg(pmp35cfg, v[31..24]);
                pmp36cfg = pmpWriteCfg(pmp36cfg, v[39..32]);
                pmp37cfg = pmpWriteCfg(pmp37cfg, v[47..40]);
                pmp38cfg = pmpWriteCfg(pmp38cfg, v[55..48]);
                pmp39cfg = pmpWriteCfg(pmp39cfg, v[63..56]);
              },
        10 => { pmp40cfg = pmpWriteCfg(pmp40cfg, v[7 ..0]);
                pmp41cfg = pmpWriteCfg(pmp41cfg, v[15..8]);
                pmp42cfg = pmpWriteCfg(pmp42cfg, v[23..16]);
                pmp43cfg = pmpWriteCfg(pmp43cfg, v[31..24]);
                pmp44cfg = pmpWriteCfg(pmp44cfg, v[39..32]);
                pmp45cfg = pmpWriteCfg(pmp45cfg, v[47..40]);
                pmp46cfg = pmpWriteCfg(pmp46cfg, v[55..48]);
                pmp47cfg = pmpWriteCfg(pmp47cfg, v[63..56]);
              },
        12 => { pmp48cfg = pmpWriteCfg(pmp48cfg, v[7 ..0]);
                pmp49cfg = pmpWriteCfg(pmp49cfg, v[15..8]);
                pmp50cfg = pmpWriteCfg(pmp50cfg, v[23..16]);
                pmp51cfg = pmpWriteCfg(pmp51cfg, v[31..24]);
                pmp52cfg = pmpWriteCfg(pmp52cfg, v[39..32]);
                pmp53cfg = pmpWriteCfg(pmp53cfg, v[47..40]);
                pmp54cfg = pmpWriteCfg(pmp54cfg, v[55..48]);
                pmp55cfg = pmpWriteCfg(pmp55cfg, v[63..56]);
              },
        14 => { pmp56cfg = pmpWriteCfg(pmp56cfg, v[7 ..0]);
                pmp57cfg = pmpWriteCfg(pmp57cfg, v[15..8]);
                pmp58cfg = pmpWriteCfg(pmp58cfg, v[23..16]);
                pmp59cfg = pmpWriteCfg(pmp59cfg, v[31..24]);
                pmp60cfg = pmpWriteCfg(pmp60cfg, v[39..32]);
                pmp61cfg = pmpWriteCfg(pmp61cfg, v[47..40]);
                pmp62cfg = pmpWriteCfg(pmp62cfg, v[55..48]);
                pmp63cfg = pmpWriteCfg(pmp63cfg, v[63..56]);
              }           
       }
}

function pmpWriteAddr(locked: bool, tor_locked: bool, reg: xlenbits, v: xlenbits) -> xlenbits =
  if   sizeof(xlen) == 32
  then { if (locked | tor_locked) then reg else v }
  else { if (locked | tor_locked) then reg else EXTZ(v[53..0]) }
