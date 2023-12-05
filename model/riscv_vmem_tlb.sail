/*=======================================================================================*/
/*  RISCV Sail Model									 */
/*											 */
/*  This Sail RISC-V architecture model, comprising all files and			 */
/*  directories except for the snapshots of the Lem and Sail libraries			 */
/*  in the prover_snapshots directory (which include copies of their			 */
/*  licences), is subject to the BSD two-clause licence below.				 */
/*											 */
/*  Copyright (c) 2017-2023								 */
/*    Prashanth Mundkur									 */
/*    Rishiyur S. Nikhil and Bluespec, Inc.						 */
/*    Jon French									 */
/*    Brian Campbell									 */
/*    Robert Norton-Wright								 */
/*    Alasdair Armstrong								 */
/*    Thomas Bauereiss									 */
/*    Shaked Flur									 */
/*    Christopher Pulte									 */
/*    Peter Sewell									 */
/*    Alexander Richardson								 */
/*    Hesham Almatary									 */
/*    Jessica Clarke									 */
/*    Microsoft, for contributions by Robert Norton-Wright and Nathaniel Wesley Filardo	 */
/*    Peter Rugg									 */
/*    Aril Computer Corp., for contributions by Scott Johnson				 */
/*    Philipp Tomsich									 */
/*    VRULL GmbH, for contributions by its employees					 */
/*											 */
/*  All rights reserved.								 */
/*											 */
/*  This software was developed by the above within the Rigorous			 */
/*  Engineering of Mainstream Systems (REMS) project, partly funded by			 */
/*  EPSRC grant EP/K008528/1, at the Universities of Cambridge and			 */
/*  Edinburgh.										 */
/*											 */
/*  This software was developed by SRI International and the University of		 */
/*  Cambridge Computer Laboratory (Department of Computer Science and			 */
/*  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and		 */
/*  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA		 */
/*  SSITH research programme.								 */
/*											 */
/*  This project has received funding from the European Research Council		 */
/*  (ERC) under the European Union’s Horizon 2020 research and innovation		 */
/*  programme (grant agreement 789108, ELVER).						 */
/*											 */
/*											 */
/*  Redistribution and use in source and binary forms, with or without			 */
/*  modification, are permitted provided that the following conditions			 */
/*  are met:										 */
/*  1. Redistributions of source code must retain the above copyright			 */
/*     notice, this list of conditions and the following disclaimer.			 */
/*  2. Redistributions in binary form must reproduce the above copyright		 */
/*     notice, this list of conditions and the following disclaimer in			 */
/*     the documentation and/or other materials provided with the			 */
/*     distribution.									 */
/*											 */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''			 */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED			 */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A			 */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.	IN NO EVENT SHALL THE AUTHOR OR			 */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,			 */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT			 */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF			 */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND			 */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,			 */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT			 */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF			 */
/*  SUCH DAMAGE.									 */
/*=======================================================================================*/

// Although a TLB is not part of the RISC-V Architecture
// specification, we model a simple TLB so that
// (1) we can meaningfully test SFENCE.VMA which would be a no-op wihout a TLB;
// (2) we can greatly speed up simulation speed (for Linux boot, can
//     reduce elapsed time from 10s of minutes to few minutes.

// PRIVATE
struct TLB_Entry = {
  asid       : bits(16),  // address-space id
  global     : bool,      // global translation
  vAddr      : bits(64),  // VPN
  pAddr      : bits(64),  // ppn
  vMatchMask : bits(64),  // matching mask for superpages
  vAddrMask  : bits(64),  // selection mask for superpages
  pte        : bits(64),  // PTE
  pteAddr    : bits(64),  // for dirty writeback
  age        : bits(64)   // for replacement policy?
}

// Single-entry TLB (could enlarge this in future for better simulation speed)
// PRIVATE
register tlb : option(TLB_Entry) = None()

// PUBLIC: invoked in init_vmem() [riscv_vmem.sail]
function init_TLB() -> unit =
  tlb = None()

// PUBLIC: invoked in translate_TLB_hit() [riscv_vmem.sail]
function write_TLB(idx : nat, ent : TLB_Entry) -> unit =
  tlb = Some(ent)

// PRIVATE
function match_TLB_Entry(ent   : TLB_Entry,
                         asid  : bits(16),
                         vaddr : bits(64)) -> bool =
  (ent.global | (ent.asid == asid))
  & (ent.vAddr == (ent.vMatchMask & vaddr))

// PRIVATE
function flush_TLB_Entry(e    : TLB_Entry,
                         asid : option(bits(16)),
                         addr : option(bits(64))) -> bool = {
  match (asid, addr) {
    ( None(),  None()) => true,
    ( None(), Some(a)) => e.vAddr == (e.vMatchMask & a),
    (Some(i),  None()) => (e.asid == i) & not(e.global),
    (Some(i), Some(a)) => (  (e.asid == i) & (e.vAddr == (a & e.vMatchMask))
                           & not(e.global))
  }
}

// PUBLIC: invoked in translate() [riscv_vmem.sail]
function lookup_TLB (asid : bits(16), vaddr : bits(64)) -> option((nat, TLB_Entry)) =
  match tlb {
    None()  => None(),
    Some(e) => if match_TLB_Entry(e, asid, vaddr) then Some((0, e)) else None()
  }

// PRIVATE
function add_to_TLB(asid          : bits(16),
                    vAddr         : bits(64),
                    pAddr         : bits(64),
                    pte           : bits(64),
                    pteAddr       : bits(64),
                    level         : nat,
                    global        : bool,
                    levelBitSize  : nat,
                    PAGESIZE_BITS : nat)     -> unit = {
  let shift      : nat       = PAGESIZE_BITS + (level * levelBitSize);
  let one_64b    : bits(64)  = zero_extend(0b1);
  let vAddrMask  : bits(64)  = (one_64b << shift) - one_64b;
  let vMatchMask : bits(64)  = ~ (vAddrMask);
  let entry      : TLB_Entry = struct {asid       = asid,
                                       global     = global,
                                       pte        = pte,
                                       pteAddr    = pteAddr,
                                       vAddrMask  = vAddrMask,
                                       vMatchMask = vMatchMask,
                                       vAddr      = vAddr & vMatchMask,
                                       pAddr      = shiftl(shiftr(pAddr, shift), shift),
                                       age        = mcycle};
  tlb = Some(entry)
}

// Top-level TLB flush function
// PUBLIC: invoked from exec SFENCE_VMA
function flush_TLB(asid_xlen : option(xlenbits),
                   addr_xlen : option(xlenbits)) -> unit = {
  let asid : option(bits(16)) =
    match asid_xlen {
      None()  => None(),
      Some(a) => Some(a[15 .. 0])
    };
  let addr_64b : option(bits(64)) =
    match addr_xlen {
      None() => None(),
      Some(a) => Some(zero_extend(a))
    };
  match tlb {
    None()  => (),
    Some(e) => if   flush_TLB_Entry(e, asid, addr_64b)
               then tlb = None()
               else ()
  }
}
