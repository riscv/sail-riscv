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

/* idealized generic TLB entry to model fence.vm and also speed up simulation. */

struct TLB_Entry('asidlen: Int, 'valen: Int, 'palen: Int, 'ptelen: Int) = {
  asid : bits('asidlen),
  global : bool,
  vAddr : bits('valen),      /* VPN */
  pAddr : bits('palen),      /* PPN */
  vMatchMask : bits('valen), /* matching mask for superpages */
  vAddrMask  : bits('valen), /* selection mask for superpages */
  pte : bits('ptelen),       /* PTE */
  pteAddr : bits('palen),    /* for dirty writeback */
  age : bits(64)
}


val make_TLB_Entry : forall 'asidlen 'valen 'palen 'ptelen, 'valen > 0.
  (bits('asidlen), bool, bits('valen), bits('palen), bits('ptelen), nat, bits('palen), nat)
  -> TLB_Entry('asidlen, 'valen, 'palen, 'ptelen)
function make_TLB_Entry(asid, global, vAddr, pAddr, pte, level, pteAddr, levelBitSize) = {
  let shift : nat = PAGESIZE_BITS + (level * levelBitSize);
  /* fixme hack: use a better idiom for masks */
  let vAddrMask  : bits('valen) = shiftl(vAddr ^ vAddr ^ zero_extend(0b1), shift) - 1;
  let vMatchMask : bits('valen) = ~ (vAddrMask);
  struct {
    asid = asid,
    global = global,
    pte = pte,
    pteAddr = pteAddr,
    vAddrMask = vAddrMask,
    vMatchMask = vMatchMask,
    vAddr = vAddr & vMatchMask,
    pAddr = shiftl(shiftr(pAddr, shift), shift),
    age = mcycle
  }
}

val match_TLB_Entry : forall 'asidlen 'valen 'palen 'ptelen.
  (TLB_Entry('asidlen, 'valen, 'palen, 'ptelen), bits('asidlen), bits('valen))
  -> bool
function match_TLB_Entry(ent, asid, vaddr) =
  (ent.global | (ent.asid == asid)) & (ent.vAddr == (ent.vMatchMask & vaddr))

val flush_TLB_Entry : forall 'asidlen 'valen 'palen 'ptelen.
  (TLB_Entry('asidlen, 'valen, 'palen, 'ptelen), option(bits('asidlen)), option(bits('valen)))
  -> bool
function flush_TLB_Entry(e, asid, addr) = {
  match(asid, addr) {
    ( None(),  None()) => true,
    ( None(), Some(a)) => e.vAddr == (e.vMatchMask & a),
    (Some(i),  None()) => (e.asid == i) & not(e.global),
    (Some(i), Some(a)) => (  (e.asid == i) & (e.vAddr == (a & e.vMatchMask))
                           & not(e.global))
  }
}
