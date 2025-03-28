/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// ****************************************************************
// Virtual memory address translation and memory protection,
// including PTWs (Page Table Walks) and TLBs (Translation Look-aside Buffers)
// Supported VM modes: Sv32, Sv39, Sv48, Sv57

// STYLE NOTES:
//   PRIVATE items are used only within this VM code.
//   PUBLIC  items are invoked from other parts of sail-riscv.

// TLB NOTE:
// TLBs are not part of the RISC-V architecture specification.
// However, we model a simple TLB so that
// (1) we can meaningfully test SFENCE.VMA which is a no-op wihout TLBs;
// (2) we can greatly speed up simulation speed
//     (e.g., from 10s of minutes to few minutes for Linux boot)
// The TLB implementation is in a separate file: riscv_vmem_tlb.sail
// The code in this file is structured and commented so you can easily
// ignore TLB functionality at first reading.

struct PTW_Output('v : Int), is_sv_mode('v) = {
  ppn     : ppn_bits('v),
  pte     : pte_bits('v),
  pteAddr : physaddr,
  level   : level_range('v),
  global  : bool,
}

// PRIVATE
union PTW_Result('v : Int), is_sv_mode('v) = {
  PTW_Success : (PTW_Output('v), ext_ptw),
  PTW_Failure : (PTW_Error, ext_ptw),
}

// ****************************************************************
// Page Table Walk (PTW)

// Write a Page Table Entry.
function write_pte forall 'n, 'n in {4, 8} . (
  paddr    : physaddr,
  pte_size : int('n),
  pte      : bits('n * 8),
) -> MemoryOpResult(bool) =
  mem_write_value_priv(paddr, pte_size, pte, Supervisor, false, false, false)

// Read a Page Table Entry.
function read_pte forall 'n, 'n in {4, 8} . (
  paddr    : physaddr,
  pte_size : int('n),
) -> MemoryOpResult(bits(8 * 'n)) =
  mem_read_priv(Read(Data), Supervisor, paddr, pte_size, false, false, false)

// Update a PTE's A/D bits and write it to memory. This returns
//
// * Ok(Some(pte)) if a write was needed and was successful. pte is the new value.
// * Ok(None()) if no write was needed.
// * Err(e) if a write was needed but there was an error.
//
function update_pte forall 'pte_width, 'pte_width in {4, 8} . (
  pte_width : int('pte_width),
  pteAddr   : physaddr,
  pte       : bits('pte_width * 8),
  ac        : AccessType(ext_access_type),
) -> result(option(bits('pte_width * 8)), PTW_Error) =
  match updated_pte_bits(pte, ac) {
    None() => Ok(None()),
    Some(pte) =>
      if not(plat_enable_dirty_update()) then {
        // PTE needs dirty/accessed update but that is not enabled.
        Err(PTW_PTE_Update())
      } else {
        // Writeback the PTE (which has new A/D bits).
        match write_pte(pteAddr, pte_width, pte) {
          Ok(_) => Ok(Some(pte)),
          Err(_) => Err(PTW_Access()),
        }
      },
  }

// PRIVATE
// 'v is the virtual address size.
val pt_walk : forall 'v, is_sv_mode('v) . (
  int('v),                      // Sv32, Sv39, Sv48, Sv57
  vpn_bits('v),                 // Virtual Page Number
  AccessType(ext_access_type),  // Read/Write/ReadWrite/Execute
  Privilege,                    // User/Supervisor/Machine
  bool,                         // mstatus.MXR
  bool,                         // do_sum
  ppn_bits('v),                 // Base PPN (`a` in the spec).
  level_range('v),              // Tree level for this recursive call (`i` in the spec).
  bool,                         // global translation,
  ext_ptw                       // ext_ptw
) -> PTW_Result('v)

function pt_walk(
  sv_width,
  vpn,
  ac,
  priv,
  mxr,
  do_sum,
  pt_base,
  level,
  global,
  ext_ptw,
) = {
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
  let pte_addr = physaddr(zero_extend(pte_addr));

  // Read this-level PTE from mem
  match read_pte(pte_addr, 2 ^ log_pte_size_bytes) {
    Err(_)  => PTW_Failure(PTW_Access(), ext_ptw),
    Ok(pte) => {
      let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);
      let pte_ext   = ext_bits_of_PTE(pte);

      if pte_is_invalid(pte_flags, pte_ext) then
        PTW_Failure(PTW_Invalid_PTE(), ext_ptw)
      else {
        let ppn = PPN_of_PTE(pte); // 22 or 44.
        let global = global | (pte_flags[G] == 0b1);
        if pte_is_ptr(pte_flags) then {
          // Non-Leaf PTE
          if level > 0 then
            // follow the pointer to walk next level
            pt_walk(sv_width, vpn, ac, priv, mxr, do_sum, ppn, level - 1, global, ext_ptw)
          else
            // level 0 PTE, but contains a pointer instead of a leaf
            PTW_Failure(PTW_Invalid_PTE(), ext_ptw)
        } else {
          // Leaf PTE
          let pte_check = check_PTE_permission(ac, priv, mxr, do_sum, pte_flags,
                                               pte_ext, ext_ptw);
          match pte_check {
            PTE_Check_Failure(ext_ptw, ext_ptw_fail) =>
              PTW_Failure(ext_get_ptw_error(ext_ptw_fail), ext_ptw),
            PTE_Check_Success(ext_ptw) =>
              if level > 0 then {
                // Superpage. Check it is correctly aligned.
                let ppn_size_bits = if 'v == 32 then 10 else 9;
                let low_bits = ppn_size_bits * level;
                if ppn[low_bits - 1 .. 0] != zeros() then
                  PTW_Failure(PTW_Misaligned(), ext_ptw)
                else {
                  // Compose final PA in superpage:
                  // Superpage PPN @ lower VPNs @ page-offset
                  let ppn = ppn[length(ppn) - 1 .. low_bits] @ vpn[low_bits - 1 .. 0];
                  PTW_Success(struct { ppn=ppn, pte=pte, pteAddr=pte_addr, level=level, global=global}, ext_ptw)
                }
              } else {
                PTW_Success(struct { ppn=ppn, pte=pte, pteAddr=pte_addr, level=level, global=global}, ext_ptw)
              }
          }
        }
      }
    }
  }
}

// ****************************************************************
// Architectural SATP CSR

// PUBLIC: see also riscv_insts_zicsr.sail and other CSR-related files
register satp : xlenbits
mapping clause csr_name_map = 0x180  <-> "satp"
function clause is_CSR_defined(0x180) = extensionEnabled(Ext_S)
function clause read_CSR(0x180) = satp
function clause write_CSR(0x180, value) = { satp = legalize_satp(cur_architecture(), satp, value); satp }

// ----------------
// Fields of SATP

// ASID is 9b in Sv32, 16b in Sv39/Sv48/Sv57
// PRIVATE
val satp_to_asid : forall 'n, 'n in {32, 64}. bits('n) -> bits(if 'n == 32 then 9 else 16)
function satp_to_asid(satp_val) =
  if 'n == 32 then Mk_Satp32(satp_val)[Asid] else Mk_Satp64(satp_val)[Asid]

// PRIVATE
val satp_to_ppn : forall 'n, 'n in {32, 64}. bits('n) -> bits(if 'n == 32 then 22 else 44)
function satp_to_ppn(satp_val) =
  if 'n == 32 then Mk_Satp32(satp_val)[PPN] else Mk_Satp64(satp_val)[PPN]

// Compute address translation mode from SATP register
// PRIVATE
function translationMode(priv : Privilege) -> SATPMode = {
  if priv == Machine then Bare
  else {
    let arch = architecture(get_mstatus_SXL(mstatus));
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

// PUBLIC
union TR_Result('paddr : Type, 'failure : Type) = {
  TR_Address : ('paddr, ext_ptw),
  TR_Failure : ('failure, ext_ptw)
}

// This function can be ignored on first reading since TLBs are not
// part of RISC-V architecture spec (see TLB NOTE above).
// PRIVATE: translate on TLB hit, and maintenance of PTE in TLB
function translate_TLB_hit forall 'v, is_sv_mode('v) . (
  sv_width  : int('v),
  asid      : asidbits,
  vpn       : vpn_bits('v),
  ac        : AccessType(ext_access_type),
  priv      : Privilege,
  mxr       : bool,
  do_sum    : bool,
  ext_ptw   : ext_ptw,
  tlb_index : tlb_index_range,
  ent       : TLB_Entry,
) -> TR_Result(ppn_bits('v), PTW_Error) = {

  let pte_width = if sv_width == 32 then 4 else 8;
  let pte       = tlb_get_pte(pte_width, ent);
  let ext_pte   = ext_bits_of_PTE(pte);
  let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);
  let pte_check = check_PTE_permission(ac, priv, mxr, do_sum, pte_flags,
                                       ext_pte,
                                       ext_ptw);

  match pte_check {
    PTE_Check_Failure(ext_ptw, ext_ptw_fail) =>
      TR_Failure(ext_get_ptw_error(ext_ptw_fail), ext_ptw),
    PTE_Check_Success(ext_ptw) => {
      let ppn = tlb_get_ppn(sv_width, ent, vpn);
      match update_pte(pte_width, ent.pteAddr, pte, ac) {
        Ok(Some(pte)) => {
          write_TLB(tlb_index, tlb_set_pte(ent, pte));
          TR_Address(ppn, ext_ptw)
        },
        Ok(None()) => TR_Address(ppn, ext_ptw),
        Err(e) => TR_Failure(e, ext_ptw),
      }
    },
  }
}

// PRIVATE: translate on TLB miss (do a page-table walk)
function translate_TLB_miss forall 'v, is_sv_mode('v) . (
  sv_width : int('v),
  asid     : asidbits,
  base_ppn : ppn_bits('v),
  vpn      : vpn_bits('v),
  ac       : AccessType(ext_access_type),
  priv     : Privilege,
  mxr      : bool,
  do_sum   : bool,
  ext_ptw  : ext_ptw,
) -> TR_Result(ppn_bits('v), PTW_Error) = {
  let initial_level = if 'v == 32 then 1 else (if 'v == 39 then 2 else (if 'v == 48 then 3 else 4));

  let 'pte_width = if sv_width == 32 then 4 else 8;
  let ptw_result = pt_walk(sv_width, vpn, ac, priv, mxr, do_sum,
                           base_ppn, initial_level, false, ext_ptw);
  match ptw_result {
    PTW_Failure(f, ext_ptw) => TR_Failure(f, ext_ptw),
    PTW_Success(struct {ppn, pte, pteAddr, level, global}, ext_ptw) => {
      let ext_pte = ext_bits_of_PTE(pte);
      match update_pte(pte_width, pteAddr, pte, ac) {
        Ok(Some(pte)) => {
          add_to_TLB(sv_width, asid, vpn, ppn, pte, pteAddr, level, global);
          TR_Address(ppn, ext_ptw)
        },
        Ok(None()) => TR_Address(ppn, ext_ptw),
        Err(e) => TR_Failure(e, ext_ptw),
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

// PRIVATE
function translate forall 'v, is_sv_mode('v) . (
  sv_width : int('v),
  asid     : asidbits,
  base_ppn : ppn_bits('v),
  vpn      : vpn_bits('v),
  ac       : AccessType(ext_access_type),
  priv     : Privilege,
  mxr      : bool,
  do_sum   : bool,
  ext_ptw  : ext_ptw,
) -> TR_Result(ppn_bits('v), PTW_Error) = {
  // On first reading, assume lookup_TLB returns None(), since TLBs
  // are not part of RISC-V archticture spec (see TLB NOTE above)
  match lookup_TLB(sv_width, asid, vpn) {
    Some(index, ent) => translate_TLB_hit(sv_width, asid, vpn, ac, priv,
                                          mxr, do_sum, ext_ptw, index, ent),
    None()           => translate_TLB_miss(sv_width, asid, base_ppn, vpn, ac, priv,
                                           mxr, do_sum, ext_ptw),
  }
}

// SATP is represented in the model as an XLEN register (xlenbits), but it's
// actually SXLEN. That means if we are using Sv39 (which is only available when
// SXLEN is 32), then it must be a 32 bit register.
function get_satp forall 'v, is_sv_mode('v). (
  sv_width : int('v)
) -> bits(if 'v == 32 then 32 else 64) = {
  // Cannot use Sv39+ on RV32.
  assert('v == 32 | xlen == 64);
  if sv_width == 32 then satp[31 .. 0] else satp
}

// Top-level addr-translation function
// PUBLIC: invoked from instr-fetch and load/store/amo
function translateAddr(
  vAddr : virtaddr,
  ac    : AccessType(ext_access_type),
) -> TR_Result(physaddr, ExceptionType) = {

  // Effective privilege takes into account mstatus.PRV, mstatus.MPP
  // See riscv_sys_regs.sail for effectivePrivilege() and cur_privilege
  let effPriv = effectivePrivilege(ac, mstatus, cur_privilege);

  let mode = translationMode(effPriv);

  if mode == Bare then return TR_Address(physaddr(zero_extend(virtaddr_bits(vAddr))), init_ext_ptw);

  // Sv39 -> 39, etc.
  let sv_width = satp_mode_width(mode);

  // For Sv32 on RV64, satp is 32 bits (SXLEN), not XLEN.
  let satp_sxlen = get_satp(sv_width);

  // Cannot use Sv39+ on RV32.
  assert(sv_width == 32 | xlen == 64);

  let svAddr = virtaddr_bits(vAddr)[sv_width - 1 .. 0];
  if virtaddr_bits(vAddr) != sign_extend(svAddr) then {
    TR_Failure(translationException(ac, PTW_Invalid_Addr()), init_ext_ptw)
  } else {
    let mxr    = mstatus[MXR] == 0b1;
    let do_sum = mstatus[SUM] == 0b1;
    let asid = satp_to_asid(satp_sxlen);
    let base_ppn = satp_to_ppn(satp_sxlen);
    let res = translate(sv_width,
                        zero_extend(asid),
                        base_ppn,
                        svAddr[sv_width - 1 .. pagesize_bits],
                        ac, effPriv, mxr, do_sum,
                        init_ext_ptw);
    // Fixup result PA or exception
    match res {
      TR_Address(ppn, ext_ptw) => {
        // Append the page offset. This is now a 34 or 56 bit address.
        let paddr = ppn @ virtaddr_bits(vAddr)[pagesize_bits - 1 .. 0];

        // On RV64 paddr can be 34 or 56 bits, so we zero extend to 64.
        // On RV32 paddr can only be 34 bits. Sail knows this due to
        // the assertion above.
        TR_Address(physaddr(zero_extend(paddr)), ext_ptw)
      },
      TR_Failure(f, ext_ptw)  => TR_Failure(translationException(ac, f), ext_ptw)
    }
  }
}

// ****************************************************************
// Initialize Virtual Memory state

// PUBLIC: invoked from init_model()
function reset_vmem() -> unit = reset_TLB()

// ****************************************************************
