/* Sv48 address translation for RV64. */

val walk48 : (vaddr48, AccessType, Privilege, bool, bool, paddr64, nat, bool) -> PTW_Result(paddr64, SV48_PTE) effect {rmem, escape}
function walk48(vaddr, ac, priv, mxr, do_sum, ptb, level, global) = {
  let va = Mk_SV48_Vaddr(vaddr);
  let pt_ofs : paddr64 = shiftl(EXTZ(shiftr(va.VPNi(), (level * SV48_LEVEL_BITS))[(SV48_LEVEL_BITS - 1) .. 0]),
                                PTE48_LOG_SIZE);
  let pte_addr = ptb + pt_ofs;
  /* FIXME: we assume here that walks only access physical-memory-backed addresses, and not MMIO regions. */
  match (phys_mem_read(Data, EXTZ(pte_addr), 8, false, false, false)) {
    MemException(_) => {
/*    print("walk48(vaddr=" ^ BitStr(vaddr) ^ " level=" ^ string_of_int(level)
            ^ " pt_base=" ^ BitStr(ptb)
            ^ " pt_ofs=" ^ BitStr(pt_ofs)
            ^ " pte_addr=" ^ BitStr(pte_addr)
            ^ ": invalid pte address"); */
      PTW_Failure(PTW_Access)
    },
    MemValue(v) => {
      let pte = Mk_SV48_PTE(v);
      let pbits = pte.BITS();
      let pattr = Mk_PTE_Bits(pbits);
      let is_global = global | (pattr.G() == true);
/*    print("walk48(vaddr=" ^ BitStr(vaddr) ^ " level=" ^ string_of_int(level)
            ^ " pt_base=" ^ BitStr(ptb)
            ^ " pt_ofs=" ^ BitStr(pt_ofs)
            ^ " pte_addr=" ^ BitStr(pte_addr)
            ^ " pte=" ^ BitStr(v)); */
      if isInvalidPTE(pbits) then {
/*      print("walk48: invalid pte"); */
        PTW_Failure(PTW_Invalid_PTE)
      } else {
        if isPTEPtr(pbits) then {
          if level == 0 then {
            /* last-level PTE contains a pointer instead of a leaf */
/*          print("walk48: last-level pte contains a ptr"); */
            PTW_Failure(PTW_Invalid_PTE)
          } else {
            /* walk down the pointer to the next level */
            walk48(vaddr, ac, priv, mxr, do_sum, shiftl(EXTZ(pte.PPNi()), PAGESIZE_BITS), level - 1, is_global)
          }
        } else { /* leaf PTE */
          if ~ (checkPTEPermission(ac, priv, mxr, do_sum, pattr)) then {
/*          print("walk48: pte permission check failure"); */
            PTW_Failure(PTW_No_Permission)
          } else {
            if level > 0 then { /* superpage */
              /* fixme hack: to get a mask of appropriate size */
              let mask = shiftl(pte.PPNi() ^ pte.PPNi() ^ EXTZ(0b1), level * SV48_LEVEL_BITS) - 1;
              if (pte.PPNi() & mask) != EXTZ(0b0) then {
                /* misaligned superpage mapping */
/*              print("walk48: misaligned superpage mapping"); */
                PTW_Failure(PTW_Misaligned)
              } else {
                /* add the appropriate bits of the VPN to the superpage PPN */
                let ppn = pte.PPNi() | (EXTZ(va.VPNi()) & mask);
/*              let res = append(ppn, va.PgOfs());
                print("walk48: using superpage: pte.ppn=" ^ BitStr(pte.PPNi())
                      ^ " ppn=" ^ BitStr(ppn) ^ " res=" ^ BitStr(res)); */
                PTW_Success(append(ppn, va.PgOfs()), pte, pte_addr, level, is_global)
              }
            } else {
              /* normal leaf PTE */
/*            let res = append(pte.PPNi(), va.PgOfs());
              print("walk48: pte.ppn=" ^ BitStr(pte.PPNi()) ^ " ppn=" ^ BitStr(pte.PPNi()) ^ " res=" ^ BitStr(res)); */
              PTW_Success(append(pte.PPNi(), va.PgOfs()), pte, pte_addr, level, is_global)
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

val lookup_TLB48 : (asid64, vaddr48) -> option((nat, TLB48_Entry)) effect {rreg}
function lookup_TLB48(asid, vaddr) =
  match tlb48 {
    None()  => None(),
    Some(e) => if match_TLB_Entry(e, asid, vaddr) then Some((0, e)) else None()
  }

val add_to_TLB48 : (asid64, vaddr48, paddr64, SV48_PTE, paddr64, nat, bool) -> unit effect {wreg, rreg}
function add_to_TLB48(asid, vAddr, pAddr, pte, pteAddr, level, global) = {
  let ent : TLB48_Entry = make_TLB_Entry(asid, global, vAddr, pAddr, pte.bits(), level, pteAddr, SV48_LEVEL_BITS);
  tlb48 = Some(ent)
}

function write_TLB48(idx : nat, ent : TLB48_Entry) -> unit =
  tlb48 = Some(ent)

val flush_TLB48 : (option(asid64), option(vaddr48)) -> unit effect {rreg, wreg}
function flush_TLB48(asid, addr) =
  match (tlb48) {
    None()  => (),
    Some(e) => if   flush_TLB_Entry(e, asid, addr)
               then tlb48 = None()
               else ()
  }

/* address translation */

val translate48 : (asid64, paddr64, vaddr48, AccessType, Privilege, bool, bool, nat) -> TR_Result(paddr64, PTW_Error) effect {rreg, wreg, wmv, wmvt, escape, rmem}
function translate48(asid, ptb, vAddr, ac, priv, mxr, do_sum, level) = {
  match walk48(vAddr, ac, priv, mxr, do_sum, ptb, level, false) {
    PTW_Failure(f) => TR_Failure(f),
    PTW_Success(pAddr, pte, pteAddr, level, global) => {
      match update_PTE_Bits(Mk_PTE_Bits(pte.BITS()), ac) {
        None() => {
          add_to_TLB48(asid, vAddr, pAddr, pte, pteAddr, level, global);
          TR_Address(pAddr)
        },
        Some(pbits) =>
          if ~ (plat_enable_dirty_update ())
          then {
            /* pte needs dirty/accessed update but that is not enabled */
            TR_Failure(PTW_PTE_Update)
          } else {
            w_pte : SV48_PTE = update_BITS(pte, pbits.bits());
            match checked_mem_write(EXTZ(pteAddr), 8, w_pte.bits(), default_meta, false, false, false) {
              MemValue(_) => {
                add_to_TLB48(asid, vAddr, pAddr, w_pte, pteAddr, level, global);
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

function init_vmem_sv48() -> unit = {
  tlb48 = None()
}
