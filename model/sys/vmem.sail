// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// ****************************************************************
// Virtual memory address translation and memory protection,
// including PTWs (Page Table Walks) and TLBs (Translation Look-aside Buffers)
// Supported VM modes: Sv32, Sv39, Sv48, Sv57

// The code below implements the steps in the "Virtual Address
// Translation Process" (abbreviated here to VATP) section of the
// Privileged Architecture specification.  Code locations
// corresponding to these steps are marked in the comments.

// TLB NOTE:
// TLBs are not part of the RISC-V architecture specification.
// However, we model a simple TLB so that
// (1) we can meaningfully test SFENCE.VMA which is a no-op without TLBs;
// (2) we can greatly speed up simulation speed
//     (e.g., from 10s of minutes to few minutes for Linux boot)
// The TLB implementation is in a separate file: vmem_tlb.sail
// The code in this file is structured and commented so you can easily
// ignore TLB functionality at first reading.

struct PTW_Output('v : Int), is_sv_mode('v) = {
  ppn     : ppn_bits('v),
  pte     : pte_bits('v),
  pteAddr : physaddr,
  level   : level_range('v),
  pbmt    : page_based_mem_type,
  global  : bool,
}

private type PTW_Result('v : Int), is_sv_mode('v) = result((PTW_Output('v), ext_ptw), (PTW_Error, ext_ptw))

// ****************************************************************
// Page Table Walk (PTW)

// Write a Page Table Entry.
private function write_pte forall 'n, 'n in {4, 8} . (
  paddr    : physaddr,
  pte_size : int('n),
  pte      : bits('n * 8),
) -> MemoryOpResult(bool) =
  mem_write_value_priv(paddr, pte_size, pte, Supervisor, Store(PageTableEntry), PBMT_PMA, false, false, false)

// Write a Page Table Entry as the write half of an atomic read-modify-write
// of that PTE.
private function write_pte_conditional forall 'n, 'n in {4, 8} . (
  paddr    : physaddr,
  pte_size : int('n),
  pte      : bits('n * 8),
) -> MemoryOpResult(bool) =
  mem_write_value_priv(paddr, pte_size, pte, Supervisor, Store(PageTableEntry), PBMT_PMA, false, false, true)

// Sscptr: Main memory supports page table read
function clause currentlyEnabled(Ext_Ssccptr) = hartSupports(Ext_Ssccptr) & (currentlyEnabled(Ext_Sv32) | currentlyEnabled(Ext_Sv39))

// Read a Page Table Entry.
private function read_pte forall 'n, 'n in {4, 8} . (
  paddr    : physaddr,
  pte_size : int('n),
) -> MemoryOpResult(bits(8 * 'n)) =
  mem_read_priv(Load(PageTableEntry), PBMT_PMA, Supervisor, paddr, pte_size, false, false, false)

// Read a Page Table Entry as the read half of an atomic read-modify-write
// of that PTE.
private function read_pte_exclusive forall 'n, 'n in {4, 8} . (
  paddr    : physaddr,
  pte_size : int('n),
) -> MemoryOpResult(bits(8 * 'n)) =
  mem_read_priv(Load(PageTableEntry), PBMT_PMA, Supervisor, paddr, pte_size, false, false, true)

// Check a leaf PTE and compute the translated PPN and the PBMT (Steps 3
// and 5-8 of the VATP; Step 4, following valid non-leaf PTEs, is handled
// in pt_walk()).  This is used by pt_walk() when it reaches a leaf PTE,
// and again by update_and_write_pte() to atomically re-perform all
// tablewalk checks on the freshly read PTE value as part of an A/D-bit
// update, as required by the spec (see update_and_write_pte()).
private function check_leaf_pte forall 'v, is_sv_mode('v) . (
  sv_width : int('v),
  vpn      : vpn_bits('v),
  access   : MemoryAccessType(mem_payload),
  priv     : Privilege,
  mxr      : bool,
  do_sum   : bool,
  pte      : pte_bits('v),
  pte_addr : physaddr,
  level    : level_range('v),
  ext_ptw  : ext_ptw,
) -> result((ppn_bits('v), page_based_mem_type, ext_ptw), (PTW_Error, ext_ptw)) = {
  let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);
  let pte_ext   = ext_bits_of_PTE(pte);

  // Step 3 of VATP.
  if pte_is_invalid(pte_flags, pte_ext) then {
    ptw_fail_callback(PTW_Invalid_PTE(), level, bits_of(pte_addr));
    return Err(PTW_Invalid_PTE(), ext_ptw);
  };

  // A non-leaf PTE is not a valid leaf: either this is a level 0 PTE that
  // contains a pointer, or (during an A/D-bit update) the PTE was
  // concurrently replaced by a pointer after the walk read a leaf here.
  if pte_is_non_leaf(pte_flags) then {
    ptw_fail_callback(PTW_Invalid_PTE(), level, bits_of(pte_addr));
    return Err(PTW_Invalid_PTE(), ext_ptw);
  };

  // Leaf PTE (Step 5 of VATP).
  let ppn = PPN_of_PTE(pte); // 22 or 44.
  let ppn_size_bits = if 'v == 32 then 10 else 9;
  if level > 0 then {
    // Check for misaligned superpage.
    let low_bits = ppn_size_bits * level;
    if ppn[low_bits - 1 .. 0] != zeros() then {
      ptw_fail_callback(PTW_Misaligned(), level, bits_of(pte_addr));
      return Err(PTW_Misaligned(), ext_ptw);
    };
  };

  // Steps 6, 7 and 8 of VATP.
  match check_PTE_permission(access, priv, mxr, do_sum, pte_flags, pte_ext, ext_ptw) {
    PTE_Check_Failure(ext_ptw, pte_failure) => {
      ptw_fail_callback(ext_get_ptw_error(pte_failure), level, bits_of(pte_addr));
      Err(ext_get_ptw_error(pte_failure), ext_ptw)
    },
    PTE_Check_Success(ext_ptw) => {
      let ppn : ppn_bits('v) = if level > 0 then {
        // NAPOT PTEs are currently reserved for level > 0.
        if pte_ext[N] == 0b1 & pte_reserved_bits_must_be_zero
        then return Err(PTW_Invalid_PTE(), ext_ptw);

        // Compose final PA in superpage:
        // Superpage PPN @ lower VPNs @ page-offset
        let low_bits = ppn_size_bits * level;
        ppn[length(ppn) - 1 .. low_bits] @ vpn[low_bits - 1 .. 0]
      } else if currentlyEnabled(Ext_Svnapot) & pte_ext[N] == 0b1 then {
        // Only 64K NAPOT PTEs are valid.
        let pte_napot_bits = 4;
        if ppn[pte_napot_bits - 1 .. 0] != 0b1000
        then return Err(PTW_Invalid_PTE(), ext_ptw);

        [ppn with (pte_napot_bits - 1) .. 0 = vpn[pte_napot_bits - 1 .. 0]]
      } else {
        ppn
      };

      let pbmt = if menvcfg[PBMTE] == 0b0 then PBMT_PMA else page_based_mem_type(pte_ext[PBMT]);

      Ok((ppn, pbmt, ext_ptw))
    }
  }
}

// Update a PTE's A/D bits and write it to memory if needed.  This returns
// * Ok(Some(pte), ext_ptw) if a write was needed and was successful. pte is the new value.
// * Ok(None(), ext_ptw) if no write was needed.
// * Err(PTW_PTE_Needs_Update(), ext_ptw) if a write was needed but is forbidden by the current state.
// * Err(e, ext_ptw) if a write was needed but the atomic update failed,
//   either because of a physical memory access error (PTW_No_Access()) or
//   because the tablewalk checks failed on the freshly read PTE value.
//
// The privileged spec requires the A/D-bit update to be atomic:
//
//   "The PTE update must be atomic with respect to other accesses to the
//    PTE, and must atomically perform all tablewalk checks for that leaf
//    PTE as part of, and before, conditionally updating the PTE value."
//
// and Step 7 of the VATP specifies it as a compare-and-swap:
//
//   "Compare pte to the value of the PTE at address a+va.vpn[i]*PTESIZE.
//    If the values match, set pte.a to 1 and, if the original memory
//    access is a store, also set pte.d to 1.  If the comparison fails,
//    return to step 2."
//
// This is modelled here as a single atomic read-check-write of the PTE:
// re-read the PTE with an exclusive read, re-perform the tablewalk checks
// on the freshly read value, and conditionally write back the fresh value
// with updated A/D bits.
private function update_and_write_pte forall 'v, is_sv_mode('v) . (
  sv_width : int('v),
  vpn      : vpn_bits('v),
  pteAddr  : physaddr,
  pte      : pte_bits('v),
  level    : level_range('v),
  access   : MemoryAccessType(mem_payload),
  priv     : Privilege,
  mxr      : bool,
  do_sum   : bool,
  ext_ptw  : ext_ptw,
) -> result((option(pte_bits('v)), ext_ptw), (PTW_Error, ext_ptw)) =
  match update_PTE_Bits(pte, access) {
    None()  => Ok(None(), ext_ptw),
    Some(_) => // The PTE needs new A/D bits.  If neither Svadu nor Svade is
               // supported, the current default is to update the PTE.
      if (currentlyEnabled(Ext_Svadu) & menvcfg[ADUE] == 0b1)
        | (not(currentlyEnabled(Ext_Svadu)) & not(currentlyEnabled(Ext_Svade)))
      then {
        let 'pte_width = if sv_width == 32 then 4 else 8;
        // Atomically: re-read the PTE, redo the tablewalk checks on the
        // fresh value, and write the fresh value with updated A/D bits.
        match read_pte_exclusive(pteAddr, pte_width) {
          Err(_) => Err(PTW_No_Access(), ext_ptw),
          Ok(pte) =>
            // A check failure means the PTE was concurrently modified
            // since the walk read it; the resulting page fault is what
            // the spec's "return to step 2" would produce.
            match check_leaf_pte(sv_width, vpn, access, priv, mxr, do_sum, pte, pteAddr, level, ext_ptw) {
              Err(e, ext_ptw)   => Err(e, ext_ptw),
              Ok(_, _, ext_ptw) =>
                match update_PTE_Bits(pte, access) {
                  // The fresh PTE already has the required A/D bits (they
                  // were set concurrently since the walk read the PTE).
                  None()    => Ok(Some(pte), ext_ptw),
                  Some(pte) =>
                    match write_pte_conditional(pteAddr, pte_width, pte) {
                      Ok(true)  => Ok(Some(pte), ext_ptw),
                      // A failed conditional write corresponds to the
                      // spec's "return to step 2" retry; as for the AMO
                      // write in zaamo_insts.sail, it cannot occur in
                      // the sequential emulator.
                      Ok(false) => internal_error(__FILE__, __LINE__, "PTE conditional write failed"),
                      Err(_)    => Err(PTW_No_Access(), ext_ptw),
                    },
                },
            },
        }
      } else Err(PTW_PTE_Needs_Update(), ext_ptw),
  }

// 'v is the virtual address size.
private val pt_walk : forall 'v, is_sv_mode('v) . (
  int('v),                      // Sv32, Sv39, Sv48, Sv57
  vpn_bits('v),                 // Virtual Page Number
  MemoryAccessType(mem_payload),  // Memory Load{Reserved}/Store{Conditional}/Atomic/InstructionFetch/CacheAccess
  Privilege,                    // User/Supervisor/Machine
  bool,                         // mstatus.MXR
  bool,                         // do_sum
  ppn_bits('v),                 // Base PPN (`a` in the spec).
  level_range('v),              // Tree level for this recursive call (`i` in the spec).
  bool,                         // global translation,
  ext_ptw                       // ext_ptw
) -> PTW_Result('v)

// Steps 2-8 of the VATP.
function pt_walk(
  sv_width,
  vpn,
  access,
  priv,
  mxr,
  do_sum,
  pt_base,
  level,
  global,
  ext_ptw,
) = {
  ptw_start_callback(zero_extend(vpn), access, (priv, ()));

  // Extract the PPN component for this level; 10 bits on Sv32, otherwise 9.
  let 'vpn_i_size = if 'v == 32 then 10 else 9;
  let vpn_i = vpn[(level + 1) * vpn_i_size - 1 .. level * vpn_i_size];
  let 'log_pte_size_bytes = if 'v == 32 then 2 else 3;

  // Address of PTE in page table. This is 34 bits for Sv32, otherwise 56 bits.
  let pte_addr = pt_base @ vpn_i @ zeros('log_pte_size_bytes);


  // Convert to a physical address (34 bits for RV32, 64 bits to RV64).
  // The assertion is required so Sail knows that we can't have a
  // pte_addr of 56 bits and physaddr of 34 bits (because you can't
  // use Sv39+ on RV32).
  assert(sv_width == 32 | xlen == 64);
  let pte_addr = Physaddr(zero_extend(pte_addr));

  // Read this-level PTE from mem (Step 2 of VATP)
  match read_pte(pte_addr, 2 ^ log_pte_size_bytes) {
    Err(_)  => {
      ptw_fail_callback(PTW_No_Access(), level, bits_of(pte_addr));
      Err(PTW_No_Access(), ext_ptw)
    },
    Ok(pte) => {
      ptw_step_callback(level, bits_of(pte_addr), zero_extend(pte));

      let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);
      let global = global | (pte_flags[G] == 0b1);

      // Follow a valid non-leaf PTE to the next level of the page table
      // (Steps 3 and 4 of VATP; invalid PTEs and non-leaf PTEs at level 0
      // are rejected by check_leaf_pte() below).
      if not(pte_is_invalid(pte_flags, ext_bits_of_PTE(pte))) & pte_is_non_leaf(pte_flags) & level > 0 then {
        // follow the pointer to walk next level (i.e., go to Step 2)
        let ppn = PPN_of_PTE(pte);
        pt_walk(sv_width, vpn, access, priv, mxr, do_sum, ppn, level - 1, global, ext_ptw)
      }
      else
        // Steps 3 and 5-8 of VATP.
        match check_leaf_pte(sv_width, vpn, access, priv, mxr, do_sum, pte, pte_addr, level, ext_ptw) {
          Err(e, ext_ptw) => Err(e, ext_ptw),
          Ok(ppn, pbmt, ext_ptw) => {
            ptw_success_callback(zero_extend(ppn), level);

            Ok(struct {ppn=ppn, pte=pte, pteAddr=pte_addr, level=level, pbmt=pbmt, global=global}, ext_ptw)
          },
        }
    }
  }
}

termination_measure pt_walk(_,_,_,_,_,_,_,level,_, _) = level

// ****************************************************************
// Architectural SATP CSR

private function satp_accessible(priv : Privilege) -> bool =
  match priv {
    Machine           => hartSupports(Ext_S),
    Supervisor        => mstatus[TVM]  == 0b0,
    VirtualSupervisor => false /* TODO: hstatus[VTVM] == 0b0 */,
    User              => false,
    VirtualUser       => false,
  }

register satp : xlenbits
mapping clause csr_name_map = 0x180  <-> "satp"
function clause is_CSR_accessible(0x180, priv, _) = satp_accessible(priv)
function clause is_CSR_exception_virtual(0x180, _, _) = true
function clause read_CSR(0x180) = satp
function clause write_CSR(0x180, value) = { satp = legalize_satp(architecture(Supervisor), satp, value); Ok(satp) }

// ----------------
// Fields of SATP

// ASID is 9b in Sv32, 16b in Sv39/Sv48/Sv57
private val satp_to_asid : forall 'n, 'n in {32, 64}. bits('n) -> bits(if 'n == 32 then 9 else 16)
function satp_to_asid(satp_val) =
  if 'n == 32 then Mk_Satp32(satp_val)[Asid] else Mk_Satp64(satp_val)[Asid]

private val satp_to_ppn : forall 'n, 'n in {32, 64}. bits('n) -> bits(if 'n == 32 then 22 else 44)
function satp_to_ppn(satp_val) =
  if 'n == 32 then Mk_Satp32(satp_val)[PPN] else Mk_Satp64(satp_val)[PPN]

// Compute address translation mode from SATP register
function translationMode(priv : Privilege) -> SATPMode = {
  if priv == Machine then Bare
  else {
    let arch = architecture(Supervisor);
    let mbits : satp_mode = match arch {
      RV64 => {
        // Can't have an effective architecture of RV64 on RV32.
        assert(xlen >= 64);
        Mk_Satp64(satp)[Mode]
      },
      RV32 => 0b000 @ Mk_Satp32(satp[31..0])[Mode],
      RV128 => internal_error(__FILE__, __LINE__, "RV128 not supported"),
    };
    match satpMode_of_bits(arch, mbits) {
      Some(m) => m,
      // The model does not support modifying SXL currently so this cannot happen.
      None()  => internal_error(__FILE__, __LINE__, "invalid translation mode in satp")
    }
  }
}

// ****************************************************************
// VA to PA translation

// Result of address translation

type TR_Result('paddr : Type, 'failure : Type) = result(('paddr, page_based_mem_type, ext_ptw), ('failure, ext_ptw))

// This function can be ignored on first reading since TLBs are not
// part of RISC-V architecture spec (see TLB NOTE above).
// Translate on TLB hit, and maintenance of PTE in TLB
private function translate_TLB_hit forall 'v, is_sv_mode('v) . (
  sv_width  : int('v),
  _asid     : asidbits,
  vpn       : vpn_bits('v),
  access    : MemoryAccessType(mem_payload),
  priv      : Privilege,
  mxr       : bool,
  do_sum    : bool,
  ext_ptw   : ext_ptw,
  tlb_index : tlb_index_range,
  ent       : TLB_Entry,
) -> TR_Result(ppn_bits('v), PTW_Error) = {

  let 'pte_size = if sv_width == 32 then 4 else 8;
  let pte       = tlb_get_pte(pte_size, ent);  // Step 2 of VATP.
  let ext_pte   = ext_bits_of_PTE(pte);
  let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);
  let pte_check = check_PTE_permission(access, priv, mxr, do_sum, pte_flags,
                                       ext_pte, ext_ptw);

  match pte_check {
    PTE_Check_Failure(ext_ptw, pte_failure) =>
      Err(ext_get_ptw_error(pte_failure), ext_ptw),
    PTE_Check_Success(ext_ptw) =>
      // Step 9 of VATP.  The A/D-bit update is performed atomically on
      // the PTE in memory (see update_and_write_pte()); if the in-memory
      // PTE no longer passes the tablewalk checks (i.e. it was modified
      // since this TLB entry was filled), the update raises a page fault
      // instead of writing back a stale TLB copy of the PTE.
      match update_and_write_pte(sv_width, vpn, ent.pteAddr, pte, tlb_get_level(sv_width, ent),
                                 access, priv, mxr, do_sum, ext_ptw) {
        Ok(Some(pte), ext_ptw) => {
          // Writeback the PTE (which has new A/D bits).
          write_TLB(tlb_index, tlb_set_pte(ent, pte : bits('pte_size * 8)));
          Ok(tlb_get_ppn(sv_width, ent, vpn), tlb_get_pbmt(ent), ext_ptw)
        },
        Ok(None(), ext_ptw) => Ok(tlb_get_ppn(sv_width, ent, vpn), tlb_get_pbmt(ent), ext_ptw),
        Err(e, ext_ptw) => Err(e, ext_ptw),
      },
  }
}

// Translate on TLB miss (do a page-table walk)
private function translate_TLB_miss forall 'v, is_sv_mode('v) . (
  sv_width : int('v),
  asid     : asidbits,
  base_ppn : ppn_bits('v),
  vpn      : vpn_bits('v),
  access   : MemoryAccessType(mem_payload),
  priv     : Privilege,
  mxr      : bool,
  do_sum   : bool,
  ext_ptw  : ext_ptw,
) -> TR_Result(ppn_bits('v), PTW_Error) = {
  let initial_level = if 'v == 32 then 1 else (if 'v == 39 then 2 else (if 'v == 48 then 3 else 4));

  // Step 2 of VATP occurs in pt_walk().
  let ptw_result = pt_walk(sv_width, vpn, access, priv, mxr, do_sum,
                           base_ppn, initial_level, false, ext_ptw);
  match ptw_result {
    Err(f, ext_ptw) => Err(f, ext_ptw),
    Ok(struct {ppn, pte, pteAddr, level, pbmt, global}, ext_ptw) => {
      // Step 9 of VATP.
      match update_and_write_pte(sv_width, vpn, pteAddr, pte, level,
                                 access, priv, mxr, do_sum, ext_ptw) {
        Ok(Some(new_pte), ext_ptw) => {
          // Writeback the PTE (which has new A/D bits).  In the absence
          // of a concurrent update of the PTE, the fresh value read by
          // update_and_write_pte() equals the value read by the walk, so
          // the walk's ppn and pbmt describe new_pte as well.
          add_to_TLB(sv_width, asid, vpn, ppn, new_pte, pteAddr, level, global);
          Ok(ppn, pbmt, ext_ptw)
        },
        Ok(None(), ext_ptw) => {
          // There was no change in the PTE, but it still needs to be added
          // to the TLB due to the TLB miss.
          add_to_TLB(sv_width, asid, vpn, ppn, pte, pteAddr, level, global);
          Ok(ppn, pbmt, ext_ptw)
        },
        Err(e, ext_ptw) => Err(e, ext_ptw),
      }
    },
  }
}

// Mapping the SATPMode to the width integer. Note there is also SvBare
// and it's an error to call this with SvBare.
mapping satp_mode_width : SATPMode <-> {32, 39, 48, 57} = {
  Sv32 <-> 32,
  Sv39 <-> 39,
  Sv48 <-> 48,
  Sv57 <-> 57,
}

private function translate forall 'v, is_sv_mode('v) . (
  sv_width : int('v),
  asid     : asidbits,
  base_ppn : ppn_bits('v),
  vpn      : vpn_bits('v),
  access   : MemoryAccessType(mem_payload),
  priv     : Privilege,
  mxr      : bool,
  do_sum   : bool,
  ext_ptw  : ext_ptw,
) -> TR_Result(ppn_bits('v), PTW_Error) = {
  // On first reading, assume lookup_TLB returns None(), since TLBs
  // are not part of RISC-V archticture spec (see TLB NOTE above)
  match lookup_TLB(sv_width, asid, vpn) {
    Some(index, ent) => translate_TLB_hit(sv_width, asid, vpn, access, priv,
                                          mxr, do_sum, ext_ptw, index, ent),
    None()           => translate_TLB_miss(sv_width, asid, base_ppn, vpn, access, priv,
                                           mxr, do_sum, ext_ptw),
  }
}

// SATP is represented in the model as an XLEN register (xlenbits), but it's
// actually SXLEN. That means if we are using Sv39 (which is only available when
// SXLEN is 32), then it must be a 32 bit register.
private function get_satp forall 'v, is_sv_mode('v). (
  sv_width : int('v)
) -> bits(if 'v == 32 then 32 else 64) = {
  // Cannot use Sv39+ on RV32.
  assert('v == 32 | xlen == 64);
  if sv_width == 32 then satp[31 .. 0] else satp
}

// Top-level addr-translation function
// PUBLIC: invoked from instr-fetch, atomics and CBOs
// [postlude/fetch.sail, A/zaamo_insts.sail, Zicbo{zm}/zicbo{zm}_insts.sail].
function translateAddr(
  vAddr : virtaddr,
  access : MemoryAccessType(mem_payload),
) -> TR_Result(physaddr, ExceptionType) = {

  // Effective privilege takes into account mstatus.PRV, mstatus.MPP
  // See sys_control.sail for effectivePrivilege() and sys_regs.sail for cur_privilege.
  let effPriv = effectivePrivilege(access, mstatus, cur_privilege);

  let mode = translationMode(effPriv);

  // "If satp.MODE (or vsatp.MODE when V=1) is set to Bare and the
  // effective privilege mode is less than M, shadow stack
  // instructions raise a store/AMO access-fault exception."
  // "Use of Zicfiss in M-mode is not supported."
  if is_shadow_stack_access(access) then {
    if (mode == Bare & effPriv != Machine) | effPriv == Machine
    then return Err(E_SAMO_Access_Fault(), init_ext_ptw);
  };

  if mode == Bare then return Ok(Physaddr(zero_extend(bits_of(vAddr))), PBMT_PMA, init_ext_ptw);

  // Sv39 -> 39, etc.
  let sv_width = satp_mode_width(mode);

  // For Sv32 on RV64, satp is 32 bits (SXLEN), not XLEN.
  let satp_sxlen = get_satp(sv_width);

  // Cannot use Sv39+ on RV32.
  assert(sv_width == 32 | xlen == 64);

  let svAddr = bits_of(vAddr)[sv_width - 1 .. 0];
  if bits_of(vAddr) != sign_extend(svAddr) then {
    Err(translationException(access, PTW_Invalid_Addr()), init_ext_ptw)
  } else {
    let mxr    = mstatus[MXR] == 0b1;
    let do_sum = mstatus[SUM] == 0b1;
    let asid   = satp_to_asid(satp_sxlen);

    // Step 1 of VATP.
    let base_ppn = satp_to_ppn(satp_sxlen);

    let res = translate(sv_width,
                        zero_extend(asid),
                        base_ppn,
                        svAddr[sv_width - 1 .. pagesize_bits],
                        access, effPriv, mxr, do_sum,
                        init_ext_ptw);
    // Fixup result PA or exception
    match res {
      Ok(ppn, pbmt, ext_ptw) => {
        // Step 10 of VATP.
        // Append the page offset. This is now a 34 or 56 bit address.
        let paddr = ppn @ bits_of(vAddr)[pagesize_bits - 1 .. 0];

        // On RV64 paddr can be 34 or 56 bits, so we zero extend to 64.
        // On RV32 paddr can only be 34 bits. Sail knows this due to
        // the assertion above.
        // High PPN bits above the implemented physical address width are
        // deliberately not masked: "The algorithm does not admit the
        // possibility of ignoring high-order PPN bits for implementations
        // with narrower physical addresses." Such addresses instead fault
        // at the PMA/PMP checks.
        Ok(Physaddr(zero_extend(paddr)), pbmt, ext_ptw)
      },
      Err(f, ext_ptw)  => Err(translationException(access, f), ext_ptw)
    }
  }
}

// ****************************************************************
// Initialize Virtual Memory state

// PUBLIC: invoked from reset() [postlude/model.sail]
function reset_vmem() -> unit = reset_TLB()

// ****************************************************************
