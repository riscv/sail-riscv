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

/* address ranges */

// TODO: handle PMP grain > 4 (i.e. G > 0).
// TODO: handle the 34-bit paddr32 on RV32

/* [min, max) of the matching range. */
type pmp_addr_range = option((xlenbits, xlenbits))

function pmpAddrRange(cfg: Pmpcfg_ent, pmpaddr: xlenbits, prev_pmpaddr: xlenbits) -> pmp_addr_range = {
  match pmpAddrMatchType_of_bits(cfg.A()) {
    OFF   => None(),
    TOR   => { Some ((prev_pmpaddr << 2, pmpaddr << 2)) },
    NA4   => { // TODO: I find the spec unclear for entries marked NA4 and G = 1.
               // (for G >= 2, it is the same as NAPOT). In particular, it affects
               // whether pmpaddr[0] is always read as 0.
               let lo = pmpaddr << 2;
               Some((lo, lo + 4))
             },
    NAPOT => { let mask = pmpaddr ^ (pmpaddr + 1);  // generate 1s in signifying bits
               let lo   = pmpaddr & (~ (mask));
               let len  = mask + 1;
               Some((lo << 2, (lo + len) << 2))
             }
  }
}

/* permission checks */

val pmpCheckRWX: (Pmpcfg_ent, AccessType(ext_access_type)) -> bool
function pmpCheckRWX(ent, acc) = {
  match acc {
    Read(_)      => ent.R() == 0b1,
    Write(_)     => ent.W() == 0b1,
    ReadWrite(_) => ent.R() == 0b1 & ent.W() == 0b1,
    Execute()    => ent.X() == 0b1
  }
}

// this needs to be called with the effective current privilege.
val pmpCheckPerms: (Pmpcfg_ent, AccessType(ext_access_type), Privilege) -> bool
function pmpCheckPerms(ent, acc, priv) = {
  match priv {
    Machine => if   pmpLocked(ent)
               then pmpCheckRWX(ent, acc)
               else true,
    _       => pmpCheckRWX(ent, acc)
  }
}

/* matching logic */

enum pmpAddrMatch = {PMP_NoMatch, PMP_PartialMatch, PMP_Match}

function pmpMatchAddr(addr: xlenbits, width: xlenbits, rng: pmp_addr_range) -> pmpAddrMatch = {
  match rng {
    None()         => PMP_NoMatch,
    Some((lo, hi)) => if   hi <_u lo   /* to handle mis-configuration */
                      then PMP_NoMatch
                      else {
                        if      (addr + width <=_u lo) | (hi <=_u addr)
                        then    PMP_NoMatch
                        else if (lo <=_u addr) & (addr + width <=_u hi)
                        then    PMP_Match
                        else    PMP_PartialMatch
                      }
  }
}

enum pmpMatch = {PMP_Success, PMP_Continue, PMP_Fail}

function pmpMatchEntry(addr: xlenbits, width: xlenbits, acc: AccessType(ext_access_type), priv: Privilege,
                       ent: Pmpcfg_ent, pmpaddr: xlenbits, prev_pmpaddr: xlenbits) -> pmpMatch = {
  let rng = pmpAddrRange(ent, pmpaddr, prev_pmpaddr);
  match pmpMatchAddr(addr, width, rng) {
    PMP_NoMatch      => PMP_Continue,
    PMP_PartialMatch => PMP_Fail,
    PMP_Match        => if   pmpCheckPerms(ent, acc, priv)
                        then PMP_Success
                        else PMP_Fail
  }
}

/* priority checks */

function pmpCheck forall 'n, 'n > 0. (addr: xlenbits, width: atom('n), acc: AccessType(ext_access_type), priv: Privilege)
                  -> option(ExceptionType) = {
  let width : xlenbits = to_bits(sizeof(xlen), width);
  let check : bool =
  match pmpMatchEntry(addr, width, acc, priv, pmp0cfg, pmpaddr0, zeros()) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp1cfg, pmpaddr1, pmpaddr0) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp2cfg, pmpaddr2, pmpaddr1) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp3cfg, pmpaddr3, pmpaddr2) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp4cfg, pmpaddr4, pmpaddr3) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp5cfg, pmpaddr5, pmpaddr4) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp6cfg, pmpaddr6, pmpaddr5) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp7cfg, pmpaddr7, pmpaddr6) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp8cfg, pmpaddr8, pmpaddr7) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp9cfg, pmpaddr9, pmpaddr8) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp10cfg, pmpaddr10, pmpaddr9) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp11cfg, pmpaddr11, pmpaddr10) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp12cfg, pmpaddr12, pmpaddr11) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp13cfg, pmpaddr13, pmpaddr12) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp14cfg, pmpaddr14, pmpaddr13) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp15cfg, pmpaddr15, pmpaddr14) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp16cfg, pmpaddr16, pmpaddr15) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp17cfg, pmpaddr17, pmpaddr16) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp18cfg, pmpaddr18, pmpaddr17) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp19cfg, pmpaddr19, pmpaddr18) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp20cfg, pmpaddr20, pmpaddr19) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp21cfg, pmpaddr21, pmpaddr20) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp22cfg, pmpaddr22, pmpaddr21) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp23cfg, pmpaddr23, pmpaddr22) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp24cfg, pmpaddr24, pmpaddr23) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp25cfg, pmpaddr25, pmpaddr24) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp26cfg, pmpaddr26, pmpaddr25) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp27cfg, pmpaddr27, pmpaddr26) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp28cfg, pmpaddr28, pmpaddr27) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp29cfg, pmpaddr29, pmpaddr28) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp30cfg, pmpaddr30, pmpaddr29) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp31cfg, pmpaddr31, pmpaddr30) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp32cfg, pmpaddr32, pmpaddr31) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp33cfg, pmpaddr33, pmpaddr32) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp34cfg, pmpaddr34, pmpaddr33) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp35cfg, pmpaddr35, pmpaddr34) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp36cfg, pmpaddr36, pmpaddr35) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp37cfg, pmpaddr37, pmpaddr36) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp38cfg, pmpaddr38, pmpaddr37) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp39cfg, pmpaddr39, pmpaddr38) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp40cfg, pmpaddr40, pmpaddr39) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp41cfg, pmpaddr41, pmpaddr40) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp42cfg, pmpaddr42, pmpaddr41) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp43cfg, pmpaddr43, pmpaddr42) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp44cfg, pmpaddr44, pmpaddr43) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp45cfg, pmpaddr45, pmpaddr44) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp46cfg, pmpaddr46, pmpaddr45) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp47cfg, pmpaddr47, pmpaddr46) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp48cfg, pmpaddr48, pmpaddr47) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp49cfg, pmpaddr49, pmpaddr48) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp50cfg, pmpaddr50, pmpaddr49) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp51cfg, pmpaddr51, pmpaddr50) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp52cfg, pmpaddr52, pmpaddr51) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp53cfg, pmpaddr53, pmpaddr52) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp54cfg, pmpaddr54, pmpaddr53) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp55cfg, pmpaddr55, pmpaddr54) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp56cfg, pmpaddr56, pmpaddr55) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp57cfg, pmpaddr57, pmpaddr56) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp58cfg, pmpaddr58, pmpaddr57) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp59cfg, pmpaddr59, pmpaddr58) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp60cfg, pmpaddr60, pmpaddr59) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp61cfg, pmpaddr61, pmpaddr60) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp62cfg, pmpaddr62, pmpaddr61) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp63cfg, pmpaddr63, pmpaddr62) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue => match priv {
                      Machine => true,
                      _       => false
                    }
  }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}};

  if   check
  then None()
  else match acc {
    Read(_)      => Some(E_Load_Access_Fault()),
    Write(_)     => Some(E_SAMO_Access_Fault()),
    ReadWrite(_) => Some(E_SAMO_Access_Fault()),
    Execute()    => Some(E_Fetch_Access_Fault())
  }
}

function init_pmp() -> unit = {
  pmp0cfg  = update_A(pmp0cfg,  pmpAddrMatchType_to_bits(OFF));
  pmp1cfg  = update_A(pmp1cfg,  pmpAddrMatchType_to_bits(OFF));
  pmp2cfg  = update_A(pmp2cfg,  pmpAddrMatchType_to_bits(OFF));
  pmp3cfg  = update_A(pmp3cfg,  pmpAddrMatchType_to_bits(OFF));
  pmp4cfg  = update_A(pmp4cfg,  pmpAddrMatchType_to_bits(OFF));
  pmp5cfg  = update_A(pmp5cfg,  pmpAddrMatchType_to_bits(OFF));
  pmp6cfg  = update_A(pmp6cfg,  pmpAddrMatchType_to_bits(OFF));
  pmp7cfg  = update_A(pmp7cfg,  pmpAddrMatchType_to_bits(OFF));
  pmp8cfg  = update_A(pmp8cfg,  pmpAddrMatchType_to_bits(OFF));
  pmp9cfg  = update_A(pmp9cfg,  pmpAddrMatchType_to_bits(OFF));
  pmp10cfg = update_A(pmp10cfg, pmpAddrMatchType_to_bits(OFF));
  pmp11cfg = update_A(pmp11cfg, pmpAddrMatchType_to_bits(OFF));
  pmp12cfg = update_A(pmp12cfg, pmpAddrMatchType_to_bits(OFF));
  pmp13cfg = update_A(pmp13cfg, pmpAddrMatchType_to_bits(OFF));
  pmp14cfg = update_A(pmp14cfg, pmpAddrMatchType_to_bits(OFF));
  pmp15cfg = update_A(pmp15cfg, pmpAddrMatchType_to_bits(OFF));
  pmp16cfg = update_A(pmp16cfg, pmpAddrMatchType_to_bits(OFF));
  pmp17cfg = update_A(pmp17cfg, pmpAddrMatchType_to_bits(OFF));
  pmp18cfg = update_A(pmp18cfg, pmpAddrMatchType_to_bits(OFF));
  pmp19cfg = update_A(pmp19cfg, pmpAddrMatchType_to_bits(OFF));
  pmp20cfg = update_A(pmp20cfg, pmpAddrMatchType_to_bits(OFF));
  pmp21cfg = update_A(pmp21cfg, pmpAddrMatchType_to_bits(OFF));
  pmp22cfg = update_A(pmp22cfg, pmpAddrMatchType_to_bits(OFF));
  pmp23cfg = update_A(pmp23cfg, pmpAddrMatchType_to_bits(OFF));
  pmp24cfg = update_A(pmp24cfg, pmpAddrMatchType_to_bits(OFF));
  pmp25cfg = update_A(pmp25cfg, pmpAddrMatchType_to_bits(OFF));
  pmp26cfg = update_A(pmp26cfg, pmpAddrMatchType_to_bits(OFF));
  pmp27cfg = update_A(pmp27cfg, pmpAddrMatchType_to_bits(OFF));
  pmp28cfg = update_A(pmp28cfg, pmpAddrMatchType_to_bits(OFF));
  pmp29cfg = update_A(pmp29cfg, pmpAddrMatchType_to_bits(OFF));
  pmp30cfg = update_A(pmp30cfg, pmpAddrMatchType_to_bits(OFF));
  pmp31cfg = update_A(pmp31cfg, pmpAddrMatchType_to_bits(OFF));
  pmp32cfg = update_A(pmp32cfg, pmpAddrMatchType_to_bits(OFF));
  pmp33cfg = update_A(pmp33cfg, pmpAddrMatchType_to_bits(OFF));
  pmp34cfg = update_A(pmp34cfg, pmpAddrMatchType_to_bits(OFF));
  pmp35cfg = update_A(pmp35cfg, pmpAddrMatchType_to_bits(OFF));
  pmp36cfg = update_A(pmp36cfg, pmpAddrMatchType_to_bits(OFF));
  pmp37cfg = update_A(pmp37cfg, pmpAddrMatchType_to_bits(OFF));
  pmp38cfg = update_A(pmp38cfg, pmpAddrMatchType_to_bits(OFF));
  pmp39cfg = update_A(pmp39cfg, pmpAddrMatchType_to_bits(OFF));
  pmp40cfg = update_A(pmp40cfg, pmpAddrMatchType_to_bits(OFF));
  pmp41cfg = update_A(pmp41cfg, pmpAddrMatchType_to_bits(OFF));
  pmp42cfg = update_A(pmp42cfg, pmpAddrMatchType_to_bits(OFF));
  pmp43cfg = update_A(pmp43cfg, pmpAddrMatchType_to_bits(OFF));
  pmp44cfg = update_A(pmp44cfg, pmpAddrMatchType_to_bits(OFF));
  pmp45cfg = update_A(pmp45cfg, pmpAddrMatchType_to_bits(OFF));
  pmp46cfg = update_A(pmp46cfg, pmpAddrMatchType_to_bits(OFF));
  pmp47cfg = update_A(pmp47cfg, pmpAddrMatchType_to_bits(OFF));
  pmp48cfg = update_A(pmp48cfg, pmpAddrMatchType_to_bits(OFF));
  pmp49cfg = update_A(pmp49cfg, pmpAddrMatchType_to_bits(OFF));
  pmp50cfg = update_A(pmp50cfg, pmpAddrMatchType_to_bits(OFF));
  pmp51cfg = update_A(pmp51cfg, pmpAddrMatchType_to_bits(OFF));
  pmp52cfg = update_A(pmp52cfg, pmpAddrMatchType_to_bits(OFF));
  pmp53cfg = update_A(pmp53cfg, pmpAddrMatchType_to_bits(OFF));
  pmp54cfg = update_A(pmp54cfg, pmpAddrMatchType_to_bits(OFF));
  pmp55cfg = update_A(pmp55cfg, pmpAddrMatchType_to_bits(OFF));
  pmp56cfg = update_A(pmp56cfg, pmpAddrMatchType_to_bits(OFF));
  pmp57cfg = update_A(pmp57cfg, pmpAddrMatchType_to_bits(OFF));
  pmp58cfg = update_A(pmp58cfg, pmpAddrMatchType_to_bits(OFF));
  pmp59cfg = update_A(pmp59cfg, pmpAddrMatchType_to_bits(OFF));
  pmp60cfg = update_A(pmp60cfg, pmpAddrMatchType_to_bits(OFF));
  pmp61cfg = update_A(pmp61cfg, pmpAddrMatchType_to_bits(OFF));
  pmp62cfg = update_A(pmp62cfg, pmpAddrMatchType_to_bits(OFF));
  pmp63cfg = update_A(pmp63cfg, pmpAddrMatchType_to_bits(OFF))
}
