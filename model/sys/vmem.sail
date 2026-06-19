// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// TODO: Rewrite this paragraph once Hypervisor extension is implemented and
// we have a better sense of how to structure the code.
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

struct PTW_Output('v : Int), is_sv_or_svx4_mode('v) = {
  ppn     : ppn_bits('v),
  pte     : pte_bits('v),
  pteAddr : physaddr,
  level   : level_range('v),
  pbmt    : page_based_mem_type,
  global  : bool,
}

private type PTW_Result('v : Int), is_sv_or_svx4_mode('v) = result((PTW_Output('v), ext_ptw), (PTW_Error, ext_ptw))

// Result of address translation
type TR_Result('paddr : Type, 'failure : Type) = result(('paddr, page_based_mem_type, ext_ptw), ('failure, ext_ptw))

// TODO: Remove this forward declaration if possible.
// G-Stage Translation
val translate_g_stage : (
  gpabits,
  MemoryAccessType(mem_payload),
  Privilege,
) -> TR_Result(gpabits, PTW_Error)

// ****************************************************************
// Page Table Walk (PTW)

// Write a Page Table Entry.
private function write_pte forall 'n, 'n in {4, 8} . (
  paddr    : physaddr,
  pte_size : int('n),
  pte      : bits('n * 8),
) -> MemoryOpResult(bool) =
  mem_write_value_priv(paddr, pte_size, pte, Supervisor, Store(PageTableEntry), PBMT_PMA, false, false, false)

// Sscptr: Main memory supports page table read
function clause currentlyEnabled(Ext_Ssccptr) = hartSupports(Ext_Ssccptr) & (currentlyEnabled(Ext_Sv32) | currentlyEnabled(Ext_Sv39))

// Read a Page Table Entry.
private function read_pte forall 'n, 'n in {4, 8} . (
  paddr    : physaddr,
  pte_size : int('n),
) -> MemoryOpResult(bits(8 * 'n)) =
  mem_read_priv(Load(PageTableEntry), PBMT_PMA, Supervisor, paddr, pte_size, false, false, false)

// Perform PTE address translation as part of VS-stage translation for implicit PTE accesses
private function translate_PTE_addr(
  pte_addr : gpabits,
  access   : MemoryAccessType(mem_payload),
  stage    : TranslationStage,
  ext_ptw  : ext_ptw
) -> TR_Result(physaddr, PTW_Error) = {
  if stage == VS_Stage then {
    // Supervisor ensures G-stage is enabled; permission checking always uses User.
    match translate_g_stage(pte_addr, access, Supervisor) {
      Ok(pa, pbmt, ext_ptw) => Ok(Physaddr(pa), pbmt, ext_ptw),
      Err(f, ext_ptw) => Err(f, ext_ptw),
    }
  } else {
    Ok(Physaddr(pte_addr), PBMT_PMA, ext_ptw)
  }
}

termination_measure translate_PTE_addr(_, _, _, _) = 1000

// Update a PTE's A/D bits and write it to memory if needed.  This returns
// * Ok(Some(pte)) if a write was needed and was successful. pte is the new value.
// * Ok(None()) if no write was needed.
// * Err(PTW_PTE_Needs_Update()) if a write was needed but is forbidden by the current state
// * Err(PTW_No_Access()) if a write was needed and attempted but there was an error.
private function update_and_write_pte forall 'pte_width, 'pte_width in {4, 8} . (
  pteAddr  : physaddr,
  pteWidth : int('pte_width),
  pte      : bits('pte_width * 8),
  access   : MemoryAccessType(mem_payload),
  stage    : TranslationStage,
  ext_ptw  : ext_ptw,
) -> result(option(bits('pte_width * 8)), PTW_Error) =
  match update_PTE_Bits(pte, access) {
    None()    => Ok(None()),
    Some(pte) => // The PTE has new A/D bits.  If neither Svadu or Svade is supported,
                 // the current default is to update the PTE.
                if (currentlyEnabled(Ext_Svadu) & (match stage {
                    VS_Stage => henvcfg[ADUE] == 0b1,
                    _        => menvcfg[ADUE] == 0b1,
                    }))
                  | (not(currentlyEnabled(Ext_Svadu)) & not(currentlyEnabled(Ext_Svade)))
                 then {
                   // Translate PTE address if performing a VS-stage access
                   let write_paddr : physaddr = match translate_PTE_addr(bits_of(pteAddr), Store(Data), stage, ext_ptw) {
                     Ok(pa, _, _) => pa,
                     Err(e, _)    => return Err(PTW_Implicit_Error(translationException(access, e), bits_of(pteAddr), Store(Data))),
                   };
                   match write_pte(write_paddr, pteWidth, pte) {
                     Ok(_)  => Ok(Some(pte)),
                     Err(_) => Err(PTW_No_Access()),
                   }
                 } else {
                   Err(PTW_PTE_Needs_Update())
                 },
  }

termination_measure update_and_write_pte(_, _, _, _, _, _) = 1000

// 'v is the virtual address size.
private val pt_walk : forall 'v, is_sv_or_svx4_mode('v) . (
  int('v),                      // Sv32, Sv39, Sv48, Sv57
  vpn_bits('v),                 // Virtual Page Number
  MemoryAccessType(mem_payload),  // Memory Load{Reserved}/Store{Conditional}/Atomic/InstructionFetch/CacheAccess
  Privilege,                    // Privilege
  bool,                         // mstatus.MXR
  bool,                         // do_sum
  ppn_bits('v),                 // Base PPN (`a` in the spec).
  level_range('v),              // Tree level for this recursive call (`i` in the spec).
  bool,                         // global translation
  TranslationStage,             // stage
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
  stage,
  ext_ptw,
) = {
  ptw_start_callback(zero_extend(vpn), access, (priv, ()));

  let 'log_pte_size_bytes = if 'v == 32 | 'v == 34 then 2 else 3;
  let 'vpn_i_size         = pagesize_bits - 'log_pte_size_bytes;

  // Svx4 root level has 2 extra bits
  let is_svx4_root = ('v == 34 | 'v == 41 | 'v == 50 | 'v == 59) & (level == get_root_level(sv_width));

  let vpn_lo = level * vpn_i_size;
  let vpn_hi = if is_svx4_root
               then (level + 1) * vpn_i_size + 1
               else (level + 1) * vpn_i_size - 1;

  let pte_addr = (pt_base @ zeros(pagesize_bits))
               + zero_extend(vpn[vpn_hi .. vpn_lo] @ zeros('log_pte_size_bytes));

  // Convert to a physical address (34 bits for RV32, 64 bits to RV64).
  // The assertion is required so Sail knows that we can't have a
  // pte_addr of 56 bits and physaddr of 34 bits (because you can't
  // use Sv39+ on RV32).
  assert('v == 32 | 'v == 34 | xlen == 64);

  // Save before G-stage translation
  let pte_addr_original = Physaddr(zero_extend(pte_addr));

  // Translate PTE address if performing a VS-stage access
  let pte_addr : physaddr = match translate_PTE_addr(zero_extend(pte_addr), Load(Data), stage, ext_ptw) {
    Ok(pa, _, _) => pa,
    Err((e, _))  => return Err(PTW_Implicit_Error(translationException(access, e), zero_extend(pte_addr), Load(Data)), ext_ptw),
  };

  // Read this-level PTE from mem (Step 2 of VATP)
  match read_pte(pte_addr, 2 ^ log_pte_size_bytes) {
    Err(_)  => {
      ptw_fail_callback(PTW_No_Access(), level, bits_of(pte_addr));
      Err(PTW_No_Access(), ext_ptw)
    },
    Ok(pte) => {
      ptw_step_callback(level, bits_of(pte_addr), zero_extend(pte));

      let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);
      let pte_ext   = ext_bits_of_PTE(pte);

      if pte_is_invalid(pte_flags, pte_ext, stage) then {
        // Step 3 of VATP.
        ptw_fail_callback(PTW_Invalid_PTE(), level, bits_of(pte_addr));
        Err(PTW_Invalid_PTE(), ext_ptw)
      }
      else {
        // Step 4 of VATP.
        let ppn = PPN_of_PTE(pte); // 22 or 44.
        let global = global | (pte_flags[G] == 0b1);
        if pte_is_non_leaf(pte_flags) then {
          // Non-Leaf PTE
          if level > 0 then
            // follow the pointer to walk next level (i.e., go to Step 2)
            pt_walk(sv_width, vpn, access, priv, mxr, do_sum, ppn, level - 1, global, stage, ext_ptw)
          else {
            // level 0 PTE, but contains a pointer instead of a leaf
            ptw_fail_callback(PTW_Invalid_PTE(), level, bits_of(pte_addr));
            Err(PTW_Invalid_PTE(), ext_ptw)
          }
        } else {
          // Leaf PTE (Step 5 of VATP).
          let low_bits = vpn_i_size * level;
          if level > 0 then {
            // Check for misaligned superpage.
            if   ppn[low_bits - 1 .. 0] != zeros()
            then {
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
              let ppn = if level > 0 then {
                // NAPOT PTEs are currently reserved for level > 0.
                if pte_ext[N] == 0b1 & pte_reserved_bits_must_be_zero
                then return Err(PTW_Invalid_PTE(), ext_ptw);

                // Compose final PA in superpage:
                // Superpage PPN @ lower VPNs @ page-offset
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

              ptw_success_callback(zero_extend(ppn), level);
              // Store the original (pre-translation) PTE address for 2-stage translation in VS-Stage.
              // For G-Stage or S-Stage, pte_addr == pte_address_original.
              Ok(struct {ppn=ppn, pte=pte, pteAddr = pte_addr_original, level=level, pbmt=pbmt, global=global}, ext_ptw)
            }
          }
        }
      }
    }
  }
}

termination_measure pt_walk(_,_,_,_,_,_,_,level,_,_, _) = level

// ****************************************************************
// Architectural HGATP CSR
register hgatp : xlenbits
mapping clause csr_name_map = 0x680 <-> "hgatp"

function clause is_CSR_accessible(0x680, priv, _) = currentlyEnabled(Ext_H) & (priv == Machine | (priv == Supervisor & mstatus[TVM] == 0b0))
function clause is_CSR_exception_virtual(0x680, _, _) = true
function clause read_CSR(0x680) = hgatp
function clause write_CSR(0x680, value) = { hgatp = legalize_hgatp(architecture(cur_privilege), hgatp, value); Ok(hgatp) }

// Architectural VSATP CSR
register vsatp : xlenbits
mapping clause csr_name_map = 0x280 <-> "vsatp"

function clause is_CSR_accessible(0x280, _, _) = currentlyEnabled(Ext_H)
function clause read_CSR(0x280) = vsatp
function clause write_CSR(0x280, value) = { vsatp = legalize_satp(architecture(cur_privilege), vsatp, value); Ok(vsatp) }

// Architectural SATP CSR
private function is_satp_accessible(priv : Privilege) -> bool =
  match priv {
    Machine           => hartSupports(Ext_S),
    Supervisor        => mstatus[TVM]  == 0b0,
    VirtualSupervisor => hstatus[VTVM] == 0b0,
    User              => false,
    VirtualUser       => false,
  }

register satp : xlenbits
mapping clause csr_name_map = 0x180  <-> "satp"
function clause is_CSR_accessible(0x180, priv, _) = is_satp_accessible(priv)
function clause is_CSR_exception_virtual(0x180, _, _) = true
function clause read_CSR(0x180) = if inVirtualPrivilege() then vsatp else satp
function clause write_CSR(0x180, value) =
  if inVirtualPrivilege()
  then { vsatp = legalize_satp(architecture(cur_privilege), vsatp, value); Ok(vsatp) }
  else { satp  = legalize_satp(architecture(Supervisor),    satp,  value); Ok(satp)  }

// ----------------
// Fields of SATP

// ASID is 9b in Sv32, 16b in Sv39/Sv48/Sv57
private function get_asid(stage : TranslationStage) -> asidbits = {
  match stage {
    S_Stage  => if xlen == 32 then Mk_Satp32(satp)[Asid]  else Mk_Satp64(satp)[Asid],
    VS_Stage => if xlen == 32 then Mk_Satp32(vsatp)[Asid] else Mk_Satp64(vsatp)[Asid],
    G_Stage  => zeros(),
  }
}

function get_vmid(stage : TranslationStage) -> vmidbits =
  if stage == S_Stage then zeros() else if xlen == 32 then Mk_Hgatp32(hgatp)[VMID] else Mk_Hgatp64(hgatp)[VMID]

private function xatp_to_ppn(stage : TranslationStage) -> bits(if xlen == 32 then 22 else 44) = {
  match stage {
    S_Stage  => if xlen == 32 then Mk_Satp32(satp)[PPN]   else Mk_Satp64(satp)[PPN],
    VS_Stage => if xlen == 32 then Mk_Satp32(vsatp)[PPN]  else Mk_Satp64(vsatp)[PPN],
    G_Stage  => if xlen == 32 then Mk_Hgatp32(hgatp)[PPN] else Mk_Hgatp64(hgatp)[PPN],
  }
}

// Return the active address translation mode for S-Stage translation.
private function satp_mode(priv : Privilege) -> SATPMode = {
  if priv == Machine then Bare
  else {
    let arch = architecture(Supervisor);
    let mbits : satp_mode = match arch {
      RV64 => { assert(xlen >= 64); Mk_Satp64(satp)[Mode] },
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

// Return the active address translation mode for VS-Stage translation.
private function vsatp_mode(priv : Privilege) -> SATPMode = {
  if priv == Machine then Bare
  else {
    let arch = architecture(VirtualSupervisor);
    let mbits : satp_mode = match arch {
      RV64 => { assert(xlen >= 64); Mk_Satp64(vsatp)[Mode] },
      RV32 => 0b000 @ Mk_Satp32(vsatp[31..0])[Mode],
      RV128 => internal_error(__FILE__, __LINE__, "RV128 not supported"),
    };
    match satpMode_of_bits(arch, mbits) {
      Some(m) => m,
      // The model does not support modifying VSXL currently so this cannot happen.
      None()  => internal_error(__FILE__, __LINE__, "invalid translation mode in vsatp")
    }
  }
}

// Return the active address translation mode for G-Stage translation.
private function hgatp_mode(priv : Privilege) -> HGATPMode = {
  if priv == Machine then HBare
  else {
    let arch = architecture(Supervisor);
    let mbits : hgatp_mode = match arch {
      RV64 => { assert(xlen >= 64); Mk_Hgatp64(hgatp)[Mode] },
      RV32 => 0b000 @ Mk_Hgatp32(hgatp[31..0])[Mode],
      RV128 => internal_error(__FILE__, __LINE__, "RV128 not supported"),
    };
    match hgatpMode_of_bits(arch, mbits) {
      Some(m) => m,
      // The model does not support modifying SXL currently so this cannot happen.
      None()  => internal_error(__FILE__, __LINE__, "invalid translation mode in hgatp")
    }
  }
}

// ****************************************************************
// VA to PA translation

// This function can be ignored on first reading since TLBs are not
// part of RISC-V architecture spec (see TLB NOTE above).
// Translate on TLB hit, and maintenance of PTE in TLB
private function translate_TLB_hit forall 'v, is_sv_or_svx4_mode('v) . (
  sv_width  : int('v),
  _asid     : asidbits,
  _vmid     : vmidbits,
  vpn       : vpn_bits('v),
  access    : MemoryAccessType(mem_payload),
  priv      : Privilege,
  mxr       : bool,
  do_sum    : bool,
  tlb_index : tlb_index_range,
  ent       : TLB_Entry,
  stage     : TranslationStage,
  ext_ptw   : ext_ptw,
) -> TR_Result(ppn_bits('v), PTW_Error) = {

  let pte_size  = if sv_width == 32 then 4 else 8;
  let pte       = tlb_get_pte(pte_size, ent);  // Step 2 of VATP.
  let ext_pte   = ext_bits_of_PTE(pte);
  let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);
  let pte_check = check_PTE_permission(access, priv, mxr, do_sum, pte_flags,
                                       ext_pte, ext_ptw);
  match pte_check {
    PTE_Check_Failure(ext_ptw, pte_failure) =>
      Err(ext_get_ptw_error(pte_failure), ext_ptw),
    PTE_Check_Success(ext_ptw) => {
      // Step 9 of VATP.
      match update_and_write_pte(ent.pteAddr, pte_size, pte, access, stage, ext_ptw) {
        Ok(Some(pte)) => {
          // Writeback the PTE (which has new A/D bits).
          write_TLB(tlb_index, tlb_set_pte(ent, pte));
          Ok(tlb_get_ppn(sv_width, ent, vpn), tlb_get_pbmt(ent), ext_ptw)
        },
        Ok(None()) => Ok(tlb_get_ppn(sv_width, ent, vpn), tlb_get_pbmt(ent), ext_ptw),
        Err(PTW_PTE_Needs_Update()) => Err(PTW_PTE_Needs_Update(), ext_ptw),
        Err(e) => Err(e, ext_ptw),
      }
    },
  }
}

termination_measure translate_TLB_hit(_, _, _, _, _, _, _, _, _, _, _, _) = 1000

// Translate on TLB miss (do a page-table walk)
private function translate_TLB_miss forall 'v, is_sv_or_svx4_mode('v) . (
  sv_width : int('v),
  asid     : asidbits,
  vmid     : vmidbits,
  base_ppn : ppn_bits('v),
  vpn      : vpn_bits('v),
  access   : MemoryAccessType(mem_payload),
  priv     : Privilege,
  mxr      : bool,
  do_sum   : bool,
  stage    : TranslationStage,
  ext_ptw  : ext_ptw,
) -> TR_Result(ppn_bits('v), PTW_Error) = {
  let initial_level = get_root_level(sv_width);

  // Step 2 of VATP occurs in pt_walk().
  let 'pte_size = if 'v == 32 | 'v == 34 then 4 else 8;
  let ptw_result = pt_walk(sv_width, vpn, access, priv, mxr, do_sum,
                           base_ppn, initial_level, false, stage, ext_ptw);
  match ptw_result {
    Err(f, ext_ptw) => Err(f, ext_ptw),
    Ok(struct {ppn, pte, pteAddr, level, pbmt, global}, ext_ptw) => {
      let ext_pte = ext_bits_of_PTE(pte);
      // Step 9 of VATP.
      match update_and_write_pte(pteAddr, pte_size, pte, access, stage, ext_ptw) {
        Ok(Some(new_pte)) => {
          // Writeback the PTE (which has new A/D bits).
          add_to_TLB(sv_width, asid, vmid, vpn, ppn, new_pte, pteAddr, level, global, stage);
          Ok(ppn, pbmt, ext_ptw)
        },
        Ok(None()) => {
          // There was no change in the PTE, but it still needs to be added
          // to the TLB due to the TLB miss.
          add_to_TLB(sv_width, asid, vmid, vpn, ppn, pte, pteAddr, level, global, stage);
          Ok(ppn, pbmt, ext_ptw)
        },
        Err(e) => Err(e, ext_ptw),
      }
    },
  }
}

termination_measure translate_TLB_miss(_, _, _, _, _, _, _, _, _, _, _) = 1000

// Mapping the SATPMode to the width integer. Note there is also SvBare
// and it's an error to call this with SvBare.
mapping satp_mode_width : SATPMode <-> {32, 39, 48, 57} = {
  Sv32 <-> 32,
  Sv39 <-> 39,
  Sv48 <-> 48,
  Sv57 <-> 57,
}

mapping hgatp_mode_width : HGATPMode <-> {34, 41, 50, 59} = {
  Sv32x4 <-> 34,
  Sv39x4 <-> 41,
  Sv48x4 <-> 50,
  Sv57x4 <-> 59,
}

private function translate forall 'v, is_sv_or_svx4_mode('v) . (
  sv_width : int('v),
  asid     : asidbits,
  vmid     : vmidbits,
  base_ppn : ppn_bits('v),
  vpn      : vpn_bits('v),
  access   : MemoryAccessType(mem_payload),
  priv     : Privilege,
  mxr      : bool,
  do_sum   : bool,
  stage    : TranslationStage,
  ext_ptw  : ext_ptw,
) -> TR_Result(ppn_bits('v), PTW_Error) = {
  // On first reading, assume lookup_TLB returns None(), since TLBs
  // are not part of RISC-V archticture spec (see TLB NOTE above)
  match lookup_TLB(sv_width, asid, vmid, vpn, stage) {
    Some(index, ent) => translate_TLB_hit(sv_width, asid, vmid, vpn, access, priv,
                                          mxr, do_sum, index, ent, stage, ext_ptw),
    None()           => translate_TLB_miss(sv_width, asid, vmid, base_ppn, vpn, access, priv,
                                           mxr, do_sum, stage, ext_ptw),
  }
}

termination_measure translate(_, _, _, _, _, _, _, _, _, _, _) = 1000

private function get_mxr(stage : TranslationStage) -> bool =
  if stage == VS_Stage then mstatus[MXR] == 0b1 | vsstatus[MXR] == 0b1 else mstatus[MXR] == 0b1

private function get_sum(stage : TranslationStage) -> bool =
  if stage == VS_Stage then vsstatus[SUM] == 0b1 else mstatus[SUM]  == 0b1

private val translate_validate_address : forall 'n 'v, is_sv_or_svx4_mode('v) & 'n >= 'v. (bits('n), int('v), TranslationStage) -> result(bits('v), PTW_Error)
function translate_validate_address(addr, sv_width, stage) = {
  let truncated           = truncate(addr, sv_width);
  let extended : bits('n) = if stage == G_Stage then zero_extend(truncated) else sign_extend(truncated);
  if addr == extended
  then Ok(truncated)
  else Err(PTW_Invalid_Addr())
}

private function translate_stage forall 'n 'v, is_sv_or_svx4_mode('v) & 'n >= 'v. (
  sv_width : int('v),
  addr     : bits('n),
  access   : MemoryAccessType(mem_payload),
  priv     : Privilege,
  stage    : TranslationStage
) -> TR_Result(gpabits, PTW_Error) = {
  match translate_validate_address(addr, sv_width, stage) {
    Err(e)         => Err(e, init_ext_ptw),
    Ok(valid_addr) => {
      assert((xlen == 32 & (sv_width == 32 | sv_width == 34)) |
             (xlen == 64 &  sv_width != 32 & sv_width != 34));
      let asid     = get_asid(stage);
      let vmid     = get_vmid(stage);
      let mxr      = get_mxr(stage);
      let do_sum   = get_sum(stage);
      let vpn      = valid_addr[sv_width - 1 .. pagesize_bits];
      let base_ppn = xatp_to_ppn(stage);
      let eff_priv = if stage == G_Stage then User else priv;
      let res = translate(sv_width, asid, vmid,
                          base_ppn, vpn, access,
                          eff_priv, mxr, do_sum,
                          stage, init_ext_ptw);
      match res {
        Ok(ppn, pbmt, ext_ptw) => Ok(zero_extend(ppn @ valid_addr[pagesize_bits - 1 .. 0]), pbmt, ext_ptw),
        Err(f, ext_ptw)  => Err(f, ext_ptw)
      }
    }
  }
}

termination_measure translate_stage(_, _, _, _, _) = 1000

// Wrapper for VS/S-stage translation (takes virtaddr)
function translate_vs_stage(
  vaddr  : virtaddr,
  access : MemoryAccessType(mem_payload),
  p      : Privilege
) -> TR_Result(gpabits, PTW_Error) = {
  let (stage, mode) = if p == VirtualSupervisor | p == VirtualUser
                      then (VS_Stage, vsatp_mode(p))
                      else (S_Stage, satp_mode(p));
  if mode == Bare then return Ok(zero_extend(bits_of(vaddr)), PBMT_PMA, init_ext_ptw);
  let sv_width = satp_mode_width(mode);
  assert(sv_width <= xlen);
  translate_stage(sv_width, bits_of(vaddr), access, p, stage)
}

// Wrapper for G-stage translation (takes physaddr)
function translate_g_stage(
  gpa    : gpabits,
  access : MemoryAccessType(mem_payload),
  p      : Privilege
) -> TR_Result(gpabits, PTW_Error) = {
  let mode = hgatp_mode(p);
  if mode == HBare then return Ok(gpa, PBMT_PMA, init_ext_ptw);
  let sv_width = hgatp_mode_width(mode);
  assert(sv_width <= gpalen);
  translate_stage(sv_width, gpa, access, p, G_Stage)
}

termination_measure translate_g_stage(_, _, _) = 1000

// There are three cases in which an access can fail during two-stage address translation.
//
// Case      Exception                        stval htval      Who Handles
// Implicit  VS-Stage fail Guest-page fault   GVA   PTE's GPA  Hypervisor
// Explicit  VS-Stage fail Regular page fault GVA   0          Virtual Supervisor
// Explicit  G-Stage  fail Guest-page fault   GVA   GPA        Hypervisor
//
// We save all the information in Exception_Context in order to set the appropriate
// CSR's according to the effective privilege mode and given faulting stage.
function build_exception_context(
  gva       : virtaddr,
  gpa       : gpabits,
  access    : MemoryAccessType(mem_payload),
  ptw_error : PTW_Error,
  stage     : TranslationStage
) -> Exception_Context = {
  match stage {
    S_Stage => {
    // S-Stage failure
      struct {
        trap  = translationException(access, ptw_error),
        excinfo_is_gva = false,
        excinfo  = zero_extend(bits_of(gva)),
        excinfo2 = None(),
        excinst  = None(),
        ext      = None(),
      }
    },
    VS_Stage => {
      match ptw_error {
        PTW_Implicit_Error(e, pte_addr, access) => {
          // Implicit VS-Stage failure
          let is_write : bool = match access {
            Store(_) => true,
            Load(_)  => false,
            _        => internal_error(__FILE__, __LINE__, "invalid memory access type"),
          };
          struct {
            trap  = convertToGuestException(e),
            excinfo_is_gva = true,
            excinfo  = zero_extend(bits_of(gva)),
            excinfo2 = Some(truncate(pte_addr >> 2, xlen)),
            // NOTE: "when a guest-page fault is caused by an implicit
            // memory access during VS-stage address translation and htval/mtval2 is nonzero,
            // a pseudoinstruction MUST be written to htinst/mtinst (zero is not allowed).
            // The pseudoinstruction encodes whether the implicit access was a read (PTE fetch)
            // or a write (hardware A/D bit update in VS-level page tables)."
            //
            // 0x00002000 = 32-bit read  (hardware was reading a PTE)
            // 0x00002020 = 32-bit write (hardware was updating A/D bits)
            // 0x00003000 = 64-bit read
            // 0x00003020 = 64-bit write
            excinst = if truncate(pte_addr >> 2, xlen) != zeros()
                      then Some(if xlen == 32
                           then if is_write then zero_extend(0x00002020) else zero_extend(0x00002000)
                           else if is_write then zero_extend(0x00003020) else zero_extend(0x00003000))
                      else None(),
            ext = None(),
          }
        },
        _ => {
          // Explicit VS-Stage failure
          struct {
            trap  = translationException(access, ptw_error),
            excinfo_is_gva = true,
            excinfo  = zero_extend(bits_of(gva)),
            excinfo2 = Some(zeros()),
            excinst  = None(),
            ext      = None(),
          }
        }
      }
    },
    G_Stage => {
      // G-Stage failure
      struct {
        trap  = convertToGuestException(translationException(access, ptw_error)),
        excinfo_is_gva = true,
        excinfo  = zero_extend(bits_of(gva)),
        excinfo2 = Some(truncate(gpa >> 2, xlen)),
        excinst  = None(),
        ext      = None(),
      }
    }
  }
}

// NOTE: We must pass the effective privilege level, since hypervisor
// instructions may execute with a different effective privilege.
function translateAddr_eff_priv(
  gva    : virtaddr,
  access : MemoryAccessType(mem_payload),
  p      : Privilege
) -> TR_Result(physaddr, Exception_Context) = {


  // True if the effective privilege is virtual (VS/VU), as opposed to
  // the hart's current privilege. Used by hlv/hsv which execute in
  // HS or M mode but emulate a virtual-mode memory access.
  let is_virtual_access = p == VirtualSupervisor | p == VirtualUser;

  let mode = if is_virtual_access then vsatp_mode(p) else satp_mode(p);

  // "If satp.MODE (or vsatp.MODE when V=1) is set to Bare and the
  // effective privilege mode is less than M, shadow stack
  // instructions raise a store/AMO access-fault exception."
  // "Use of Zicfiss in M-mode is not supported."
  if is_shadow_stack_access(access) then {
    if ((mode == Bare & p != Machine) | p == Machine) then
    // build_exception_context expects ptw_error, as a work around we manually
    // construct the exception context.
    return Err(struct {
      trap  = E_SAMO_Access_Fault(),
      excinfo_is_gva = false,
      excinfo  = zero_extend(bits_of(gva)),
      excinfo2 = None(),
      excinst  = None(),
      ext      = None(),
    }, init_ext_ptw);
  };

  // First stage: GVA -> GPA (or VA -> PA for single-stage)
  match translate_vs_stage(gva, access, p) {
    Ok(gpa, pbmt, ext_ptw) => {
      if not(is_virtual_access) then {
        return Ok(Physaddr(gpa), pbmt, ext_ptw)
      };
      // Second stage: GPA -> SPA
      match translate_g_stage(gpa, access, p) {
        Ok(spa, pbmt, ext_ptw)  => Ok(Physaddr(spa), pbmt, ext_ptw),
        // G-Stage failure
        Err(ptw_error, ext_ptw) => Err(build_exception_context(gva, gpa, access, ptw_error, G_Stage), ext_ptw)
      }
    },
    // S/VS-stage failure
    Err(ptw_error, ext_ptw) => Err(build_exception_context(gva, zeros(), access, ptw_error, if is_virtual_access then VS_Stage else S_Stage), ext_ptw)
  }
}

// Top-level addr-translation function
// PUBLIC: invoked from instr-fetch, atomics and CBOs
// [postlude/fetch.sail, A/zaamo_insts.sail, Zicbo{zm}/zicbo{zm}_insts.sail].
function translateAddr(
  vAddr : virtaddr,
  access : MemoryAccessType(mem_payload),
) -> TR_Result(physaddr, Exception_Context) = {
  // Effective privilege takes into account mstatus.PRV, mstatus.MPP
  // See sys_control.sail for effectivePrivilege() and sys_regs.sail for cur_privilege.
  let effPriv = effectivePrivilege(access, mstatus, cur_privilege);
  translateAddr_eff_priv(vAddr, access, effPriv)
}

// ****************************************************************
// Initialize Virtual Memory state

// PUBLIC: invoked from reset() [postlude/model.sail]
function reset_vmem() -> unit = {
  // "If the hypervisor extension is implemented, the hgatp.MODE and vsatp.MODE fields are reset to 0."
  vsatp = zeros();
  hgatp = zeros();

  reset_TLB()
}

// ****************************************************************
