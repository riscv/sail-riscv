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

/* Architectural state for the 'N' user-level interrupts standard extension. */
/* ustatus reveals a subset of mstatus */
bitfield Ustatus : xlenbits = {
  UPIE : 4,
  UIE  : 0
}

/* This is a view, so there is no register defined. */
function lower_sstatus s : Sstatus -> Ustatus = {
  let u = Mk_Ustatus(EXTZ(0b0));
  let u = update_UPIE(u, _mod_UPIE(s));
  let u = update_UIE(u, _mod_UIE(s));
  u
}

function lift_ustatus(s : Sstatus, u : Ustatus) -> Sstatus = {
  let s = update_UPIE(s, _mod_UPIE(u));
  let s = update_UIE(s, _mod_UIE(u));
  s
}

function legalize_ustatus(m : Mstatus, v : xlenbits) -> Mstatus = {
  let u = Mk_Ustatus(v);
  let s = lower_mstatus(m); // lower current mstatus to sstatus
  let s = lift_ustatus(s, u); // get updated sstatus
  let m = lift_sstatus(m, s); // lift it to an updated mstatus
  m
}

bitfield Uinterrupts : xlenbits = {
  UEI : 8,  /* external interrupt */
  UTI : 4,  /* timer interrupt    */
  USI : 0   /* software interrupt */
}

/* Provides the uip read view of sip (s) as delegated by sideleg (d). */
function lower_sip(s : Sinterrupts, d : Sinterrupts) -> Uinterrupts = {
  let u : Uinterrupts = Mk_Uinterrupts(EXTZ(0b0));
  let u = update_UEI(u, _mod_UEI(s) & _mod_UEI(d));
  let u = update_UTI(u, _mod_UTI(s) & _mod_UTI(d));
  let u = update_USI(u, _mod_USI(s) & _mod_USI(d));
  u
}

/* Provides the uie read view of sie as delegated by sideleg. */
function lower_sie(s : Sinterrupts, d : Sinterrupts) -> Uinterrupts = {
  let u : Uinterrupts = Mk_Uinterrupts(EXTZ(0b0));
  let u = update_UEI(u, _mod_UEI(s) & _mod_UEI(d));
  let u = update_UTI(u, _mod_UTI(s) & _mod_UTI(d));
  let u = update_USI(u, _mod_USI(s) & _mod_USI(d));
  u
}

/* Returns the new value of sip from the previous sip (o) and the written uip (u) as delegated by sideleg (d). */
function lift_uip(o : Sinterrupts, d : Sinterrupts, u : Uinterrupts) -> Sinterrupts = {
  let s : Sinterrupts = o;
  let s = if _mod_USI(d) == 0b1 then {
    update_USI(s, _mod_USI(u))
  } else {
    s
  };
  s
}

function legalize_uip(s : Sinterrupts, d : Sinterrupts, v : xlenbits) -> Sinterrupts = {
  lift_uip(s, d, Mk_Uinterrupts(v))
}

/* Returns the new value of sie from the previous sie (o) and the written uie (u) as delegated by sideleg (d). */
function lift_uie(o : Sinterrupts, d : Sinterrupts, u : Uinterrupts) -> Sinterrupts = {
  let s : Sinterrupts = o;
  let s = if _mod_UEI(d) == 0b1 then {
    update_UEI(s, _mod_UEI(u))
  } else {
    s
  };
  let s = if _mod_UTI(d) == 0b1 then {
    update_UTI(s, _mod_UTI(u))
  } else {
    s
  };
  let s = if _mod_USI(d) == 0b1 then {
    update_USI(s, _mod_USI(u))
  } else {
    s
  };
  s
}

function legalize_uie(s : Sinterrupts, d : Sinterrupts, v : xlenbits) -> Sinterrupts = {
  lift_uie(s, d, Mk_Uinterrupts(v))
}

register utvec : Mtvec
register uscratch : xlenbits
register uepc : xlenbits
register ucause : Mcause
register utval : xlenbits
