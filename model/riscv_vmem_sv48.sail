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

/* Sv48 address translation for RV64. */

val walk48 : (vaddr48, AccessType(ext_access_type), Privilege, bool, bool, paddr64, nat, bool, ext_ptw) -> PTW_Result(paddr64, SV48_PTE)
function walk48(vaddr, ac, priv, mxr, do_sum, ptb, level, global, ext_ptw) = {
  let va = Mk_SV48_Vaddr(vaddr);
  let pt_ofs : paddr64 = shiftl(zero_extend(shiftr(va.VPNi(), (level * SV48_LEVEL_BITS))[(SV48_LEVEL_BITS - 1) .. 0]),
                                PTE48_LOG_SIZE);
  let pte_addr = ptb + pt_ofs;
  match (mem_read_priv(Read(Data), Supervisor, zero_extend(pte_addr), 8, false, false, false)) {
    MemException(_) => {
/*    print("walk48(vaddr=" ^ BitStr(vaddr) ^ " level=" ^ string_of_int(level)
            ^ " pt_base=" ^ BitStr(ptb)
            ^ " pt_ofs=" ^ BitStr(pt_ofs)
            ^ " pte_addr=" ^ BitStr(pte_addr)
            ^ ": invalid pte address"); */
      PTW_Failure(PTW_Access(), ext_ptw)
    },
    MemValue(v) => {
      let pte = Mk_SV48_PTE(v);
      let pbits = pte.BITS();
      let ext_pte = pte.Ext();
      let pattr = Mk_PTE_Bits(pbits);
      let is_global = global | (pattr.G() == 0b1);
/*    print("walk48(vaddr=" ^ BitStr(vaddr) ^ " level=" ^ string_of_int(level)
            ^ " pt_base=" ^ BitStr(ptb)
            ^ " pt_ofs=" ^ BitStr(pt_ofs)
            ^ " pte_addr=" ^ BitStr(pte_addr)
            ^ " pte=" ^ BitStr(v)); */
      if isInvalidPTE(pbits, ext_pte) then {
/*      print("walk48: invalid pte"); */
        PTW_Failure(PTW_Invalid_PTE(), ext_ptw)
      } else {
        if isPTEPtr(pbits, ext_pte) then {
          if level > 0 then {
            /* walk down the pointer to the next level */
            walk48(vaddr, ac, priv, mxr, do_sum, shiftl(zero_extend(pte.PPNi()), PAGESIZE_BITS), level - 1, is_global, ext_ptw)
          } else {
            /* last-level PTE contains a pointer instead of a leaf */
/*          print("walk48: last-level pte contains a ptr"); */
            PTW_Failure(PTW_Invalid_PTE(), ext_ptw)
          }
        } else { /* leaf PTE */
          match checkPTEPermission(ac, priv, mxr, do_sum, pattr, ext_pte, ext_ptw) {
            PTE_Check_Failure(ext_ptw, ext_ptw_fail) => {
/*            print("walk48: pte permission check failure"); */
              PTW_Failure(ext_get_ptw_error(ext_ptw_fail), ext_ptw)
            },
            PTE_Check_Success(ext_ptw) => {
              if level > 0 then { /* superpage */
                /* fixme hack: to get a mask of appropriate size */
                let mask = shiftl(pte.PPNi() ^ pte.PPNi() ^ zero_extend(0b1), level * SV48_LEVEL_BITS) - 1;
                if (pte.PPNi() & mask) != zero_extend(0b0) then {
                  /* misaligned superpage mapping */
/*                print("walk48: misaligned superpage mapping"); */
                  PTW_Failure(PTW_Misaligned(), ext_ptw)
                } else {
                  /* add the appropriate bits of the VPN to the superpage PPN */
                  let ppn = pte.PPNi() | (zero_extend(va.VPNi()) & mask);
/*                let res = append(ppn, va.PgOfs());
                  print("walk48: using superpage: pte.ppn=" ^ BitStr(pte.PPNi())
                        ^ " ppn=" ^ BitStr(ppn) ^ " res=" ^ BitStr(res)); */
                  PTW_Success(append(ppn, va.PgOfs()), pte, pte_addr, level, is_global, ext_ptw)
                }
              } else {
                /* normal leaf PTE */
/*              let res = append(pte.PPNi(), va.PgOfs());
                print("walk48: pte.ppn=" ^ BitStr(pte.PPNi()) ^ " ppn=" ^ BitStr(pte.PPNi()) ^ " res=" ^ BitStr(res)); */
                PTW_Success(append(pte.PPNi(), va.PgOfs()), pte, pte_addr, level, is_global, ext_ptw)
              }
            }
          }
        }
      }
    }
  }
}

/* TLB management: single entry for now */

// ideally we would use the below form:
// type TLB48_Entry = TLB_Entry(sizeof(asid64), sizeof(vaddr48), sizeof(paddr64), sizeof(pte64))
type TLB48_Entry = TLB_Entry(16, 48, 56, 64)
register tlb48 : option(TLB48_Entry)

val lookup_TLB48 : (asid64, vaddr48) -> option((nat, TLB48_Entry))
function lookup_TLB48(asid, vaddr) =
  match tlb48 {
    None()  => None(),
    Some(e) => if match_TLB_Entry(e, asid, vaddr) then Some((0, e)) else None()
  }

val add_to_TLB48 : (asid64, vaddr48, paddr64, SV48_PTE, paddr64, nat, bool) -> unit
function add_to_TLB48(asid, vAddr, pAddr, pte, pteAddr, level, global) = {
  let ent : TLB48_Entry = make_TLB_Entry(asid, global, vAddr, pAddr, pte.bits(), level, pteAddr, SV48_LEVEL_BITS);
  tlb48 = Some(ent)
}

function write_TLB48(idx : nat, ent : TLB48_Entry) -> unit =
  tlb48 = Some(ent)

val flush_TLB48 : (option(asid64), option(vaddr48)) -> unit
function flush_TLB48(asid, addr) =
  match (tlb48) {
    None()  => (),
    Some(e) => if   flush_TLB_Entry(e, asid, addr)
               then tlb48 = None()
               else ()
  }

/* address translation */

val translate48 : (asid64, paddr64, vaddr48, AccessType(ext_access_type), Privilege, bool, bool, nat, ext_ptw) -> TR_Result(paddr64, PTW_Error)
function translate48(asid, ptb, vAddr, ac, priv, mxr, do_sum, level, ext_ptw) = {
  match walk48(vAddr, ac, priv, mxr, do_sum, ptb, level, false, ext_ptw) {
    PTW_Failure(f, ext_ptw) => TR_Failure(f, ext_ptw),
    PTW_Success(pAddr, pte, pteAddr, level, global, ext_ptw) => {
      match update_PTE_Bits(Mk_PTE_Bits(pte.BITS()), ac, pte.Ext()) {
        None() => {
          add_to_TLB48(asid, vAddr, pAddr, pte, pteAddr, level, global);
          TR_Address(pAddr, ext_ptw)
        },
        Some(pbits, ext) =>
          if not(plat_enable_dirty_update())
          then {
            /* pte needs dirty/accessed update but that is not enabled */
            TR_Failure(PTW_PTE_Update(), ext_ptw)
          } else {
            var w_pte : SV48_PTE = update_BITS(pte, pbits.bits());
            w_pte = update_Ext(w_pte, ext);
            match mem_write_value_priv(zero_extend(pteAddr), 8, w_pte.bits(), Supervisor, false, false, false) {
              MemValue(_) => {
                add_to_TLB48(asid, vAddr, pAddr, w_pte, pteAddr, level, global);
                TR_Address(pAddr, ext_ptw)
              },
              MemException(e) => {
                /* pte is not in valid memory */
                TR_Failure(PTW_Access(), ext_ptw)
              }
            }
          }
      }
    }
  }
}

function init_vmem_sv48() -> unit = {
  tlb48 = None()
}
