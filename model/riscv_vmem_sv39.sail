/* Sv39 address translation for RV64. */

val walk39 : (vaddr39, AccessType, Privilege, bool, bool, paddr64, nat, bool) -> PTW_Result(paddr64, SV39_PTE) effect {rmem, escape}
function walk39(vaddr, ac, priv, mxr, do_sum, ptb, level, global) = {
  let va = Mk_SV39_Vaddr(vaddr);
  let pt_ofs : paddr64 = shiftl(EXTZ(shiftr(va.VPNi(), (level * SV39_LEVEL_BITS))[(SV39_LEVEL_BITS - 1) .. 0]),
                                PTE39_LOG_SIZE);
  let pte_addr = ptb + pt_ofs;
  /* FIXME: we assume here that walks only access physical-memory-backed addresses, and not MMIO regions. */
  match (phys_mem_read(Data, EXTZ(pte_addr), 8, false, false, false)) {
    MemException(_) => {
/*    print("walk39(vaddr=" ^ BitStr(vaddr) ^ " level=" ^ string_of_int(level)
            ^ " pt_base=" ^ BitStr(ptb)
            ^ " pt_ofs=" ^ BitStr(pt_ofs)
            ^ " pte_addr=" ^ BitStr(pte_addr)
            ^ ": invalid pte address"); */
      PTW_Failure(PTW_Access)
    },
    MemValue(v) => {
      let pte = Mk_SV39_PTE(v);
      let pbits = pte.BITS();
      let pattr = Mk_PTE_Bits(pbits);
      let is_global = global | (pattr.G() == true);
/*    print("walk39(vaddr=" ^ BitStr(vaddr) ^ " level=" ^ string_of_int(level)
            ^ " pt_base=" ^ BitStr(ptb)
            ^ " pt_ofs=" ^ BitStr(pt_ofs)
            ^ " pte_addr=" ^ BitStr(pte_addr)
            ^ " pte=" ^ BitStr(v)); */
      if isInvalidPTE(pbits) then {
/*      print("walk39: invalid pte"); */
        PTW_Failure(PTW_Invalid_PTE)
      } else {
        if isPTEPtr(pbits) then {
          if level == 0 then {
            /* last-level PTE contains a pointer instead of a leaf */
/*          print("walk39: last-level pte contains a ptr"); */
            PTW_Failure(PTW_Invalid_PTE)
          } else {
            /* walk down the pointer to the next level */
            walk39(vaddr, ac, priv, mxr, do_sum, EXTZ(shiftl(pte.PPNi(), PAGESIZE_BITS)), level - 1, is_global)
          }
        } else { /* leaf PTE */
          if ~ (checkPTEPermission(ac, priv, mxr, do_sum, pattr)) then {
/*          print("walk39: pte permission check failure"); */
            PTW_Failure(PTW_No_Permission)
          } else {
            if level > 0 then { /* superpage */
              /* fixme hack: to get a mask of appropriate size */
              let mask = shiftl(pte.PPNi() ^ pte.PPNi() ^ EXTZ(0b1), level * SV39_LEVEL_BITS) - 1;
              if (pte.PPNi() & mask) != EXTZ(0b0) then {
                /* misaligned superpage mapping */
/*              print("walk39: misaligned superpage mapping"); */
                PTW_Failure(PTW_Misaligned)
              } else {
                /* add the appropriate bits of the VPN to the superpage PPN */
                let ppn = pte.PPNi() | (EXTZ(va.VPNi()) & mask);
/*              let res = append(ppn, va.PgOfs());
                print("walk39: using superpage: pte.ppn=" ^ BitStr(pte.PPNi())
                      ^ " ppn=" ^ BitStr(ppn) ^ " res=" ^ BitStr(res)); */
                PTW_Success(append(ppn, va.PgOfs()), pte, pte_addr, level, is_global)
              }
            } else {
              /* normal leaf PTE */
/*            let res = append(pte.PPNi(), va.PgOfs());
              print("walk39: pte.ppn=" ^ BitStr(pte.PPNi()) ^ " ppn=" ^ BitStr(pte.PPNi()) ^ " res=" ^ BitStr(res)); */
              PTW_Success(append(pte.PPNi(), va.PgOfs()), pte, pte_addr, level, is_global)
            }
          }
        }
      }
    }
  }
}

val translate39 : (asid64, paddr64, vaddr39, AccessType, Privilege, bool, bool, nat) -> TR_Result(paddr64, PTW_Error) effect {rreg, wreg, wmv, escape, rmem}
function translate39(asid, ptb, vAddr, ac, priv, mxr, do_sum, level) = {
  match lookupTLB39(asid, vAddr) {
    Some(idx, ent) => {
      let pteBits = Mk_PTE_Bits(ent.pte.BITS());
      if ~ (checkPTEPermission(ac, priv, mxr, do_sum, pteBits))
      then TR_Failure(PTW_No_Permission)
      else {
        match update_PTE_Bits(pteBits, ac) {
          None() => TR_Address(ent.pAddr | EXTZ(vAddr & ent.vAddrMask)),
          Some(pbits) => {
            if ~ (plat_enable_dirty_update ())
            then {
              /* pte needs dirty/accessed update but that is not enabled */
              TR_Failure(PTW_PTE_Update)
            } else {
              /* update PTE entry and TLB */
              n_ent : TLB39_Entry = ent;
              n_ent.pte = update_BITS(ent.pte, pbits.bits());
              writeTLB39(idx, n_ent);
              /* update page table */
              match checked_mem_write(EXTZ(ent.pteAddr), 8, ent.pte.bits(), false, false, false) {
                MemValue(_) => (),
                MemException(e) => internal_error("invalid physical address in TLB")
              };
              TR_Address(ent.pAddr | EXTZ(vAddr & ent.vAddrMask))
            }
          }
        }
      }
    },
    None() => {
      match walk39(vAddr, ac, priv, mxr, do_sum, ptb, level, false) {
        PTW_Failure(f) => TR_Failure(f),
        PTW_Success(pAddr, pte, pteAddr, level, global) => {
          match update_PTE_Bits(Mk_PTE_Bits(pte.BITS()), ac) {
            None() => {
              addToTLB39(asid, vAddr, pAddr, pte, pteAddr, level, global);
              TR_Address(pAddr)
            },
            Some(pbits) =>
              if ~ (plat_enable_dirty_update ())
              then {
                /* pte needs dirty/accessed update but that is not enabled */
                TR_Failure(PTW_PTE_Update)
              } else {
                w_pte : SV39_PTE = update_BITS(pte, pbits.bits());
                match checked_mem_write(EXTZ(pteAddr), 8, w_pte.bits(), false, false, false) {
                  MemValue(_) => {
                    addToTLB39(asid, vAddr, pAddr, w_pte, pteAddr, level, global);
                    TR_Address(pAddr)
                  },
                  MemException(e) => {
                    /* pte is not in valid memory */
                    TR_Failure(PTW_Access)
                  }
                }
              }
          }
        }
      }
    }
  }
}

