// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// TODO: Rewrite this paragraph
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
  global  : bool,
}

private type PTW_Result('v : Int), is_sv_or_svx4_mode('v) = result((PTW_Output('v), ext_ptw), (PTW_Error, ext_ptw))

// Result of address translation

type TR_Result('paddr : Type, 'failure : Type) = result(('paddr, ext_ptw), ('failure, ext_ptw))

// TODO: Remove this forward declaration and restructure code.
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
  mem_write_value_priv(paddr, pte_size, pte, Supervisor, false, false, false)

// Read a Page Table Entry.
private function read_pte forall 'n, 'n in {4, 8} . (
  paddr    : physaddr,
  pte_size : int('n),
) -> MemoryOpResult(bits(8 * 'n)) =
  mem_read_priv(Load(Data), Supervisor, paddr, pte_size, false, false, false)

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
      Ok(pa, ext_ptw) => Ok(Physaddr(pa), ext_ptw),
      Err(f, ext_ptw) => Err(f, ext_ptw),
    }
  } else {
    Ok(Physaddr(pte_addr), ext_ptw)
  }
}

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

  let 'vpn_i_size = if ('v == 32 | 'v == 34) then 10 else 9;
  let 'log_pte_size_bytes = if ('v == 32 | 'v == 34) then 2 else 3;

  // Root level depends on the mode
  let root_level = if ('v == 32 | 'v == 34) then 1
                   else if ('v == 39 | 'v == 41) then 2
                   else if ('v == 48 | 'v == 50) then 3
                   else 4;

  // Svx4 root level has 2 extra bits
  let is_svx4_root = ('v == 34 | 'v == 41 | 'v == 50 | 'v == 59) & (level == root_level);

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

  // Translate PTE address if performing a VS-stage access
  let pte_addr : physaddr = match translate_PTE_addr(zero_extend(pte_addr), access, stage, ext_ptw) {
    Ok(pa, _)   => pa,
    Err((e, _)) => return Err(PTW_Implicit_Error(translationException(access, e), zero_extend(pte_addr)), ext_ptw),
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

      if pte_is_invalid(pte_flags, pte_ext) then {
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
          let ppn_size_bits = if 'v == 32 | 'v == 34 then 10 else 9;
          if level > 0 then {
            // Check for misaligned superpage.
            let low_bits = ppn_size_bits * level;
            if   ppn[low_bits - 1 .. 0] != zeros()
            then {
              ptw_fail_callback(PTW_Misaligned(), level, bits_of(pte_addr));
              return Err(PTW_Misaligned(), ext_ptw);
            };
          };
          // Steps 6, 7 (TODO: shadow stack protection), 8 of VATP.
          match check_PTE_permission(access, priv, mxr, do_sum, pte_flags, pte_ext, ext_ptw) {
            PTE_Check_Failure(ext_ptw, pte_failure) => {
              ptw_fail_callback(ext_get_ptw_error(pte_failure), level, bits_of(pte_addr));
              Err(ext_get_ptw_error(pte_failure), ext_ptw)
            },
            PTE_Check_Success(ext_ptw) => {
              let ppn = if level > 0 then {
                // Compose final PA in superpage:
                // Superpage PPN @ lower VPNs @ page-offset
                let low_bits = ppn_size_bits * level;
                ppn[length(ppn) - 1 .. low_bits] @ vpn[low_bits - 1 .. 0]
              } else {
                ppn
              };
              ptw_success_callback(zero_extend(ppn), level);

              Ok(struct {ppn=ppn, pte=pte, pteAddr=pte_addr, level=level, global=global}, ext_ptw)
            }
          }
        }
      }
    }
  }
}

termination_measure pt_walk(_,_,_,_,_,_,_,level,_,_, _) = level

// ****************************************************************
// Architectural SATP CSR

register satp : xlenbits
mapping clause csr_name_map = 0x180  <-> "satp"

function clause is_CSR_accessible(0x180, priv, _) = {
  if not(currentlyEnabled(Ext_S)) then false
  else if priv == Supervisor & mstatus[TVM] == 0b1 then false
  // TODO: VS-mode with VTVM=1 should raise virtual instruction
  // not illegal instruction. Needs refactoring of CSR access logic.
  else if inVirtualPrivilege() & hstatus[VTVM] == 0b1 then false
  else true
}

function clause read_CSR(0x180) = if inVirtualPrivilege() then vsatp else satp

function clause write_CSR(0x180, value) = {
  let arch = architecture(cur_privilege);
  if inVirtualPrivilege() then {
    vsatp = legalize_satp(arch, vsatp, value);
    Ok(vsatp)
  } else {
    satp = legalize_satp(arch, satp, value);
    Ok(satp)
  }
}

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

function get_vmid(stage : TranslationStage) -> vmidbits = {
  match stage {
    S_Stage => zeros(),
    _       => if xlen == 32 then Mk_Hgatp32(hgatp)[VMID] else Mk_Hgatp64(hgatp)[VMID],
  }
}

private function xatp_to_ppn(stage : TranslationStage) -> bits(if xlen == 32 then 22 else 44) = {
  match stage {
    S_Stage  => if xlen == 32 then Mk_Satp32(satp)[PPN]   else Mk_Satp64(satp)[PPN],
    VS_Stage => if xlen == 32 then Mk_Satp32(vsatp)[PPN]  else Mk_Satp64(vsatp)[PPN],
    G_Stage  => if xlen == 32 then Mk_Hgatp32(hgatp)[PPN] else Mk_Hgatp64(hgatp)[PPN],
  }
}

// Compute address translation mode from SATP register
private function translationMode(priv : Privilege) -> SATPMode = {
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

// S-stage (HS-mode uses satp)
function satp_mode(priv : Privilege) -> SATPMode = {
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

// VS-stage (VS-mode uses vsatp)
function vsatp_mode(priv : Privilege) -> SATPMode = {
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

// G-stage (HS-mode used for 2-stage addresses translation uses hgatp)
function hgatp_mode(priv : Privilege) -> HGATPMode = {
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
  _stage    : TranslationStage,
  ext_ptw   : ext_ptw,
) -> TR_Result(ppn_bits('v), PTW_Error) = {

  let pte_size  = if (sv_width == 32 | sv_width == 34) then 4 else 8;
  let pte       = tlb_get_pte(pte_size, ent);  // Step 2 of VATP.
  let ext_pte   = ext_bits_of_PTE(pte);
  let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);
  let pte_check = check_PTE_permission(access, priv, mxr, do_sum, pte_flags,
                                       ext_pte, ext_ptw);

  match pte_check {
    PTE_Check_Failure(ext_ptw, pte_failure) =>
      Err(ext_get_ptw_error(pte_failure), ext_ptw),
    PTE_Check_Success(ext_ptw) =>
      match update_PTE_Bits(pte, access) {
        None()     => Ok(tlb_get_ppn(sv_width, ent, vpn), ext_ptw),
        Some(pte') =>
          // Step 9 of VATP. See platform.sail.
          if not(plat_enable_dirty_update) then
            // pte needs dirty/accessed update but that is not enabled
            Err(PTW_PTE_Needs_Update(), ext_ptw)
          else {
            // Writeback the PTE (which has new A/D bits)
            write_TLB(tlb_index, tlb_set_pte(ent, pte'));
            match write_pte(ent.pteAddr, pte_size, pte') {
              Ok(_)  => (),
              Err(_) => internal_error(__FILE__, __LINE__,
                                       "invalid physical address in TLB")
            };
            Ok(tlb_get_ppn(sv_width, ent, vpn), ext_ptw)
          }
      }
  }
}

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
   let initial_level = if 'v == 32 | 'v == 34 then 1
                      else if 'v == 39 | 'v == 41 then 2
                      else if 'v == 48 | 'v == 50 then 3
                      else 4;

  // Step 2 of VATP occurs in pt_walk().
  let 'pte_size = if 'v == 32 | 'v == 34 then 4 else 8;
  let ptw_result = pt_walk(sv_width, vpn, access, priv, mxr, do_sum,
                           base_ppn, initial_level, false, stage, ext_ptw);
  match ptw_result {
    Err(f, ext_ptw) => Err(f, ext_ptw),
    Ok(struct {ppn, pte, pteAddr, level, global}, ext_ptw) => {
      let ext_pte = ext_bits_of_PTE(pte);
      // Without TLBs, this 'match' expression can be replaced simply
      // by: 'Ok(ppn, ext_ptw)'    (see TLB NOTE above)
      match update_PTE_Bits(pte, access) {
        None() => {
          add_to_TLB(sv_width, asid, vmid, vpn, ppn, pte, pteAddr, level, global, stage);
          Ok(ppn, ext_ptw)
        },
        Some(pte) =>
          // Step 9 of VATP. See platform.sail.
          if not(plat_enable_dirty_update) then
            // pte needs dirty/accessed update but that is not enabled
            Err(PTW_PTE_Needs_Update(), ext_ptw)
          else {
            // Writeback the PTE (which has new A/D bits)
            match write_pte(pteAddr, pte_size, pte) {
              Ok(_) => {
                add_to_TLB(sv_width, asid, vmid, vpn, ppn, pte, pteAddr, level, global, stage);
                Ok(ppn, ext_ptw)
              },
              Err(_) =>
                Err(PTW_No_Access(), ext_ptw)
            }
          }
        }
      }
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

// NOTE: Currently unused
function get_xatp forall 'v, is_sv_mode('v). (
  sv_width : int('v),
  stage    : TranslationStage
) -> bits(if 'v == 32 | 'v == 34 then 32 else 64) = {
  match stage {
    S_Stage => {
      assert('v != 34 & ('v == 32 | xlen == 64));
      if sv_width == 32 then satp[31 .. 0] else satp
    },
    VS_Stage => {
      assert('v != 34 & ('v == 32 | xlen == 64));
      if sv_width == 32 then vsatp[31 .. 0] else vsatp
    },
    G_Stage => {
      assert('v != 32 & ('v == 34 | xlen == 64));
      if sv_width == 34 then hgatp[31 .. 0] else hgatp
    },
  }
}

private function get_mxr(stage :TranslationStage) -> bool = {
  match stage {
    VS_Stage => mstatus[MXR] == 0b1 | vsstatus[MXR] == 0b1,
    _ => mstatus[MXR] == 0b1,
  }
}

private function get_sum(stage : TranslationStage) -> bool = {
  match stage {
    VS_Stage => vsstatus[SUM] == 0b1,
    _ => mstatus[SUM] == 0b1,
  }
}

val validate_vs_input : forall 'v, is_sv_mode('v). (
  xlenbits,
  int('v),
) -> result(bits('v), PTW_Error)

function validate_vs_input(addr, sv_width) = {
  assert('v <= xlen);
  let truncated = truncate(addr, sv_width);
  if addr == sign_extend(truncated)
  then Ok(truncated)
  else Err(PTW_Invalid_Addr())
}

val validate_g_input : forall 'v, is_svx4_mode('v). (
  gpabits,
  int('v),
) -> result(bits('v), PTW_Error)

function validate_g_input(addr, sv_width) = {
  assert('v <= gpalen);
  let truncated = truncate(addr, sv_width);
  if addr == zero_extend(truncated)
  then Ok(truncated)
  else Err(PTW_Invalid_Addr())
}

private function translate_stage forall 'v, is_sv_or_svx4_mode('v). (
  sv_width : int('v),
  addr     : bits('v),
  access   : MemoryAccessType(mem_payload),
  priv     : Privilege,
  stage    : TranslationStage
) -> TR_Result(gpabits, PTW_Error) = {

  assert((xlen == 32 & (sv_width == 32 | sv_width == 34)) |
         (xlen == 64 &  sv_width != 32 & sv_width != 34));

  let asid     = get_asid(stage);
  let vmid     = get_vmid(stage);
  let vpn      = addr[sv_width - 1 .. pagesize_bits];
  let mxr      = get_mxr(stage);
  let do_sum   = get_sum(stage);
  let base_ppn = xatp_to_ppn(stage);
  let eff_priv = if stage == G_Stage then User else priv;

  let res = translate(sv_width, asid, vmid, base_ppn, vpn,
                      access, eff_priv, mxr, do_sum, stage, init_ext_ptw);

  match res {
    Ok(ppn, ext_ptw) => {
      let pa = ppn @ addr[pagesize_bits - 1 .. 0];
      Ok(zero_extend(pa), ext_ptw)
    },
    Err(f, ext_ptw) => Err(f, ext_ptw)
  }
}

// Wrapper for VS/S-stage translation (takes virtaddr)
function translate_vs_stage(
  vaddr  : virtaddr,
  access : MemoryAccessType(mem_payload),
  p      : Privilege
) -> TR_Result(gpabits, PTW_Error) = {
  let stage = if inVirtualPrivilege() then VS_Stage else S_Stage;
  let mode  = if inVirtualPrivilege() then vsatp_mode(p) else satp_mode(p);

  if mode == Bare then return Ok(zero_extend(bits_of(vaddr)), init_ext_ptw);

  let sv_width = satp_mode_width(mode);
  match validate_vs_input(bits_of(vaddr), sv_width) {
    Err(e)       => Err(e, init_ext_ptw),
    Ok(valid_va) => translate_stage(sv_width, valid_va, access, p, stage),
  }
}

// Wrapper for G-stage translation (takes physaddr)
function translate_g_stage(
  gpa    : gpabits,
  access : MemoryAccessType(mem_payload),
  p      : Privilege
) -> TR_Result(gpabits, PTW_Error) = {
  let mode = hgatp_mode(p);

  if mode == HBare then return Ok(gpa, init_ext_ptw);

  let sv_width = hgatp_mode_width(mode);
  match validate_g_input(gpa, sv_width) {
    Err(e)        => Err(e, init_ext_ptw),
    Ok(valid_gpa) => translate_stage(sv_width, valid_gpa, access, p, G_Stage),
  }
}

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
        tval  = zero_extend(bits_of(gva)),
        tval2 = zeros(),
        is_gstage_fault = false,
      }
    },
    VS_Stage => {
      match ptw_error {
        PTW_Implicit_Error(e, pte_addr) => {
          // Implicit VS-Stage failure
          struct {
            trap  = convertToGuestException(e),
            tval  = zero_extend(bits_of(gva)),
            tval2 = truncate(pte_addr >> 2, xlen),
            is_gstage_fault = true
          }
        },
        _ => {
          // Explicit VS-Stage failure
          struct {
            trap  = translationException(access, ptw_error),
            tval  = zero_extend(bits_of(gva)),
            tval2 = zeros(),
            is_gstage_fault = false
          }
        }
      }
    },
    G_Stage => {
      // G-Stage failure
      struct {
        trap  = convertToGuestException(translationException(access, ptw_error)),
        tval  = zero_extend(bits_of(gva)),
        tval2 = truncate(gpa >> 2, xlen),
        is_gstage_fault = true
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
  let is_virtual = inVirtualPrivilege();
  // First stage: GVA -> GPA (or VA -> PA for single-stage)
  match translate_vs_stage(gva, access, p) {
    Ok(gpa, ext_ptw) => {
      if not(is_virtual) then {
        return Ok(Physaddr(gpa), ext_ptw)
      };
      // Second stage: GPA -> SPA
      match translate_g_stage(gpa, access, p) {
        Ok(spa, ext_ptw)        => Ok(Physaddr(spa), ext_ptw),
        // G-Stage failure
        Err(ptw_error, ext_ptw) => Err(build_exception_context(gva, gpa, access, ptw_error, G_Stage), ext_ptw)
      }
    },
    // S/VS-stage failure
    Err(ptw_error, ext_ptw) => Err(build_exception_context(gva, zeros(), access, ptw_error, if is_virtual then VS_Stage else S_Stage), ext_ptw)
  }
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
  // NOTE/TODO: translateAddr must return Exception_Context to properly handle traps.
  // To keep this PR size manageable, we stop here.
  match translateAddr_eff_priv(vAddr, access, effPriv) {
    Ok(pa, ext_ptw)      => Ok(pa, ext_ptw),
    Err(e_cont, ext_ptw) => Err(e_cont.trap, ext_ptw),
  }
}

// ****************************************************************
// Initialize Virtual Memory state

// PUBLIC: invoked from reset() [postlude/model.sail]
function reset_vmem() -> unit = reset_TLB()

// ****************************************************************
