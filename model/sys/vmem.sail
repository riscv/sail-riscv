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

struct PTW_Output('v : Int), is_xv_mode('v) = {
  ppn     : ppn_bits('v),
  pte     : pte_bits('v),
  pteAddr : physaddr,
  level   : level_range('v),
  global  : bool,
}

private type PTW_Result('v : Int), is_xv_mode('v) = result((PTW_Output('v), ext_ptw), (PTW_Error, ext_ptw))

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

// ****************************************************************

type TR_Result('paddr : Type, 'failure : Type) = result(('paddr, ext_ptw), ('failure, ext_ptw))

private val translate_stage : (
  bits(64),                          // virtual address
  MemoryAccessType(mem_payload), // Read/Write/ReadWrite/Execute
  Privilege,                         // Machine/Supervisor/User
  AddressTranslationStage,           // S/VS/G
  ext_ptw,                           // ext_ptw
) -> TR_Result(physaddr, PTW_Error)

private function translate_PTE_addr forall 'v, is_xv_mode('v) . (
  sv_width : int('v),
  stage    : AddressTranslationStage,
  access   : MemoryAccessType(mem_payload),
  pte_addr : pte_addr_bits('v),
  ext_ptw  : ext_ptw
) -> TR_Result(physaddr, PTW_Error) = {
  let pa_bits : bits(physaddrbits_len) = match stage {
    Stage_VS => match translate_stage(zero_extend(pte_addr), access, User, Stage_G, ext_ptw) {
      Ok(pte_pa, ext_ptw) => (bits_of(pte_pa))[(sizeof(physaddrbits_len) - 1) .. 0],
      Err(f, ext_ptw) => return Err((PTW_Implicit(ptw_implicit_error(f), zero_extend(pte_addr), access), ext_ptw)),
    },
    _  => {
      assert(length(pte_addr) >= physaddrbits_len);
      pte_addr[(physaddrbits_len - 1) .. 0]
    },
  };
  Ok((Physaddr(pa_bits), ext_ptw))
}

// Steps 2-8 of the VATP.
// 'v is the virtual address size.
private function pt_walk forall 'v, is_xv_mode('v) .(
  sv_width : int('v),                           // Sv32(x4), Sv39(x4), Sv48(x4), Sv57(x4)
  vpn      : vpn_bits('v),                      // Virtual Page Number
  access   : MemoryAccessType(mem_payload),
  priv     : Privilege,
  stage    : AddressTranslationStage,
  mxr      : bool,                              // mstatus.MXR
  do_sum   : bool,                              // do_sum
  pt_base  : ppn_bits('v),                      // Base PPN
  level    : level_range('v),                   // Tree level for this recursive call (`i` in the spec).
  global   : bool,                              // global translation
  ext_ptw  : ext_ptw                            // ext_ptw
) -> PTW_Result('v) = {
  ptw_start_callback(zero_extend(vpn), access, (priv, ()));

  // Extract the PPN component for this level; 10 bits on Sv32, otherwise 9.
  let 'vpn_i_size = if 'v == 32 | 'v == 34 then 10 else 9;
  let 'log_pte_size_bytes = if 'v == 32 | 'v == 34 then 2 else 3;
  let 'vpn_extened = if 'v == 34 | 'v == 41 | 'v == 50 | 'v == 59 then 1 else 0;

  // TODO: improve this
  let vpn_begin = level * vpn_i_size;
  let vpn_end = if 'v - pagesize_bits == (level + 1) * vpn_i_size + 2 // Svx4 root level
                then 'v - pagesize_bits - 1
                else (level + 1) * vpn_i_size - 1;
  // Address of PTE in page table. This is 34 bits for Sv32(x4), otherwise 56 bits.
  let pte_addr : pte_addr_bits('v) = (pt_base @ zeros(pagesize_bits))
    + zero_extend(vpn[vpn_end .. vpn_begin] @ zeros('log_pte_size_bytes));
  // TODO: Any method to move this check to type constraint?
  assert(length(pte_addr) == physaddrbits_len);

  // Read the PTE physical address
  let pte_pa : physaddr = match translate_PTE_addr(sv_width, stage, Load(Data), pte_addr, ext_ptw) {
    Ok(pa, _) => pa,
    Err(e) => return Err(e),
  };

  match read_pte(pte_pa, 2 ^ log_pte_size_bytes) {
    Err(_)  => {
      ptw_fail_callback(PTW_No_Access(), level, pte_addr[physaddrbits_len - 1 .. 0]);
      Err(PTW_No_Access(), ext_ptw)
    },
    Ok(pte) => {
      ptw_step_callback(level, pte_addr[physaddrbits_len - 1 .. 0], zero_extend(pte));

      let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);
      let pte_ext   = ext_bits_of_PTE(pte);

      if pte_is_invalid(pte_flags, pte_ext) then {
        // Step 3 of VATP.
        ptw_fail_callback(PTW_Invalid_PTE(), level, pte_addr[physaddrbits_len - 1 .. 0]);
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
            pt_walk(sv_width, vpn, access, priv, stage, mxr, do_sum, ppn, level - 1, global, ext_ptw)
          else {
            // level 0 PTE, but contains a pointer instead of a leaf
            ptw_fail_callback(PTW_Invalid_PTE(), level, pte_addr[physaddrbits_len - 1 .. 0]);
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
              ptw_fail_callback(PTW_Misaligned(), level, pte_addr[physaddrbits_len - 1 .. 0]);
              return Err(PTW_Misaligned(), ext_ptw);
            };
          };
          // Steps 6, 7 (TODO: shadow stack protection), 8 of VATP.
          match check_PTE_permission(access, priv, mxr, do_sum, pte_flags, pte_ext, ext_ptw) {
            PTE_Check_Failure(ext_ptw, pte_failure) => {
              ptw_fail_callback(ext_get_ptw_error(pte_failure), level, pte_addr[physaddrbits_len - 1 .. 0]);
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

              Ok(struct {ppn=ppn, pte=pte, pteAddr=Physaddr(pte_addr[physaddrbits_len - 1 .. 0]), level=level, global=global}, ext_ptw)
            }
          }
        }
      }
    }
  }
}

termination_measure pt_walk(_,_,_,_,_,_,_,_,level,_,_) = level

// ****************************************************************
// Architectural SATP/HGATP CSR

register satp : xlenbits
mapping clause csr_name_map = 0x180  <-> "satp"
function clause is_CSR_accessible(0x180, priv, _) = currentlyEnabled(Ext_S) & not(priv == Supervisor & mstatus[TVM] == 0b1)
function clause read_CSR(0x180) = satp
function clause write_CSR(0x180, value) = { satp = legalize_satp(architecture(Supervisor), satp, value); Ok(satp) }
function clause write_CSR(0x180, value) =
  if privLevel_is_virtual(cur_privilege) then {
    vsatp = legalize_satp(architecture(VirtualSupervisor), vsatp, value); Ok(vsatp)
  } else {
    satp = legalize_satp(architecture(Supervisor), satp, value); Ok(satp)
  }

register hgatp : xlenbits
mapping clause csr_name_map = 0x680  <-> "hgatp"
function clause is_CSR_accessible(0x680, _, _) = currentlyEnabled(Ext_H)
function clause read_CSR(0x680) = hgatp
function clause write_CSR(0x680, value) = { hgatp = legalize_hgatp(architecture(VirtualSupervisor), hgatp, value); Ok(hgatp) }

// ----------------
// Fields of SATP/HGATP

// ASID is 9b in Sv32, 16b in Sv39/Sv48/Sv57
private function xsatp_to_asid forall 'n, 'n in {32, 64} . (satp_val : bits('n)) -> bits(if 'n == 32 then 9 else 16) =
  if 'n == 32 then Mk_Satp32(satp_val)[Asid] else Mk_Satp64(satp_val)[Asid]

private function vsatp_to_asid forall 'n, 'n in {32, 64} . (vsatp_val : bits('n)) -> bits(if 'n == 32 then 9 else 16) =
  if 'n == 32 then Mk_Satp32(vsatp_val)[Asid] else Mk_Satp64(vsatp_val)[Asid]

private function hgatp_to_mode forall 'n, 'n in {32, 64} . (satp_val : bits('n)) -> bits(if 'n == 32 then 1 else 4) =
  if 'n == 32 then Mk_Hgatp32(satp_val)[Mode] else Mk_Hgatp64(satp_val)[Mode]

// VMID is 7b in Sv32x4, 14b in Sv39x4/Sv48x4/Sv57x4: we use 14b for both
private function hgatp_to_vmid forall 'n, 'n in {32, 64}. (hgatp_val : bits('n)) -> bits(if 'n == 32 then 7 else 14) = {
   if 'n == 32 then Mk_Hgatp32(hgatp_val)[Vmid] else Mk_Hgatp64(hgatp_val)[Vmid]
}

private function satp_to_ppn forall 'n, 'n in {32, 64} . (satp_val : bits('n)) -> bits(if 'n == 32 then 22 else 44) =
  if 'n == 32 then Mk_Satp32(satp_val)[PPN] else Mk_Satp64(satp_val)[PPN]

private function vsatp_to_ppn forall 'n, 'n in {32, 64} . (vsatp_val : bits('n)) -> bits(if 'n == 32 then 22 else 44) =
  if 'n == 32 then Mk_Satp32(vsatp_val)[PPN] else Mk_Satp64(vsatp_val)[PPN]

// Result is 64b to cover both RV32 and RV64 addresses
private function hgatp_to_ppn forall 'n, 'n in {32, 64}. (hgatp_val : bits('n)) -> bits(if 'n == 32 then 22 else 44) =
  if 'n == 32 then Mk_Hgatp32(hgatp_val)[PPN] else Mk_Hgatp64(hgatp_val)[PPN]

// ****************************************************************
// Applicable address translation mode

// Compute address translation mode from SATP/HGATP register
private function translationMode(priv : Privilege, stage : AddressTranslationStage) -> XATPMode = {
  // For S- & G-stage, translation mode is based on mstatus.SXL
  // For VS-stage, translation mode is based on hstatus.VSXL
  let arch : Architecture = match stage {
    Stage_VS => architecture(VirtualSupervisor),
    _        => architecture(Supervisor),
  };

  let mode =
    if priv == Machine then
      Some(Bare)
    else match (stage, arch, xlen) {
      (Stage_S,  RV32,  _) => satpMode_of_bits(RV32, zero_extend(Mk_Satp32(satp[31 .. 0])[Mode])),
      (Stage_S,  RV64, 64) => satpMode_of_bits(RV64, Mk_Satp64(satp)[Mode]),
      (Stage_VS, RV32,  _) => satpMode_of_bits(RV32, zero_extend(Mk_Satp32(vsatp[31 .. 0])[Mode])),
      (Stage_VS, RV64, 64) => satpMode_of_bits(RV64, Mk_Satp64(vsatp)[Mode]),

      (Stage_G,  RV32,  _) => hgatp64Mode_of_bits(RV32, zero_extend(Mk_Hgatp32(hgatp[31 .. 0])[Mode])),
      (Stage_G,  RV64, 64) => hgatp64Mode_of_bits(RV64, Mk_Hgatp64(hgatp)[Mode]),

      _                    => internal_error(__FILE__, __LINE__, "unsupported address translation arch")
    };

  match mode {
      Some(m) => m,
      None()  => internal_error(__FILE__, __LINE__, "invalid translation mode in xatp")
  }
}

// ****************************************************************
// VA to PA translation

// Translate on TLB hit, and maintenance of PTE in TLB
// This function can be ignored on first reading since TLBs are not
// part of RISC-V architecture spec (see TLB NOTE above).
private function translate_TLB_hit forall 'v, is_xv_mode('v) . (
  sv_width  : int('v),
  _asid     : xxidbits,
  vpn       : vpn_bits('v),
  access    : MemoryAccessType(mem_payload),
  priv      : Privilege,
  stage     : AddressTranslationStage,
  mxr       : bool,
  do_sum    : bool,
  ext_ptw   : ext_ptw,
  tlb_index : tlb_index_range,
  ent       : TLB_Entry,
) -> TR_Result(ppn_bits('v), PTW_Error) = {

  let pte_size  = if sv_width == 32 | sv_width == 34 then 4 else 8;
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
            write_TLB(tlb_index, tlb_set_pte(ent, pte'), stage);
            let pte_pa : physaddr = match translate_PTE_addr(sv_width, stage, Store(Data), bits_of(ent.pteAddr)[(if 'v == 32 | 'v == 34 then 34 else 56) - 1 .. 0], ext_ptw) {
              Ok(pa, _) => pa,
              Err(e) => return Err(e),
            };
            match write_pte(pte_pa, pte_size, pte') {
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
private function translate_TLB_miss forall 'v, is_xv_mode('v) . (
  sv_width : int('v),
  asid     : xxidbits,
  base_ppn : ppn_bits('v),
  vpn      : vpn_bits('v),
  access   : MemoryAccessType(mem_payload),
  priv     : Privilege,
  stage    : AddressTranslationStage,
  mxr      : bool,
  do_sum   : bool,
  ext_ptw  : ext_ptw,
) -> TR_Result(ppn_bits('v), PTW_Error) = {
  let initial_level = if 'v == 32 | 'v == 34 then 1 else (if 'v == 39 | 'v == 41 then 2 else (if 'v == 48 | 'v == 50 then 3 else 4));
  // Step 2 of VATP occurs in pt_walk().
  let 'pte_size = if sv_width == 32 | sv_width == 34 then 4 else 8;
  let ptw_result = pt_walk(sv_width, vpn, access, priv, stage, mxr, do_sum,
                           base_ppn, initial_level, false, ext_ptw);
  match ptw_result {
    Err(f, ext_ptw) => {
      Err(f, ext_ptw)
    },
    Ok(struct {ppn, pte, pteAddr, level, global}, ext_ptw) => {
      let ext_pte = ext_bits_of_PTE(pte);
      // Without TLBs, this 'match' expression can be replaced simply
      // by: 'Ok(ppn, ext_ptw)'    (see TLB NOTE above)
      match update_PTE_Bits(pte, access) {
        None() => {
          add_to_TLB(sv_width, asid, stage, vpn, ppn, pte, pteAddr, level, global);
          Ok(ppn, ext_ptw)
        },
        Some(pte) => {
          // Step 9 of VATP. See platform.sail.
          if not(plat_enable_dirty_update) then
            // pte needs dirty/accessed update but that is not enabled
            Err(PTW_PTE_Needs_Update(), ext_ptw)
          else {
            let pte_pa : physaddr = match translate_PTE_addr(sv_width, stage, Store(Data), bits_of(pteAddr)[(if 'v == 32 | 'v == 34 then 34 else 56) - 1 .. 0], ext_ptw) {
              Ok(pa, _) => pa,
              Err(e) => return Err(e),
            };
            // Writeback the PTE (which has new A/D bits)
            match write_pte(pte_pa, pte_size, pte) {
              Ok(_) => {
                add_to_TLB(sv_width, asid, stage, vpn, ppn, pte, pteAddr, level, global);
                Ok(ppn, ext_ptw)
              },
              Err(e) => Err(PTW_No_Access(), ext_ptw)
            }
          }
        }
      }
    }
  }
}

// Mapping the SATPMode to the width integer. Note there is also SvBare
// and it's an error to call this with SvBare.
mapping satp_mode_width : XATPMode <-> {32, 39, 48, 57} = {
  Sv32   <-> 32,
  Sv39   <-> 39,
  Sv48   <-> 48,
  Sv57   <-> 57,
}

mapping hgatp_mode_width : XATPMode <-> {34, 41, 50, 59} = {
  Sv32x4 <-> 34,
  Sv39x4 <-> 41,
  Sv48x4 <-> 50,
  Sv57x4 <-> 59,
}

mapping xatp_mode_width : XATPMode <-> {32, 39, 48, 57, 34, 41, 50, 59} = {
  Sv32   <-> 32,
  Sv39   <-> 39,
  Sv48   <-> 48,
  Sv57   <-> 57,
  Sv32x4 <-> 34,
  Sv39x4 <-> 41,
  Sv48x4 <-> 50,
  Sv57x4 <-> 59,
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

function get_vsatp forall 'v, is_sv_mode('v). (
  sv_width : int('v)
) -> bits(if 'v == 32 then 32 else 64) = {
  // Cannot use Sv39+ on RV32.
  assert('v == 32 | xlen == 64);
  if sv_width == 32 then vsatp[31 .. 0] else vsatp
}

function get_hgatp forall 'v, is_svx4_mode('v). (
  sv_width : int('v)
) -> bits(if 'v == 34 then 32 else 64) = {
  // Cannot use Sv39x4+ on RV32.
  assert('v == 34 | xlen == 64);
  if sv_width == 34 then hgatp[31 .. 0] else hgatp
}

private function translate forall 'v, is_xv_mode('v) . (
  stage    : AddressTranslationStage,
  sv_width : int('v),
  asid     : xxidbits,
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
  match lookup_TLB(sv_width, asid, vpn, stage) {
    Some(index, ent) => {
      translate_TLB_hit(sv_width, asid, vpn, access, priv, stage,
                                          mxr, do_sum, ext_ptw, index, ent)
    },
    None()           => {
      translate_TLB_miss(sv_width, asid, base_ppn, vpn, access, priv, stage,
                                           mxr, do_sum, ext_ptw)
    },
  }
}

// PRIVATE: perform address translation for a specific stage
// Note: translate_stage is used for translation of implicit accesses during page walk
//       => 'val' declaration should occur before 'function' definition of pt_walk,
//          the 'function' definition of translate_stage is further down in this file
// Translate VA -> PA (S-stage), VA -> GPA (VS-stage) or GPA -> SPA(G-stage)
function translate_stage(
  vAddr    : bits(64),                      // virtual address
  access   : MemoryAccessType(mem_payload), // Read/Write/ReadWrite/Execute
  priv     : Privilege,                     // Machine/Supervisor/User
  stage    : AddressTranslationStage,       // S/VS/G
  ext_ptw  : ext_ptw,                       // ext_ptw
) -> TR_Result(physaddr, PTW_Error) = {
  let mode = translationMode(priv, stage);
  if mode == Bare then return Ok(Physaddr(vAddr[physaddrbits_len - 1 .. 0]), init_ext_ptw);
  match stage {
    Stage_S => {
      // Sv39 -> 39, etc.
      let sv_width = satp_mode_width(mode);
      assert((xlen == 32 & sv_width == 32) | (xlen == 64 & sv_width != 32));
      let satp_sxlen = get_satp(sv_width);
      let svAddr = vAddr[sv_width - 1 .. 0];
      if vAddr != sign_extend(svAddr) then {
        // translationException(ac, stage, PTW_Invalid_Addr())
        return Err(PTW_Invalid_Addr(), init_ext_ptw);
      };

      let mxr    : bool     = mstatus[MXR] == 0b1;
      let do_sum : bool     = mstatus[SUM] == 0b1;
      let asid              = xsatp_to_asid(satp);

      // let ptb    : bits(64) = satp_to_PT_base(satp);
      let satp_sxlen = get_satp(sv_width);
      let base_ppn = satp_to_ppn(satp_sxlen);
      let res = translate(Stage_S,
                          sv_width,
                          zero_extend(asid),
                          base_ppn, // ptb
                          svAddr[sv_width - 1 .. pagesize_bits],
                          access,
                          priv,
                          mxr,
                          do_sum,
                          ext_ptw);

      // Fixup result PA or exception
      match res {
        Ok(ppn, ext_ptw) => {
          // Step 10 of VATP.
          // Append the page offset. This is now a 34 or 56 bit address.
          let paddr = ppn @ vAddr[pagesize_bits - 1 .. 0];

          // On RV64 paddr can be 34 or 56 bits, so we zero extend to 64.
          // On RV32 paddr can only be 34 bits. Sail knows this due to
          // the assertion above.
          Ok(Physaddr(zero_extend(paddr)), ext_ptw)
        },
        Err(f, ext_ptw)  => {
          Err(f, ext_ptw)
        }
      }
    },
    Stage_VS => {
      let sv_width = satp_mode_width(mode);
      assert((xlen == 32 & sv_width == 32) | (xlen == 64 & sv_width != 32));
      let vsatp_sxlen = get_vsatp(sv_width);
      let svAddr = vAddr[sv_width - 1 .. 0];
      if vAddr != sign_extend(svAddr) then {
        return Err(PTW_Invalid_Addr(), init_ext_ptw);
      };

      let mxr    : bool = mstatus[MXR] == 0b1 | vsstatus[MXR] == 0b1; // HS-level MXR overwrites VS-stage page protections
      let do_sum : bool = vsstatus[SUM] == 0b1;
      let asid          = vsatp_to_asid(vsatp);
      let base_ppn      = vsatp_to_ppn(vsatp_sxlen);
      let res = translate(Stage_VS,
                          sv_width,
                          zero_extend(asid),
                          base_ppn, // ptb
                          svAddr[sv_width - 1 .. pagesize_bits],
                          access,
                          priv,
                          mxr,
                          do_sum,
                          ext_ptw);
      // Fixup result PA or exception
      match res {
        Ok(ppn, ext_ptw) => {
          // Step 10 of VATP.
          // Append the page offset. This is now a 34 or 56 bit address.
          let paddr = ppn @ vAddr[pagesize_bits - 1 .. 0];
          // On RV64 paddr can be 34 or 56 bits, so we zero extend to 64.
          // On RV32 paddr can only be 34 bits. Sail knows this due to
          // the assertion above.
          Ok(Physaddr(zero_extend(paddr)), ext_ptw)
        },
        Err(f, ext_ptw)  => {
          Err(f, ext_ptw)
        }
      }
    },
    Stage_G => {
      let sv_width = hgatp_mode_width(mode);
      assert((xlen == 32 & sv_width == 34) | (xlen == 64 & sv_width != 34));
      let hgatp_sxlen = get_hgatp(sv_width);
      let svAddr = vAddr[sv_width - 1 .. 0];
      if vAddr != zero_extend(svAddr) then {
        return Err(PTW_Invalid_Addr(), init_ext_ptw);
      };

      let mxr    : bool     = mstatus[MXR] == 0b1;
      let do_sum : bool     = mstatus[SUM] == 0b1;
      let vmid   : bits(16) = zero_extend(hgatp_to_vmid(hgatp));
      let ptb               = hgatp_to_ppn(hgatp_sxlen);
      let res = translate(Stage_G,
                          sv_width,
                          vmid,
                          ptb,
                          svAddr[sv_width - 1 .. pagesize_bits],
                          access,
                          // All G-stage memory accesses are considered User-level
                          User,
                          mxr,
                          do_sum,
                          ext_ptw);
      // Fixup result PA or exception
      match res {
        Ok(ppn, ext_ptw) => {
          // Step 10 of VATP.
          // Append the page offset. This is now a 34 or 56 bit address.
          let paddr = ppn @ vAddr[pagesize_bits - 1 .. 0];

          // On RV64 paddr can be 34 or 56 bits, so we zero extend to 64.
          // On RV32 paddr can only be 34 bits. Sail knows this due to
          // the assertion above.
          Ok(Physaddr(zero_extend(paddr)), ext_ptw)
        },
        Err(f, ext_ptw)  => {
          Err(f, ext_ptw)
        }
      }
    },
  }
}


// Addr-translation function for specific privilege & virtualization mode
// Invoked from HLV, HSV and HLVX
function translateAddr_pv(
  vAddr  : virtaddr,
  access : MemoryAccessType(mem_payload),
  priv   : Privilege
) -> TR_Result(physaddr, (ExceptionType, ExceptionContext)) = {

  let start_is_virt = privLevel_is_virtual(priv);
  let stage = if start_is_virt then {
    Stage_VS
  } else {
    Stage_S
  };
  let vAddr = zero_extend(64, bits_of(vAddr));

  let res = translate_stage(vAddr, access, priv, stage, init_ext_ptw);

  if not(start_is_virt) then match res {
    Ok(pa, ext_ptw) => Ok(pa, ext_ptw),
    Err(e, ext_ptw) => Err((translationException(access, Stage_S, e), translationExcContext(e, vAddr, false)), ext_ptw)
  } else match res {
    Ok(gpa, ext_ptw) => match translate_stage(zero_extend(bits_of(gpa)), access, priv, Stage_G, ext_ptw) {
      Ok(spa, ext_ptw) => Ok(spa, ext_ptw),
      Err(e, ext_ptw) => Err(
        (translationException(access, Stage_G, e),
          { translationExcContext(e, vAddr, true) with excinfo2 = Some(zero_extend(bits_of(gpa)[physaddrbits_len - 1 .. 2])) }
        ),
        ext_ptw
      ),
    },
    Err(e, ext_ptw) => Err((translationException(access, Stage_VS, e), translationExcContext(e, vAddr, true)), ext_ptw),
  }
}

// Top-level addr-translation function
// Invoked from instr-fetch and load/store/amo
function translateAddr(
  vAddr  : virtaddr,
  access : MemoryAccessType(mem_payload),
) -> TR_Result(physaddr, (ExceptionType, ExceptionContext)) = {

  // Effective privilege takes into account mstatus.PRV, mstatus.MPP
  // See sys_regs.sail for effectivePrivilege() and cur_privilege
  let effPriv = effectivePrivilege(access, mstatus, cur_privilege);
  translateAddr_pv(vAddr, access, effPriv)
}

// ****************************************************************

// PUBLIC: invoked from reset() [postlude/model.sail]
function reset_vmem() -> unit = reset_TLB()

// ****************************************************************
