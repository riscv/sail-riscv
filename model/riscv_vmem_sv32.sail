/* Sv32 address translation for RV32. */

/* FIXME: paddr32 is 34-bits, but phys_mem accesses in riscv_mem take 32-bit (xlenbits) addresses.
 * Define a converter for now.
 */

function to_phys_addr(a : paddr32) -> xlenbits = a[31..0]

val walk32 : (vaddr32, AccessType, Privilege, bool, bool, paddr32, nat, bool) -> PTW_Result(paddr32, SV32_PTE) effect {rmem, escape}
function walk32(vaddr, ac, priv, mxr, do_sum, ptb, level, global) = {
  let va = Mk_SV32_Vaddr(vaddr);
  let pt_ofs : paddr32 = shiftl(EXTZ(shiftr(va.VPNi(), (level * SV32_LEVEL_BITS))[(SV32_LEVEL_BITS - 1) .. 0]),
                                PTE32_LOG_SIZE);
  let pte_addr = ptb + pt_ofs;
  /* FIXME: we assume here that walks only access physical-memory-backed addresses, and not MMIO regions. */
  match (phys_mem_read(Data, to_phys_addr(pte_addr), 4, false, false, false)) {
    MemException(_) => {
/*    print("walk32(vaddr=" ^ BitStr(vaddr) ^ " level=" ^ string_of_int(level)
            ^ " pt_base=" ^ BitStr(to_phys_addr(ptb))
            ^ " pt_ofs=" ^ BitStr(to_phys_addr(pt_ofs))
            ^ " pte_addr=" ^ BitStr(to_phys_addr(pte_addr))
            ^ ": invalid pte address"); */
      PTW_Failure(PTW_Access)
    },
    MemValue(v) => {
      let pte = Mk_SV32_PTE(v);
      let pbits = pte.BITS();
      let pattr = Mk_PTE_Bits(pbits);
      let is_global = global | (pattr.G() == true);
/*    print("walk32(vaddr=" ^ BitStr(vaddr) ^ " level=" ^ string_of_int(level)
            ^ " pt_base=" ^ BitStr(to_phys_addr(ptb))
            ^ " pt_ofs=" ^ BitStr(to_phys_addr(pt_ofs))
            ^ " pte_addr=" ^ BitStr(to_phys_addr(pte_addr))
            ^ " pte=" ^ BitStr(v)); */
      if isInvalidPTE(pbits) then {
/*      print("walk32: invalid pte"); */
        PTW_Failure(PTW_Invalid_PTE)
      } else {
        if isPTEPtr(pbits) then {
          if level == 0 then {
            /* last-level PTE contains a pointer instead of a leaf */
/*          print("walk32: last-level pte contains a ptr"); */
            PTW_Failure(PTW_Invalid_PTE)
          } else {
            /* walk down the pointer to the next level */
            walk32(vaddr, ac, priv, mxr, do_sum, shiftl(EXTZ(pte.PPNi()), PAGESIZE_BITS), level - 1, is_global)
          }
        } else { /* leaf PTE */
          if ~ (checkPTEPermission(ac, priv, mxr, do_sum, pattr)) then {
/*          print("walk32: pte permission check failure"); */
            PTW_Failure(PTW_No_Permission)
          } else {
            if level > 0 then { /* superpage */
              /* fixme hack: to get a mask of appropriate size */
              let mask = shiftl(pte.PPNi() ^ pte.PPNi() ^ EXTZ(0b1), level * SV32_LEVEL_BITS) - 1;
              if (pte.PPNi() & mask) != EXTZ(0b0) then {
                /* misaligned superpage mapping */
/*              print("walk32: misaligned superpage mapping"); */
                PTW_Failure(PTW_Misaligned)
              } else {
                /* add the appropriate bits of the VPN to the superpage PPN */
                let ppn = pte.PPNi() | (EXTZ(va.VPNi()) & mask);
/*              let res = append(ppn, va.PgOfs());
                print("walk32: using superpage: pte.ppn=" ^ BitStr(pte.PPNi())
                      ^ " ppn=" ^ BitStr(ppn) ^ " res=" ^ BitStr(res)); */
                PTW_Success(append(ppn, va.PgOfs()), pte, pte_addr, level, is_global)
              }
            } else {
              /* normal leaf PTE */
/*            let res = append(pte.PPNi(), va.PgOfs());
              print("walk32: pte.ppn=" ^ BitStr(pte.PPNi()) ^ " ppn=" ^ BitStr(pte.PPNi()) ^ " res=" ^ BitStr(res)); */
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
// type TLB32_Entry = TLB_Entry(sizeof(asid32), sizeof(vaddr32), sizeof(paddr32), sizeof(pte32))
type TLB32_Entry = TLB_Entry(9, 32, 34, 32)
register tlb32 : option(TLB32_Entry)

val lookup_TLB32 : (asid32, vaddr32) -> option((nat, TLB32_Entry)) effect {rreg}
function lookup_TLB32(asid, vaddr) =
  match tlb32 {
    None()  => None(),
    Some(e) => if match_TLB_Entry(e, asid, vaddr) then Some((0, e)) else None()
  }

val add_to_TLB32 : (asid32, vaddr32, paddr32, SV32_PTE, paddr32, nat, bool) -> unit effect {wreg, rreg}
function add_to_TLB32(asid, vAddr, pAddr, pte, pteAddr, level, global) = {
  let ent : TLB32_Entry = make_TLB_Entry(asid, global, vAddr, pAddr, pte.bits(), level, pteAddr, SV32_LEVEL_BITS);
  tlb32 = Some(ent)
}

function write_TLB32(idx : nat, ent : TLB32_Entry) -> unit =
  tlb32 = Some(ent)

val flush_TLB32 : (option(asid32), option(vaddr32)) -> unit effect {rreg, wreg}
function flush_TLB32(asid, addr) =
  match (tlb32) {
    None()  => (),
    Some(e) => if   flush_TLB_Entry(e, asid, addr)
               then tlb32 = None()
               else ()
  }

/* address translation */

val translate32 : (asid32, paddr32, vaddr32, AccessType, Privilege, bool, bool, nat) -> TR_Result(paddr32, PTW_Error) effect {rreg, wreg, wmv, wmvt, escape, rmem}
function translate32(asid, ptb, vAddr, ac, priv, mxr, do_sum, level) = {
  match lookup_TLB32(asid, vAddr) {
    Some(idx, ent) => {
/*    print("translate32: TLB32 hit for " ^ BitStr(vAddr)); */
      let  pte = Mk_SV32_PTE(ent.pte);
      let  pteBits = Mk_PTE_Bits(pte.BITS());
      if ~ (checkPTEPermission(ac, priv, mxr, do_sum, pteBits))
      then TR_Failure(PTW_No_Permission)
      else {
        match update_PTE_Bits(pteBits, ac) {
          None()      => TR_Address(ent.pAddr | EXTZ(vAddr & ent.vAddrMask)),
          Some(pbits) => {
            if ~ (plat_enable_dirty_update ())
            then {
              /* pte needs dirty/accessed update but that is not enabled */
              TR_Failure(PTW_PTE_Update)
            } else {
              /* update PTE entry and TLB */
              n_pte = update_BITS(pte, pbits.bits());
              n_ent : TLB32_Entry = ent;
              n_ent.pte = n_pte.bits();
              write_TLB32(idx, n_ent);
              /* update page table */
              match checked_mem_write(to_phys_addr(EXTZ(ent.pteAddr)), 4, n_pte.bits(), default_meta, false, false, false) {
                MemValue(_)     => (),
                MemException(e) => internal_error("invalid physical address in TLB")
              };
              TR_Address(ent.pAddr | EXTZ(vAddr & ent.vAddrMask))
            }
          }
        }
      }
    },
    None() => {
      match walk32(vAddr, ac, priv, mxr, do_sum, ptb, level, false) {
        PTW_Failure(f) => TR_Failure(f),
        PTW_Success(pAddr, pte, pteAddr, level, global) => {
          match update_PTE_Bits(Mk_PTE_Bits(pte.BITS()), ac) {
            None() => {
              add_to_TLB32(asid, vAddr, pAddr, pte, pteAddr, level, global);
              TR_Address(pAddr)
            },
            Some(pbits) =>
              if ~ (plat_enable_dirty_update ())
              then {
                /* pte needs dirty/accessed update but that is not enabled */
                TR_Failure(PTW_PTE_Update)
              } else {
                w_pte : SV32_PTE = update_BITS(pte, pbits.bits());
                match checked_mem_write(to_phys_addr(pteAddr), 4, w_pte.bits(), default_meta, false, false, false) {
                  MemValue(_) => {
                    add_to_TLB32(asid, vAddr, pAddr, w_pte, pteAddr, level, global);
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

function init_vmem_sv32() -> unit = {
  tlb32 = None()
}
