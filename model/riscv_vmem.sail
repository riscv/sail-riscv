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

// ****************************************************************
// Virtual memory address translation and memory protection,
// including PTWs (Page Table Walks) and TLBs (Translation Look-aside Buffers)
// Supported VM modes: Sv32, Sv39, Sv48.  FUTURE: Sv57

// STYLE NOTES:
//   PRIVATE items are used only within this VM code.
//   PUBLIC  items are invoked from other parts of sail-riscv.

// TLB NOTE:
// TLBs are not part of the RISC-V architecture specification.
// However, we model a simple TLB so that
// (1) we can meaningfully test SFENCE.VMA which is a no-op wihout TLBs;
// (2) we can greatly speed up simulation speed
//     (e.g., from 10s or minutes to few minutes for Linux boot)
// The TLB implementation is in a separate file: riscv_vmem_tlb.sail
// The code in this file is structured and commented so you can easily
// ignore TLB functionality at first reading.

// ****************************************************************
// Parameters for VM modes sv32, sv39 and sv48

// All VM modes use the same page size (4KB, with 12-bit index)

let PAGESIZE_BITS : nat = 12

// PRIVATE
struct SV_Params = {
  // SATP CSR                            // Sv32  Sv39  Sv48
  satp_asid_size_bits : { 9, 16},        //    9    16    16
  satp_asid_lsb_index : {22, 44},        //   22    44    44
  // SATP PPN
  satp_ppn_size_bits  : {22, 44},        //   22    44    44
  satp_ppn_lsb_index  : { 0},            //    0     0     0

  // VA
  va_size_bits        : {32, 39, 48},    //   32    39    48
  vpn_size_bits       : {10,  9},        //   10     9     9

  // PTE
  levels              : { 2,  3,  4},    //    2     3     4
  log_pte_size_bytes  : { 2,  3},        //    2     3     3
  pte_msbs_lsb_index  : {32, 54},        //   32    54    54
  pte_msbs_size_bits  : { 0, 10},        //    0    10    10
  pte_PPNs_lsb_index  : {10},            //   10    10    10
  pte_PPNs_size_bits  : {22, 44},        //   22    44    44
  pte_PPN_j_size_bits : {10,  9}         //   10     9     9
}

// PRIVATE
let sv32_params : SV_Params = struct {
       // SATP CSR
       satp_asid_size_bits = 9,
       satp_asid_lsb_index = 22,

       // SATP PPN
       satp_ppn_size_bits  = 22,
       satp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 32,
       vpn_size_bits       = 10,

       // PTE
       levels              = 2,
       log_pte_size_bytes  = 2,    // 4 Bytes
       pte_msbs_lsb_index  = 32,
       pte_msbs_size_bits  = 0,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 22,
       pte_PPN_j_size_bits = 10
}

// PRIVATE
let sv39_params : SV_Params = struct {
       // SATP CSR
       satp_asid_size_bits = 16,
       satp_asid_lsb_index = 44,

       // SATP PPN
       satp_ppn_size_bits  = 44,
       satp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 39,
       vpn_size_bits       = 9,

       // PTE
       levels              = 3,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}

// PRIVATE
let sv48_params : SV_Params = struct {
       // SATP CSR
       satp_asid_size_bits = 16,
       satp_asid_lsb_index = 44,

       // SATP PPN
       satp_ppn_size_bits  = 44,
       satp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 48,
       vpn_size_bits       = 9,

       // PTE
       levels              = 4,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}

// For future; not currently used
// PRIVATE
/*
let sv57_params : SV_Params = struct {
       // SATP CSR
       satp_asid_size_bits = 16,
       satp_asid_lsb_index = 44,

       // SATP PPN
       satp_ppn_size_bits  = 44,
       satp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 57,
       vpn_size_bits       = 9,

       // PTE
       levels              = 5,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}
*/

// PRIVATE
val      undefined_SV_Params : unit -> SV_Params

function undefined_SV_Params() = sv32_params

// ****************************************************************
// Fields of virtual addresses

// PRIVATE: Extract full VPN field from VA
function vpns_of_va(sv_params : SV_Params,
                    va        : bits(64)) -> bits(64) = {
    let mask : bits(64) = (zero_extend(0b1) << sv_params.va_size_bits) - zero_extend(0b1);
    (va & mask) >> PAGESIZE_BITS
}

// PRIVATE: Extract VPN[level] from  VA
function vpn_j_of_va(sv_params : SV_Params,
                     va        : bits(64),
                     level     : nat)       -> bits(64) = {
    let lsb  : nat       = PAGESIZE_BITS + level * sv_params.vpn_size_bits;
    let mask : bits(64) = (zero_extend(0b1) << sv_params.vpn_size_bits) - 1;
    ((va >> lsb) & mask)
}

// PRIVATE: Extract offset within page from VA
function offset_of_va(va : bits(64)) -> bits(64) = {
    let mask : bits(64) = (zero_extend(0b1) << PAGESIZE_BITS) - 1;
    va & mask
}

// Valid xlen-wide values containing virtual addrs must have upper
// bits equal to the MSB of the virtual address.
// Virtual address widths depend on the virtual memory mode.
// PRIVATE
function is_valid_vAddr(struct { va_size_bits, _ } : SV_Params,
                        vAddr                      : bits(64))  -> bool = {
  let index      = va_size_bits - 1;
  let upper_bits = vAddr[63 .. va_size_bits];
  let va_msb     = vAddr[index];
  if va_msb == bitzero then
    upper_bits == zeros()
  else
    upper_bits == ones()
}

// ****************************************************************
// PTE (Page Table Entry) in PTN (Page Table Node)

// PTE      MSBs      PPNs      RSW    BITs
// Sv32      -       31..10    9..8    7..0
// Sv39    63..54    53..10    9..8    7..0
// Sv48    63..54    53..10    9..8    7..0

// MSBs of PTE are reserved for RV64 extensions.
// There are no available bits on RV32, so these bits will be zeros on RV32.

// For PTW extensions (non-standard)
type extPte = bits(64)

// PRIVATE: extract msbs of PTE above the PPN
function msbs_of_PTE(sv_params : SV_Params, pte : bits(64)) -> bits(64) = {
  let mask : bits(64) = (zero_extend(0b1) << sv_params.pte_msbs_size_bits) - zero_extend(0b1);
  (pte >> sv_params.pte_msbs_lsb_index) & mask
}

// PRIVATE: extract PPNs of PTE
function PPNs_of_PTE(sv_params : SV_Params, pte : bits(64)) -> bits(64) = {
  let mask : bits(64) = (zero_extend(0b1) << sv_params.pte_PPNs_size_bits) - zero_extend(0b1);
  (pte >> sv_params.pte_PPNs_lsb_index) & mask
}

// PRIVATE: extract LSBs (including permissions) of PTE
function D_of_PTE(pte : bits(64)) -> bit = pte[7]
function A_of_PTE(pte : bits(64)) -> bit = pte[6]
function G_of_PTE(pte : bits(64)) -> bit = pte[5]
function U_of_PTE(pte : bits(64)) -> bit = pte[4]
function X_of_PTE(pte : bits(64)) -> bit = pte[3]
function W_of_PTE(pte : bits(64)) -> bit = pte[2]
function R_of_PTE(pte : bits(64)) -> bit = pte[1]
function V_of_PTE(pte : bits(64)) -> bit = pte[0]

// PRIVATE: check if a PTE is a pointer to next level (non-leaf)
function pte_is_ptr(pte : bits(64)) -> bool = {
  let x = X_of_PTE(pte);
  let w = W_of_PTE(pte);
  let r = R_of_PTE(pte);
  (x == bitzero) & (w == bitzero) & (r == bitzero)
}

// PRIVATE: check if a PTE is valid
function pte_is_invalid(pte : bits(64)) -> bool = {
  let w = W_of_PTE(pte);
  let r = R_of_PTE(pte);
  let v = V_of_PTE(pte);
  (v == bitzero) | ((w == bitone) & (r == bitzero))
}

// ----------------
// Check access permissions in PTE

// For (non-standard) extensions: this function gets the extension-available bits
// of the PTE in extPte, and the accumulated information of the page-table-walk
// in ext_ptw. It should return the updated ext_ptw in both success and failure cases.

union PTE_Check = {
  PTE_Check_Success : ext_ptw,
  PTE_Check_Failure : (ext_ptw, ext_ptw_fail)
}

// PRIVATE
function check_PTE_permission(ac      : AccessType(ext_access_type),
                              priv    : Privilege,
                              mxr     : bool,
                              do_sum  : bool,
                              pte_U   : bit,
                              pte_X   : bit,
                              pte_W   : bit,
                              pte_R   : bit,
                              ext     : extPte,
                              ext_ptw : ext_ptw) -> PTE_Check = {
  let b : bool =
    match (ac, priv) {
      (Read(_),         User)       => ((pte_U == bitone)
                                        & ((pte_R == bitone) | ((pte_X == bitone & mxr)))),
      (Write(_),        User)       => ((pte_U == bitone) & (pte_W == bitone)),
      (ReadWrite(_, _), User)       => ((pte_U == bitone)
                                        & (pte_W == bitone)
                                        & ((pte_R == bitone) | ((pte_X == bitone) & mxr))),
      (Execute(),       User)       => ((pte_U == bitone) & (pte_X == bitone)),
      (Read(_),         Supervisor) => (((pte_U == bitzero) | do_sum)
                                        & ((pte_R == bitone) | ((pte_X == bitone) & mxr))),
      (Write(_),        Supervisor) => (((pte_U == bitzero) | do_sum) & (pte_W == bitone)),
      (ReadWrite(_, _), Supervisor) => (((pte_U == bitzero) | do_sum)
                                        & (pte_W == bitone)
                                        & ((pte_R == bitone) | ((pte_X == bitone) & mxr))),
      (Execute(),       Supervisor) => ((pte_U == bitzero) & (pte_X == bitone)),
      (_,               Machine)    => internal_error(__FILE__, __LINE__,
                                                      "m-mode mem perm check")};
  if b then PTE_Check_Success(())
  else      PTE_Check_Failure((), ())
}

// Update PTE bits if needed; return new PTE if updated
// PRIVATE
function update_PTE_Bits(sv_params : SV_Params,
                         pte       : bits(64),
                         a         : AccessType(ext_access_type),
                         ext       : extPte)
                        -> option(bits(64)) = {
  // Update 'dirty' bit?
  let update_d = (D_of_PTE(pte) == bitzero)
                 & (match a {
                      Execute()       => false,
                      Read()          => false,
                      Write(_)        => true,
                      ReadWrite(_, _) => true
                    });
  // Update 'accessed'-bit?
  let update_a = A_of_PTE(pte) == bitzero;
  if update_d | update_a then {
    let pte1 = pte | (zero_extend(0b1) << 6);
    let pte2 = if update_d then (pte1 | (zero_extend(0b1) << 7)) else pte1;
    Some(pte2 | (ext << sv_params.pte_msbs_lsb_index))
  }
  else
    None()
}

// ****************************************************************
// Results of Page Table Walk (PTW)

// 'ext_ptw' supports (non-standard) extensions to the default addr-translation and PTW.

// Failure modes for address-translation/page-table-walks
// PRIVATE
union PTW_Error = {
  PTW_Invalid_Addr  : unit,          // invalid source address
  PTW_Access        : unit,          // physical memory access error for a PTE
  PTW_Invalid_PTE   : unit,
  PTW_No_Permission : unit,
  PTW_Misaligned    : unit,          // misaligned superpage
  PTW_PTE_Update    : unit,          // PTE update needed but not enabled
  PTW_Ext_Error     : ext_ptw_error  // parameterized for errors from extensions
}

// PRIVATE: only 'to_str' overload is public
function ptw_error_to_str(e : PTW_Error) -> string = {
  match e {
    PTW_Invalid_Addr()   => "invalid-source-addr",
    PTW_Access()         => "mem-access-error",
    PTW_Invalid_PTE()    => "invalid-pte",
    PTW_No_Permission()  => "no-permission",
    PTW_Misaligned()     => "misaligned-superpage",
    PTW_PTE_Update()     => "pte-update-needed",
    PTW_Ext_Error(e)     => "extension-error"
  }
}

// PUBLIC
overload to_str = {ptw_error_to_str}

// hook for (non-standard) extensions to customize errors reported by page-table
// walks during address translation; it typically works in conjunction
// with any customization to check_PTE_permission().

// PRIVATE
function ext_get_ptw_error(eptwf : ext_ptw_fail) -> PTW_Error =
  PTW_No_Permission()

// Convert translation/PTW failures into architectural exceptions
function translationException(a : AccessType(ext_access_type),
                              f : PTW_Error)
                             -> ExceptionType = {
  match (a, f) {
    (_, PTW_Ext_Error(e))        => E_Extension(ext_translate_exception(e)),
    (ReadWrite(_), PTW_Access()) => E_SAMO_Access_Fault(),
    (ReadWrite(_), _)            => E_SAMO_Page_Fault(),
    (Read(_), PTW_Access())      => E_Load_Access_Fault(),
    (Read(_), _)                 => E_Load_Page_Fault(),
    (Write(_), PTW_Access())     => E_SAMO_Access_Fault(),
    (Write(_), _)                => E_SAMO_Page_Fault(),
    (Execute(), PTW_Access())    => E_Fetch_Access_Fault(),
    (Execute(), _)               => E_Fetch_Page_Fault()
  }
}

// PRIVATE
union PTW_Result = {
  PTW_Success: (bits(64), bits(64), bits(64), nat, bool, ext_ptw),
  PTW_Failure: (PTW_Error, ext_ptw)
}

// ****************************************************************
// Page Table Walk (PTW)

// Note: 'pt_walk()' is recursive => cannot merge 'val' and 'function' decls

// PRIVATE
val pt_walk : (SV_Params,
               bits(64),                     // virtual addr
               AccessType(ext_access_type),  // Read/Write/ReadWWrite/Execute
               Privilege,                    // User/Supervisor/Machine
               bool,                         // mstatus.MXR
               bool,                         // do_sum
               bits(64),                     // PT base addr
               nat,                          // tree level for this recursive call
               bool,                         // global translation,
               ext_ptw)                      // ext_ptw
              -> PTW_Result

function pt_walk(sv_params,
                 va,
                 ac,
                 priv,
                 mxr,
                 do_sum,
                 pt_base,
                 level,
                 global,
                 ext_ptw) = {
  let vpn_j      = vpn_j_of_va(sv_params, va, level);
  let pte_offset = vpn_j << sv_params.log_pte_size_bytes;
  let pte_addr   = pt_base + pte_offset;
  let pte_phys_addr : xlenbits = pte_addr[(sizeof(xlen) - 1) .. 0];

  // Read this-level PTE from mem
  let mem_result = mem_read_priv(Read(Data),              // AccessType
                                 Supervisor,              // Privilege
                                 pte_phys_addr,
                                 8,                       // atom (8)
                                 false,                   // aq
                                 false,                   // rl
                                 false);                  // res

  match mem_result {
    MemException(_) => PTW_Failure(PTW_Access(), ext_ptw),
    MemValue(pte)   => {
      let ppns : bits(64) = PPNs_of_PTE(sv_params, pte);
      let ext_pte         = msbs_of_PTE(sv_params, pte);
      let global'         = global | (G_of_PTE(pte) == bitone);
      if pte_is_invalid(pte) then
        PTW_Failure(PTW_Invalid_PTE(), ext_ptw)
      else {
        // Non-Leaf PTE
        if pte_is_ptr(pte) then {
          if level > 0 then {
            // follow the pointer to walk next level
            let pt_base' : bits(64) = shiftl(ppns, PAGESIZE_BITS);
            let level'        = level - 1;
            pt_walk(sv_params, va, ac, priv, mxr, do_sum,
                    pt_base', level', global', ext_ptw)
          }
          else
            // level 0 PTE, but contains a pointer instead of a leaf
            PTW_Failure(PTW_Invalid_PTE(), ext_ptw)
        }
        // Leaf PTE
        else {
          let pte_check = check_PTE_permission(ac, priv, mxr, do_sum,
                                               U_of_PTE(pte),
                                               X_of_PTE(pte),
                                               W_of_PTE(pte),
                                               R_of_PTE(pte),
                                               ext_pte,
                                               ext_ptw);
          match pte_check {
            PTE_Check_Failure(ext_ptw, ext_ptw_fail) =>
              PTW_Failure(ext_get_ptw_error(ext_ptw_fail), ext_ptw),
            PTE_Check_Success(ext_ptw) =>
              if level > 0 then {
                // Superpage; construct mask for lower-level PPNs from the PTE
                mask_PPN_j : bits(64) = (zero_extend(0b1) << sv_params.pte_PPN_j_size_bits)
                                        - zero_extend(0b1);
                mask       : bits(64) = zero_extend(0b0);
                foreach (j from 0 to (level - 1))
                  mask = ((mask << sv_params.pte_PPN_j_size_bits) | mask_PPN_j);
                // Lower-level PPNs must be zero (for aligned superpage)
                if not((ppns & mask) == zero_extend(0b0)) then
                  // misaligned superpage mapping
                  PTW_Failure(PTW_Misaligned(), ext_ptw)
                else {
                  // Compose final PA in superpage:
                  // Superpage PPN + lower VPNs + PAGESIZE_BITS page-offset
                  let ppn = ppns | (vpns_of_va (sv_params, va) & mask);
                  let pa  = ((ppn << PAGESIZE_BITS) | offset_of_va(va));
                  PTW_Success(pa, pte, pte_addr, level, global', ext_ptw)
                }
              }
              else {
                let pa = ((ppns << PAGESIZE_BITS) | offset_of_va (va));
                PTW_Success(pa, pte, pte_addr, level, global', ext_ptw)
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

// See riscv_sys_regs.sail for legalize_satp{32,64}().
// WARNING: those functions legalize Mode but not ASID?
// PUBLIC: invoked from writeCSR() to fixup WARL fields
function legalize_satp(a : Architecture,
                       o : xlenbits,        // previous value of satp
                       v : xlenbits)        // proposed new value of satp
                      -> xlenbits = {       // new legal value of satp
  if sizeof(xlen) == 32 then {
    // The slice and extend ops below are no-ops when xlen==32,
    // but appease the type-checker when xlen==64 (when this code is not executed!)
    let o32      : bits(32) = o[31 .. 0];
    let v32      : bits(32) = v[31 .. 0];
    let new_satp : bits(32) = legalize_satp32(a, o32, v32);
    zero_extend(new_satp);
  } else if sizeof(xlen) == 64 then {
    // The extend and truncate ops below are no-ops when xlen==64,
    // but appease the type-checker when xlen==32 (when this code is not executed!)
    let o64      : bits(64) = zero_extend(o);
    let v64      : bits(64) = zero_extend(v);
    let new_satp : bits(64) = legalize_satp64(a, o64, v64);
    truncate(new_satp, sizeof(xlen))
  } else
    internal_error(__FILE__, __LINE__, "Unsupported xlen" ^ string_of_int(sizeof(xlen)))
}

// ----------------
// Fields of SATP

// ASID is 9b in Sv32, 16b in Sv39/Sv48/Sv57: we use 16b for both
// PRIVATE
function satp_to_asid(sv_params : SV_Params, satp_val : xlenbits) -> bits(16) = {
  // This extend op is a no-op when xlen==64, extends when xlen==32
  let satp_64b : bits(64) = zero_extend (satp_val);
  let mask_64b : bits(64) = (zero_extend(0b1) << sv_params.satp_asid_size_bits) - zero_extend(0b1);
  let asid_64b : bits(64) = (satp_64b >>  sv_params.satp_asid_lsb_index) & mask_64b;
  asid_64b[15 .. 0]
}

// Result is 64b to cover both RV32 and RV64 addrs
// PRIVATE
function satp_to_PT_base(sv_params : SV_Params, satp_val : xlenbits) -> bits(64) = {
  // This extend op is a no-op when xlen==64, extends when xlen==32
  let satp_64b : bits(64) = zero_extend (satp_val);
  let mask_64b : bits(64) = (zero_extend(0b1) << sv_params.satp_ppn_size_bits) - zero_extend(0b1);
  let ppn_64b  : bits(64) = (satp_64b >>  sv_params.satp_ppn_lsb_index) & mask_64b;
  ppn_64b << PAGESIZE_BITS
}

// Compute address translation mode from SATP
// TODO: shouldn't we look at mstatus_UXL if priv is User?

// PRIVATE
function translationMode(priv : Privilege) -> SATPMode = {
  if priv == Machine then
    Sbare
  else if sizeof(xlen) == 32 then
    match satp[31] {
      bitzero => Sbare,
      bitone  => Sv32
    }
  else if sizeof(xlen) == 64 then {
    // This extend op is a no-op when xlen==64,
    // but appeases the type-checker when xlen==32 (when this code is not executed!)
    let satp_64b : bits(64) = zero_extend(satp);
    // Translation mode is based on mstatus.SXL, which could be RV32 when xlen==64
    let arch = architecture(get_mstatus_SXL(mstatus));
    match arch {
      Some(RV64) => { let mbits : bits(4) = satp[63 .. 60];
                      match satp64Mode_of_bits(RV64, mbits) {    // see riscv_types.sail
                        Some(m) => m,
                        None()  => internal_error(__FILE__, __LINE__,
                                                  "invalid RV64 translation mode in satp")
                      }
                    },
      Some(RV32) => match satp[31] {
                      // When xlen is 64, mstatus.SXL/UXL (for S, U privileges) can be RV32
                      bitzero => Sbare,
                      bitone  => Sv32
                    },
      _    => internal_error(__FILE__, __LINE__, "unsupported address translation arch")
    }
  }
  else
    internal_error(__FILE__, __LINE__, "unsupported xlen")
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
// part of RISC-V architecture spec (see TLB_NOTE above).
// PRIVATE: translate on TLB hit, and maintenance of PTE in TLB
function translate_TLB_hit(sv_params : SV_Params,
                           asid      : bits(16),
                           ptb       : bits(64),
                           vAddr     : bits(64),
                           ac        : AccessType(ext_access_type),
                           priv      : Privilege,
                           mxr       : bool,
                           do_sum    : bool,
                           level     : nat,
                           ext_ptw   : ext_ptw,
                           tlb_index : nat,
                           ent       : TLB_Entry)
                          -> TR_Result(bits(64), PTW_Error) = {
  let pte       = ent.pte;
  let ext_pte   = msbs_of_PTE(sv_params, pte);
  let pte_check = check_PTE_permission(ac, priv, mxr, do_sum,
                                       U_of_PTE(pte),
                                       X_of_PTE(pte),
                                       W_of_PTE(pte),
                                       R_of_PTE(pte),
                                       ext_pte,
                                       ext_ptw);
  let tr_result : TR_Result(bits(64), PTW_Error)
  = match pte_check {
      PTE_Check_Failure(ext_ptw, ext_ptw_fail) =>
        TR_Failure(ext_get_ptw_error(ext_ptw_fail), ext_ptw),
      PTE_Check_Success(ext_ptw) =>
        match update_PTE_Bits(sv_params, pte, ac, ext_pte) {
          None()     => TR_Address(ent.pAddr | (vAddr & ent.vAddrMask), ext_ptw),
          Some(pte') =>
            // See riscv_platform.sail
            if not(plat_enable_dirty_update()) then
              // pte needs dirty/accessed update but that is not enabled
              TR_Failure(PTW_PTE_Update(), ext_ptw)
            else {
              // Writeback the PTE (which has new A/D bits)
              n_ent : TLB_Entry = ent;
              n_ent.pte = pte';
              write_TLB(tlb_index, n_ent);
              let pte_phys_addr : xlenbits = ent.pteAddr[(sizeof(xlen) - 1) .. 0];
              let mv = mem_write_value_priv(pte_phys_addr,
                                            8,
                                            pte',
                                            Supervisor,
                                            false,
                                            false,
                                            false);
              match mv {
                MemValue(_)     => (),
                MemException(e) => internal_error(__FILE__, __LINE__,
                                                  "invalid physical address in TLB")
              };
              TR_Address(ent.pAddr | (vAddr & ent.vAddrMask), ext_ptw)
            }
        }
    };
  tr_result
}

// PRIVATE: translate on TLB miss (do a page-table walk)
function translate_TLB_miss(sv_params : SV_Params,
                            asid      : bits(16),
                            ptb       : bits(64),
                            vAddr     : bits(64),
                            ac        : AccessType(ext_access_type),
                            priv      : Privilege,
                            mxr       : bool,
                            do_sum    : bool,
                            level     : nat,
                            ext_ptw   : ext_ptw) -> TR_Result(bits(64), PTW_Error) = {
  let ptw_result = pt_walk(sv_params, vAddr, ac, priv, mxr, do_sum,
                           ptb, level, false, ext_ptw);
  match ptw_result {
    PTW_Failure(f, ext_ptw) => TR_Failure(f, ext_ptw),
    PTW_Success(pAddr, pte, pteAddr, level, global, ext_ptw) => {
      let ext_pte   = msbs_of_PTE(sv_params, pte);
      // Without TLBs, this 'match' expression can be replaced simply
      // by: 'TR_Address(pAddr, ext_ptw)'    (see TLB_NOTE above)
      match update_PTE_Bits(sv_params, pte, ac, ext_pte) {
        None() => {
          add_to_TLB(asid, vAddr, pAddr, pte, pteAddr, level, global,
                     sv_params.vpn_size_bits,    // TODO: ppn_size_bits?
                     PAGESIZE_BITS);
          TR_Address(pAddr, ext_ptw)
        },
        Some(pte') =>
          // See riscv_platform.sail
          if not(plat_enable_dirty_update()) then
            // pte needs dirty/accessed update but that is not enabled
            TR_Failure(PTW_PTE_Update(), ext_ptw)
          else {
            // Writeback the PTE (which has new A/D bits)
            let pte_phys_addr : xlenbits = pteAddr[(sizeof(xlen) - 1) .. 0];
            let mv = mem_write_value_priv(pte_phys_addr, // pteAddr,
                                          8,
                                          pte',
                                          Supervisor,
                                          false,
                                          false,
                                          false);
            match mv {
              MemValue(_) => {
                add_to_TLB(asid, vAddr, pAddr, pte', pteAddr, level, global,
                           sv_params.vpn_size_bits,    // TODO: ppn_size_bits?
                           PAGESIZE_BITS);
                TR_Address(pAddr, ext_ptw)
              },
              MemException(e) =>
                TR_Failure(PTW_Access(), ext_ptw)
            }
          }
        }
      }
    }
}

// PRIVATE
function translate(sv_params : SV_Params,
                   asid      : bits(16),
                   ptb        : bits(64),
                   vAddr_arg : bits(64),
                   ac         : AccessType(ext_access_type),
                   priv      : Privilege,
                   mxr        : bool,
                   do_sum    : bool,
                   level     : nat,
                   ext_ptw   : ext_ptw)
                  -> TR_Result(bits(64), PTW_Error) = {
  let one_64b  : bits(64) = zero_extend(0b1);
  let va_mask = (one_64b << sv_params.va_size_bits) - 1;
  let vAddr   = (vAddr_arg & va_mask);

  // On first reading, assume lookup_TLB returns None(), since TLBs
  // are not part of RISC-V archticture spec (see TLB_NOTE above)
  match lookup_TLB(asid, vAddr) {
    Some(index, ent) => translate_TLB_hit(sv_params, asid, ptb, vAddr, ac, priv,
                                          mxr, do_sum, level, ext_ptw, index, ent),
    None()           => translate_TLB_miss(sv_params, asid, ptb, vAddr, ac, priv,
                                           mxr, do_sum, level, ext_ptw)
  }
}

// Top-level addr-translation function
// PUBLIC: invoked from instr-fetch and load/store/amo
function translateAddr(vAddr   : xlenbits,
                       ac      : AccessType(ext_access_type))
                      -> TR_Result(xlenbits, ExceptionType) = {
  // Internally the vmem code works with 64-bit values, whether xlen==32 or xlen==64
  // This 'extend' is a no-op when xlen==64 and extends when xlen==32
  let vAddr_64b : bits(64) = zero_extend(vAddr);
  // Effective privilege takes into account mstatus.PRV, mstatus.MPP
  // See riscv_sys_regs.sail for effectivePrivilege() and cur_privilege
  let effPriv   : Privilege = effectivePrivilege(ac, mstatus, cur_privilege);
  let mode      : SATPMode = translationMode(effPriv);
  // PTW extensions (non-standard): initialize the PTW extension state
  let ext_ptw   : ext_ptw = init_ext_ptw;
  let (valid_va, sv_params) : (bool, SV_Params) = match mode {
    Sbare => return TR_Address(vAddr, ext_ptw),
    Sv32  => (true,                                 sv32_params),
    Sv39  => (is_valid_vAddr(sv39_params, vAddr_64b), sv39_params),
    Sv48  => (is_valid_vAddr(sv48_params, vAddr_64b), sv48_params),
    // Sv57 => (is_valid_vAddr(sv57_params, vAddr_64b), sv57_params),    // FUTURE
  };
  if not(valid_va) then
    TR_Failure(translationException(ac, PTW_Invalid_Addr()), ext_ptw)
  else {
    let mxr    : bool     = mstatus.MXR() == 0b1;
    let do_sum : bool     = mstatus.SUM() == 0b1;
    let asid   : bits(16) = satp_to_asid(sv_params, satp);
    let ptb    : bits(64) = satp_to_PT_base(sv_params, satp);
    let tr_result1 = translate(sv_params,
                               asid,
                               ptb,
                               vAddr_64b,
                               ac, effPriv, mxr, do_sum,
                               sv_params.levels - 1,    // initial level
                               ext_ptw);
    // Fixup result PA or exception
    match tr_result1 {
      TR_Address(pa, ext_ptw) => TR_Address(truncate(pa, sizeof(xlen)), ext_ptw),
      TR_Failure(f, ext_ptw)  => TR_Failure(translationException(ac, f), ext_ptw)
    }
  }
}

// ****************************************************************
// Initialize Virtual Memory state

// PUBLIC: invoked from init_model()
function init_vmem() -> unit = init_TLB()

// ****************************************************************
