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
// Supported VM modes: Sv32, Sv39, Sv48.  TODO: Sv57

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
// Parameters for VM modes Sv32, Sv39, Sv48, Sv57, Sv32x4, Sv39x4, Sv48x4 and Sv57x4

// All VM modes use the same page size (4KB, with 12-bit index)

// This two-line idiom constrains the value (2nd line) to be a singleton,
// which helps in type-checking wherever it is used.
type PAGESIZE_BITS : Int = 12
let  pagesize_bits = sizeof(PAGESIZE_BITS)

// PRIVATE
struct SV_Params = {
  // SATP/HGATP CSR                                         // Sv32  Sv39  Sv48  Sv57  Sv32x4  Sv39x4  Sv48x4  Sv57x4
  xatp_id_size_bits : { 7, 9, 14, 16},                      //    9    16    16    16       7      14      14      14
  xatp_id_lsb_index : {22, 44},                             //   22    44    44    44      22      44      44      44
  // SATP/HGATP PPN
  xatp_ppn_size_bits  : {22, 44},                           //   22    44    44    44      22      44      44      44
  xatp_ppn_lsb_index  : { 0},                               //    0     0     0     0       0       0       0       0

  // VA
  va_size_bits        : {32, 34, 39, 41, 48, 50, 57, 59},   //   32    39    48    57      34      41      50      59
  vpn_size_bits       : {10,  9},                           //   10     9     9     9      10       9       9       9
  root_vpn_size_bits  : {9,  10, 11, 12},                   //   10     9     9     9      12      11      11      11
  va_sign_extends     : bool,                               // true  true  true  true   false   false   false   false

  // PTE
  levels              : { 2,  3,  4,  5},                   //    2     3     4     5       2       3       4       5
  log_pte_size_bytes  : { 2,  3},                           //    2     3     3     3       2       3       3       3
  pte_msbs_lsb_index  : {32, 54},                           //   32    54    54    54      32      54      54      54
  pte_msbs_size_bits  : { 0, 10},                           //    0    10    10    10       0      10      10      10
  pte_PPNs_lsb_index  : {10},                               //   10    10    10    10      10      10      10      10
  pte_PPNs_size_bits  : {22, 44},                           //   22    44    44    44      22      44      44      44
  pte_PPN_j_size_bits : {10,  9}                            //   10     9     9     9      10       9       9       9
}

// Current level during a page-table walk (0 to SV_Params.levels - 1)
type PTW_Level = range(0,4)

// PRIVATE
let sv32_params : SV_Params = struct {
       // SATP CSR
       xatp_id_size_bits   = 9,
       xatp_id_lsb_index   = 22,

       // SATP PPN
       xatp_ppn_size_bits  = 22,
       xatp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 32,
       vpn_size_bits       = 10,
       root_vpn_size_bits  = 10,
       va_sign_extends     = true,

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
let sv32x4_params : SV_Params = struct {
       // SATP CSR
       xatp_id_size_bits   = 7,
       xatp_id_lsb_index   = 22,

       // SATP PPN
       xatp_ppn_size_bits  = 22,
       xatp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 34,
       vpn_size_bits       = 10,
       root_vpn_size_bits  = 12,
       va_sign_extends     = false,

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
       xatp_id_size_bits   = 14,
       xatp_id_lsb_index   = 44,

       // SATP PPN
       xatp_ppn_size_bits  = 44,
       xatp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 39,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 9,
       va_sign_extends     = true,

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
let sv39x4_params : SV_Params = struct {
       // SATP CSR
       xatp_id_size_bits   = 16,
       xatp_id_lsb_index   = 44,

       // SATP PPN
       xatp_ppn_size_bits  = 44,
       xatp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 41,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 11,
       va_sign_extends     = false,

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
       xatp_id_size_bits   = 16,
       xatp_id_lsb_index   = 44,

       // SATP PPN
       xatp_ppn_size_bits  = 44,
       xatp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 48,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 9,
       va_sign_extends     = true,

       // PTE
       levels              = 4,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}

// PRIVATE
let sv48x4_params : SV_Params = struct {
       // SATP CSR
       xatp_id_size_bits   = 14,
       xatp_id_lsb_index   = 44,

       // SATP PPN
       xatp_ppn_size_bits  = 44,
       xatp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 50,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 11,
       va_sign_extends     = false,

       // PTE
       levels              = 4,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}

// TODO; not currently used
// PRIVATE
let sv57_params : SV_Params = struct {
       // SATP CSR
       xatp_id_size_bits   = 16,
       xatp_id_lsb_index   = 44,

       // SATP PPN
       xatp_ppn_size_bits  = 44,
       xatp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 57,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 9,
       va_sign_extends     = true,

       // PTE
       levels              = 5,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}

// PRIVATE
let sv57x4_params : SV_Params = struct {
       // SATP CSR
       xatp_id_size_bits   = 14,
       xatp_id_lsb_index   = 44,

       // SATP PPN
       xatp_ppn_size_bits  = 44,
       xatp_ppn_lsb_index  = 0,

       // VA
       va_size_bits        = 59,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 11,
       va_sign_extends     = false,

       // PTE
       levels              = 5,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}

// This 'undefined_SV_Params()' function is not used anywhere, but is
// currently (2023-12) needed to work around an issue where Sail tries
// to figure out how it could do
//     let x : SV_Params = undefined
// even though the code never does this.  This has been fixed in Sail.
// The fix will become available in a new Sail release, at which point
// this function can be deleted (TODO).
// PRIVATE
val      undefined_SV_Params : unit -> SV_Params
function undefined_SV_Params() = sv32_params

// ****************************************************************
// Fields of virtual addresses

// PRIVATE: Extract full VPN field from VA
function vpns_of_va(sv_params : SV_Params,
                    va        : bits(64)) -> bits(64) = {
  let mask : bits(64) = zero_extend(ones(sv_params.va_size_bits));
  (va & mask) >> pagesize_bits
}

// PRIVATE: Extract VPN[level] from  VA
function vpn_j_of_va(sv_params : SV_Params,
                     va        : bits(64),
                     level     : PTW_Level) -> bits(64) = {
    let lsb  : range(0,63)= pagesize_bits + level * sv_params.vpn_size_bits;
  assert (lsb < sizeof(xlen));
    let mask : bits(64) = if (level == sv_params.levels - 1)
                          then zero_extend(ones(sv_params.root_vpn_size_bits))
                          else zero_extend(ones(sv_params.vpn_size_bits));
    ((va >> lsb) & mask)
}

// PRIVATE: Extract offset within page from VA
function offset_of_va(va : bits(64)) -> bits(PAGESIZE_BITS) = va[pagesize_bits - 1 .. 0]

// Valid xlen-wide values containing virtual addrs must have upper
// bits equal to the MSB of the virtual address for S- and VS-stage
// address translation. G-stage address translation schemes require
// the upper bits to be zero.
// Virtual address widths depend on the virtual memory mode.
// PRIVATE
function is_valid_vAddr(struct { va_size_bits, va_sign_extends, _ } : SV_Params,
                        vAddr                      : bits(64))  -> bool = {
  if va_sign_extends
  then vAddr == sign_extend(vAddr[va_size_bits - 1 .. 0])
  else vAddr == zero_extend(vAddr[va_size_bits - 1 .. 0])
}

// ****************************************************************
// PTE (Page Table Entry) in PTN (Page Table Node)

// PTE      MSBs      PPNs      RSW    BITs
// Sv32      -       31..10    9..8    7..0
// Sv39    63..54    53..10    9..8    7..0
// Sv48    63..54    53..10    9..8    7..0
// Sv32x4    -       31..10    9..8    7..0
// Sv39x4  63..54    53..10    9..8    7..0
// Sv48x4  63..54    53..10    9..8    7..0

// MSBs of PTE are reserved for RV64 extensions.
// There are not available bits on RV32, so these bits will be zeros on RV32.

type pte_flags_bits = bits(8)

// For PTW extensions (non-standard)
type extPte = bits(64)

// PRIVATE: extract msbs of PTE above the PPN
function msbs_of_PTE(sv_params : SV_Params, pte : bits(64)) -> bits(64) = {
  let mask : bits(64) = zero_extend(ones(sv_params.pte_msbs_size_bits));
  (pte >> sv_params.pte_msbs_lsb_index) & mask
}

// PRIVATE: extract PPNs of PTE
function PPNs_of_PTE(sv_params : SV_Params, pte : bits(64)) -> bits(64) = {
  let mask : bits(64) = zero_extend(ones(sv_params.pte_PPNs_size_bits));
  (pte >> sv_params.pte_PPNs_lsb_index) & mask
}

// PRIVATE: 8 LSBs of PTEs in Sv32, Sv39, Sv48 and Sv57
bitfield PTE_Flags : pte_flags_bits = {
  D : 7,    // dirty
  A : 6,    // accessed
  G : 5,    // global
  U : 4,    // User
  X : 3,    // Execute permission
  W : 2,    // Write permission
  R : 1,    // Read permission
  V : 0     // Valid
}

// PRIVATE: check if a PTE is a pointer to next level (non-leaf)
function pte_is_ptr(pte_flags : PTE_Flags) -> bool = (pte_flags[X] == 0b0)
                                                      & (pte_flags[W] == 0b0)
                                                      & (pte_flags[R] == 0b0)

// PRIVATE: check if a PTE is valid
function pte_is_invalid(pte_flags : PTE_Flags) -> bool = (pte_flags[V] == 0b0)
                                                         | ((pte_flags[W] == 0b1)
                                                            & (pte_flags[R] == 0b0))

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
function check_PTE_permission(ac        : AccessType(ext_access_type),
                              priv      : Privilege,
                              mxr       : bool,
                              do_sum    : bool,
                              pte_flags : PTE_Flags,
                              ext       : extPte,
                              ext_ptw   : ext_ptw) -> PTE_Check = {
  let pte_U = pte_flags[U];
  let pte_R = pte_flags[R];
  let pte_W = pte_flags[W];
  let pte_X = pte_flags[X];
  let success : bool =
    match (ac, priv) {
      (Read(_),         User)       => (pte_U == 0b1)
                                       & ((pte_R == 0b1)
                                          | ((pte_X == 0b1 & mxr))),
      (Write(_),        User)       => (pte_U == 0b1) & (pte_W == 0b1),
      (ReadWrite(_, _), User)       => (pte_U == 0b1)
                                       & (pte_W == 0b1)
                                       & ((pte_R == 0b1) | ((pte_X == 0b1) & mxr)),
      (Execute(),       User)       => (pte_U == 0b1) & (pte_X == 0b1),
      (Read(_),         Supervisor) => ((pte_U == 0b0) | do_sum)
                                       & ((pte_R == 0b1) | ((pte_X == 0b1) & mxr)),
      (Write(_),        Supervisor) => ((pte_U == 0b0) | do_sum)
                                       & (pte_W == 0b1),
      (ReadWrite(_, _), Supervisor) => ((pte_U == 0b0) | do_sum)
                                       & (pte_W == 0b1)
                                       & ((pte_R == 0b1)
                                          | ((pte_X == 0b1) & mxr)),
      (Execute(),       Supervisor) => (pte_U == 0b0) & (pte_X == 0b1),
      (_,               Machine)    => internal_error(__FILE__, __LINE__,
                                                      "m-mode mem perm check")};
  if success then PTE_Check_Success(())
  else            PTE_Check_Failure((), ())
}

// Update PTE bits if needed; return new PTE if updated
// PRIVATE
function update_PTE_Bits(sv_params : SV_Params,
                         pte       : bits(64),
                         a         : AccessType(ext_access_type))
                        -> option(bits(64)) = {
  let pte_flags = Mk_PTE_Flags(pte [7 .. 0]);

  // Update 'dirty' bit?
  let update_d : bool = (pte_flags[D] == 0b0)
                        & (match a {
                             Execute()       => false,
                             Read()          => false,
                             Write(_)        => true,
                             ReadWrite(_, _) => true
                           });
  // Update 'accessed'-bit?
  let update_a = (pte_flags[A] == 0b0);

  if update_d | update_a then {
    let pte_flags = [pte_flags with
                      A = 0b1,
                      D = (if update_d then 0b1 else pte_flags[D])];
    Some(pte[63 .. 8] @ pte_flags.bits())
  }
  else
    None()
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
  let mask_64b : bits(64) = (zero_extend(0b1) << sv_params.xatp_id_size_bits) - zero_extend(0b1);
  let asid_64b : bits(64) = (satp_64b >>  sv_params.xatp_id_lsb_index) & mask_64b;
  asid_64b[15 .. 0]
}

// Result is 64b to cover both RV32 and RV64 addrs
// PRIVATE
function satp_to_PT_base(sv_params : SV_Params, satp_val : xlenbits) -> bits(64) = {
  // This extend op is a no-op when xlen==64, extends when xlen==32
  let satp_64b : bits(64) = zero_extend (satp_val);
  let mask_64b : bits(64) = (zero_extend(0b1) << sv_params.xatp_ppn_size_bits) - zero_extend(0b1);
  let ppn_64b  : bits(64) = (satp_64b >>  sv_params.xatp_ppn_lsb_index) & mask_64b;
  ppn_64b << pagesize_bits
}

// ****************************************************************
// Architectural HGATP CSR

register hgatp : xlenbits

// See riscv_hext_regs.sail for legalize_hgatp{32,64}().
// WARNING: those functions legalize Mode but not VMID?
// PUBLIC: invoked from writeCSR() to fixup WARL fields
function legalize_hgatp(a : Architecture,
                       o : xlenbits,        // previous value of hgatp
                       v : xlenbits)        // proposed new value of hgatp
                      -> xlenbits = {       // new legal value of hgatp
  if sizeof(xlen) == 32 then {
    // The slice and extend ops below are no-ops when xlen==32,
    // but appease the type-checker when xlen==64 (when this code is not executed!)
    let o32      : bits(32) = o[31 .. 0];
    let v32      : bits(32) = v[31 .. 0];
    let new_hgatp : bits(32) = legalize_hgatp32(a, o32, v32);
    zero_extend(new_hgatp);
  } else if sizeof(xlen) == 64 then {
    // The extend and truncate ops below are no-ops when xlen==64,
    // but appease the type-checker when xlen==32 (when this code is not executed!)
    let o64      : bits(64) = zero_extend(o);
    let v64      : bits(64) = zero_extend(v);
    let new_hgatp : bits(64) = legalize_hgatp64(a, o64, v64);
    truncate(new_hgatp, sizeof(xlen))
  } else
    internal_error(__FILE__, __LINE__, "Unsupported xlen" ^ string_of_int(sizeof(xlen)))
}

// ----------------
// Fields of HGATP

// VMID is 7b in Sv32x4, 14b in Sv39x4/Sv48x4/Sv57x4: we use 14b for both
// PRIVATE
function hgatp_to_vmid(sv_params : SV_Params, hgatp_val : xlenbits) -> bits(14) = {
  // This extend op is a no-op when xlen==64, extends when xlen==32
  let hgatp_64b : bits(64) = zero_extend (hgatp_val);
  let mask_64b  : bits(64) = (zero_extend(0b1) << sv_params.xatp_id_size_bits) - zero_extend(0b1);
  let vmid_64b  : bits(64) = (hgatp_64b >>  sv_params.xatp_id_lsb_index) & mask_64b;
  vmid_64b[13 .. 0]
}

// Result is 64b to cover both RV32 and RV64 addrs
// PRIVATE
function hgatp_to_PT_base(sv_params : SV_Params, hgatp_val : xlenbits) -> bits(64) = {
  // This extend op is a no-op when xlen==64, extends when xlen==32
  let hgatp_64b : bits(64) = zero_extend (hgatp_val);
  let mask_64b  : bits(64) = (zero_extend(0b1) << sv_params.xatp_ppn_size_bits) - zero_extend(0b1);
  let ppn_64b   : bits(64) = (hgatp_64b >>  sv_params.xatp_ppn_lsb_index) & mask_64b;
  ppn_64b << pagesize_bits
}

// ****************************************************************
// Address translation mode

// Compute address translation mode from SATP/HGATP
// TODO: shouldn't we look at mstatus_UXL if priv is User?

// PRIVATE
function translationMode(priv : Privilege, stage : AddressTranslationStage) -> AddressTranslationMode = {
  let mode : option(AddressTranslationMode) = match priv {
    Machine => Some(Bare),
    _       => {
      if sizeof(xlen) == 32 then
        match stage {
          S  => satp64Mode_of_bits(RV32, zero_extend(Mk_Satp32(satp).Mode())),
          VS => satp64Mode_of_bits(RV32, zero_extend(Mk_Satp32(vsatp).Mode())),
          G  => hgatp64Mode_of_bits(RV32, zero_extend(Mk_Hgatp32(hgatp).Mode())),
        }
      else if sizeof(xlen) == 64 then
        // When xlen is 64, mstatus.SXL (S/HS-mode) or hstatus.VSXL (VS-mode) can be RV32
        match stage {
          S  => match architecture(get_mstatus_SXL(mstatus)) {
                  Some(RV32) => satp64Mode_of_bits(RV32, zero_extend(Mk_Satp32(satp[31 .. 0]).Mode())),
                  Some(RV64) => satp64Mode_of_bits(RV64, Mk_Satp64(satp).Mode()),
                  _          => internal_error(__FILE__, __LINE__, "unsupported address translation arch")
          },
          VS => match architecture(get_hstatus_VSXL(hstatus)) {
                  Some(RV32) => satp64Mode_of_bits(RV32, zero_extend(Mk_Satp32(vsatp[31 .. 0]).Mode())),
                  Some(RV64) => satp64Mode_of_bits(RV64, Mk_Satp64(vsatp).Mode()),
                  _          => internal_error(__FILE__, __LINE__, "unsupported address translation arch")
          },
          G  => match architecture(get_mstatus_SXL(mstatus)) {
                  Some(RV32) => hgatp64Mode_of_bits(RV32, zero_extend(Mk_Hgatp32(hgatp[31 .. 0]).Mode())),
                  Some(RV64) => hgatp64Mode_of_bits(RV64, Mk_Hgatp64(hgatp).Mode()),
                  _          => internal_error(__FILE__, __LINE__, "unsupported address translation arch")
          },
        }
      else
        internal_error(__FILE__, __LINE__, "unsupported xlen")
    }
  } in
  match mode {
      Some(m) => m,
      None()  => internal_error(__FILE__, __LINE__, "invalid translation mode in xatp")
  }
}

// ****************************************************************
// Results of Page Table Walk (PTW)

// Note: Idealy we could use 'PTW_Implicit : (PTW_Error, ...)' in 'PTW_Error' but recursive types are not supported

// Failure modes for implicit address-translation/page-table-walks
// PRIVATE
union PTW_Implicit_Error = {
  PTW_I_Invalid_Addr  : unit,                         // invalid source address
  PTW_I_Access        : unit,                         // physical memory access error for a PTE
  PTW_I_Invalid_PTE   : unit,                         // invalid page table entry or ptr PTE when level = 0
  PTW_I_No_Permission : unit,                         // insufficient page permissions
  PTW_I_Misaligned    : unit,                         // misaligned superpage
  PTW_I_PTE_Update    : unit,                         // PTE update needed but not enabled
  PTW_I_Ext_Error     : ext_ptw_error                 // parameterized for errors from extensions
}

// Failure modes for address-translation/page-table-walks
// PRIVATE
union PTW_Error = {
  PTW_Invalid_Addr  : unit,                           // invalid source address
  PTW_Access        : unit,                           // physical memory access error for a PTE
  PTW_Invalid_PTE   : unit,                           // invalid page table entry or ptr PTE when level = 0
  PTW_No_Permission : unit,                           // insufficient page permissions
  PTW_Misaligned    : unit,                           // misaligned superpage
  PTW_PTE_Update    : unit,                           // PTE update needed but not enabled
  PTW_Implicit      : (PTW_Implicit_Error,            // error during implicit access/page-walk
                       bits(64),                      //   faulting address of implicit access/page-walk
                       AccessType(ext_access_type)),  //   access type of implicit access/page-walk
  PTW_Ext_Error     : ext_ptw_error                   // parameterized for errors from extensions
}

// Convert PTW_Error to PTW_Implicit_Error
function implicit_error(f : PTW_Error) -> PTW_Implicit_Error = {
  match f {
    PTW_Invalid_Addr()    => PTW_I_Invalid_Addr(),
    PTW_Access()          => PTW_I_Access(),
    PTW_Invalid_PTE()     => PTW_I_Invalid_PTE(),
    PTW_No_Permission()   => PTW_I_No_Permission(),
    PTW_Misaligned()      => PTW_I_Misaligned(),
    PTW_PTE_Update()      => PTW_I_PTE_Update(),
    PTW_Ext_Error()       => PTW_I_Ext_Error(),
    PTW_Implicit(_, _, _) => internal_error(__FILE__, __LINE__, "cannot convert implicit PTW error")
  }
}

// PRIVATE: only 'to_str' overload is public
function ptw_error_to_str(e : PTW_Error) -> string = {
  match e {
    PTW_Invalid_Addr()    => "invalid-source-addr",
    PTW_Access()          => "mem-access-error",
    PTW_Invalid_PTE()     => "invalid-pte",
    PTW_No_Permission()   => "no-permission",
    PTW_Misaligned()      => "misaligned-superpage",
    PTW_PTE_Update()      => "pte-update-needed",
    PTW_Implicit(_, _, _) => "implicit-access-error",
    PTW_Ext_Error(e)      => "extension-error"
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
// PRIVATE
function translationException(a : AccessType(ext_access_type),
                              f : PTW_Error)
                              -> ExceptionType = {
  match (a, f) {
    (_, PTW_Ext_Error(e))         => E_Extension(ext_translate_exception(e)),
    (_, PTW_Implicit(fi, _, _))   => match (a, fi) { // Report exception for the original access type (of explicit page-walk)
                                       (_, PTW_I_Ext_Error(e))         => E_Extension(ext_translate_exception(e)),
                                       (ReadWrite(_), PTW_I_Access())  => E_SAMO_Access_Fault(),
                                       (ReadWrite(_), _)               => E_SAMO_GPage_Fault(),
                                       (Read(_), PTW_I_Access())       => E_Load_Access_Fault(),
                                       (Read(_), _)                    => E_Load_GPage_Fault(),
                                       (Write(_), PTW_I_Access())      => E_SAMO_Access_Fault(),
                                       (Write(_), _)                   => E_SAMO_GPage_Fault(),
                                       (Execute(), PTW_I_Access())     => E_Fetch_Access_Fault(),
                                       (Execute(), _)                  => E_Fetch_GPage_Fault()},
    (ReadWrite(_), PTW_Access())  => E_SAMO_Access_Fault(),
    (ReadWrite(_), _)             => E_SAMO_Page_Fault(),
    (Read(_), PTW_Access())       => E_Load_Access_Fault(),
    (Read(_), _)                  => E_Load_Page_Fault(),
    (Write(_), PTW_Access())      => E_SAMO_Access_Fault(),
    (Write(_), _)                 => E_SAMO_Page_Fault(),
    (Execute(), PTW_Access())     => E_Fetch_Access_Fault(),
    (Execute(), _)                => E_Fetch_Page_Fault()
  }
}

// PRIVATE
function pseudoinst(ac : AccessType(ext_access_type), arch : Architecture) -> bits(32) = {
  match (arch, ac) {
    (RV32, Read(_))  => 0x00002000,
    (RV32, Write(_)) => 0x00002020,
    (RV64, Read(_))  => 0x00003000,
    (RV64, Write(_)) => 0x00003020,
    (_, _) => internal_error(__FILE__, __LINE__, "Illegal pseudoinst architecture/access type")
  }
}

// Build architectural exception context for translation/PTW failures
// PRIVATE
function translationEContext(f     : PTW_Error,
                             vaddr : bits(64),
                             gva   : bool)
                             -> ExceptionContext = {
  match f {
    PTW_Ext_Error(e)            => ext_exception_context(e),
    PTW_Implicit(f, gpaddr, ac) => {
      let pinst : option(xlenbits) = match f {
        PTW_I_Access()     => None(),
        PTW_I_Ext_Error(_) => None(),
        _                  => Some(zero_extend(pseudoinst(ac, if sizeof(xlen) == 32 then RV32 else RV64))), // FIXME: This does not support dynamic XLEN changes
      } in
      vmem_exception_context(truncate(vaddr, sizeof(xlen)), true, Some(truncate(gpaddr >> 2, sizeof(xlen))), pinst)
    },
    _ => vmem_exception_context(truncate(vaddr, sizeof(xlen)), gva, None(), None()),
  }
}

// PRIVATE
union PTW_Result = {
  PTW_Success: (bits(64), bits(64), bits(64), nat, bool, ext_ptw),
  PTW_Failure: (PTW_Error, ext_ptw)
}

// ****************************************************************
// Translate VA -> PA (S-stage), VA -> GPA (VS-stage) or GPA -> SPA(G-stage)

// Result of Address Translation (for internal, private functions)
// PRIVATE
union TRi_Result = {
  TRi_Address : (bits(64), ext_ptw),
  TRi_Failure : (PTW_Error, ext_ptw)
}

// Note: translate_stage is used for translation of implicit accesses during page walk
//       => 'val' declaration should occur before 'function' definition of pt_walk,
//          the 'function' definition of translate_stage is further down in this file

// PRIVATE
val translate_stage : (bits(64),                    // virtual address
                       AccessType(ext_access_type), // Read/Write/ReadWrite/Execute
                       Privilege,                   // Machine/Supervisor/User
                       AddressTranslationStage,     // S/VS/G
                       ext_ptw                      // ext_ptw
                      ) -> TRi_Result

// ****************************************************************
// Page Table Walk (PTW)

// Note: 'pt_walk()' is recursive => needs separate 'val' decls

// PRIVATE
val pt_walk : (SV_Params,
               AddressTranslationStage,
               bits(64),                     // virtual addr
               AccessType(ext_access_type),  // Read/Write/ReadWrite/Execute
               Privilege,                    // User/Supervisor/Machine
               bool,                         // mstatus.MXR
               bool,                         // do_sum
               bits(64),                     // PT base addr
               PTW_Level,                    // tree level for this recursive call
               bool,                         // global translation,
               ext_ptw)                      // ext_ptw
              -> PTW_Result

function pt_walk(sv_params,
                 stage,
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
  let pte_phys_addr : xlenbits = match stage {
    VS => match translate_stage(pte_addr, Read(Data), User, G, ext_ptw) {
      TRi_Address(pte_pa, ext_ptw) => pte_pa[(sizeof(xlen) - 1) .. 0],
      TRi_Failure(f, ext_ptw)  => return PTW_Failure(PTW_Implicit(implicit_error(f), pte_addr, Read(Data)), ext_ptw),
    },
    _  => pte_addr[(sizeof(xlen) - 1) .. 0]
  };

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
      let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);
      if pte_is_invalid(pte_flags) then
        PTW_Failure(PTW_Invalid_PTE(), ext_ptw)
      else {
        let ppns : bits(64) = PPNs_of_PTE(sv_params, pte);
        let global'         = global | (pte_flags[G] == 0b1);
        if pte_is_ptr(pte_flags) then {
          // Non-Leaf PTE
          if level > 0 then {
            // follow the pointer to walk next level
            let pt_base' : bits(64) = ppns << pagesize_bits;
            let level'        = level - 1;
            pt_walk(sv_params, stage, va, ac, priv, mxr, do_sum,
                    pt_base', level', global', ext_ptw)
          }
          else
            // level 0 PTE, but contains a pointer instead of a leaf
            PTW_Failure(PTW_Invalid_PTE(), ext_ptw)
        }
        else {
          // Leaf PTE
          let ext_pte   = msbs_of_PTE(sv_params, pte);
          let pte_check = check_PTE_permission(ac, priv, mxr, do_sum, pte_flags,
                                               ext_pte, ext_ptw);
          match pte_check {
            PTE_Check_Failure(ext_ptw, ext_ptw_fail) =>
              PTW_Failure(ext_get_ptw_error(ext_ptw_fail), ext_ptw),
            PTE_Check_Success(ext_ptw) =>
              if level > 0 then {
                // Superpage; construct mask for lower-level PPNs from the PTE
                let mask_bits = level * sv_params.pte_PPN_j_size_bits;
                // Clear the lowest `mask_bits` bits.
                let ppns_masked = (ppns >> mask_bits) << mask_bits;
                if not(ppns == ppns_masked) then
                  // misaligned superpage mapping
                  PTW_Failure(PTW_Misaligned(), ext_ptw)
                else {
                  // Compose final PA in superpage:
                  // Superpage PPN + lower VPNs + pagesize_bits page-offset
                  let mask : bits(64) = ~ (ones() << mask_bits);
                  let ppn = ppns | (vpns_of_va(sv_params, va) & mask);
                  let pa  = (ppn << pagesize_bits) | zero_extend(offset_of_va(va));
                  PTW_Success(pa, pte, pte_addr, level, global', ext_ptw)
                }
              }
              else {
                let pa = (ppns << pagesize_bits) | zero_extend(offset_of_va(va));
                PTW_Success(pa, pte, pte_addr, level, global', ext_ptw)
              }
          }
        }
      }
    }
  }
}

// ****************************************************************
// VA to PA translation

// This function can be ignored on first reading since TLBs are not
// part of RISC-V architecture spec (see TLB_NOTE above).
// PRIVATE: translate on TLB hit, and maintenance of PTE in TLB
function translate_TLB_hit(sv_params : SV_Params,
                           stage     : AddressTranslationStage,
                           xxid      : bits(16),
                           ptb       : bits(64),
                           vAddr     : bits(64),
                           ac        : AccessType(ext_access_type),
                           priv      : Privilege,
                           mxr       : bool,
                           do_sum    : bool,
                           ext_ptw   : ext_ptw,
                           tlb_index : nat,
                           ent       : TLB_Entry)
                          -> TRi_Result = {
  let pte       = ent.pte;
  let ext_pte   = msbs_of_PTE(sv_params, pte);
  let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);
  let pte_check = check_PTE_permission(ac, priv, mxr, do_sum, pte_flags,
                                       ext_pte,
                                       ext_ptw);
  let tr_result : TRi_Result
  = match pte_check {
      PTE_Check_Failure(ext_ptw, ext_ptw_fail) =>
        TRi_Failure(ext_get_ptw_error(ext_ptw_fail), ext_ptw),
      PTE_Check_Success(ext_ptw) =>
        match update_PTE_Bits(sv_params, pte, ac) {
          None()     => TRi_Address(ent.pAddr | (vAddr & ent.vAddrMask), ext_ptw),
          Some(pte') =>
            // See riscv_platform.sail
            if not(plat_enable_dirty_update()) then
              // pte needs dirty/accessed update but that is not enabled
              TRi_Failure(PTW_PTE_Update(), ext_ptw)
            else {
              // Writeback the PTE (which has new A/D bits)
              n_ent : TLB_Entry = ent;
              n_ent.pte = pte';
              write_TLB(tlb_index, n_ent, stage);
              let pte_phys_addr : xlenbits = match stage {
                VS => match translate_stage(ent.pteAddr, Write(Data), User, G, ext_ptw) {
                  TRi_Address(pte_pa, ext_ptw) => pte_pa[(sizeof(xlen) - 1) .. 0],
                  TRi_Failure(f, ext_ptw)  => return TRi_Failure(PTW_Implicit(implicit_error(f),
                                                                              ent.pteAddr,
                                                                              Write(Data)),
                                                                 ext_ptw),
                },
                _  => ent.pteAddr[(sizeof(xlen) - 1) .. 0]
              };
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
              TRi_Address(ent.pAddr | (vAddr & ent.vAddrMask), ext_ptw)
            }
        }
    };
  tr_result
}

// PRIVATE: translate on TLB miss (do a page-table walk)
function translate_TLB_miss(sv_params : SV_Params,
                            stage     : AddressTranslationStage,
                            xxid      : bits(16),
                            ptb       : bits(64),
                            vAddr     : bits(64),
                            ac        : AccessType(ext_access_type),
                            priv      : Privilege,
                            mxr       : bool,
                            do_sum    : bool,
                            ext_ptw   : ext_ptw) -> TRi_Result = {
  let initial_level = sv_params.levels - 1;
  let ptw_result = pt_walk(sv_params, stage, vAddr, ac, priv, mxr, do_sum,
                           ptb, initial_level, false, ext_ptw);
  match ptw_result {
    PTW_Failure(f, ext_ptw) => TRi_Failure(f, ext_ptw),
    PTW_Success(pAddr, pte, pteAddr, level, global, ext_ptw) => {
      let ext_pte   = msbs_of_PTE(sv_params, pte);
      // Without TLBs, this 'match' expression can be replaced simply
      // by: 'TRi_Address(pAddr, ext_ptw)'    (see TLB_NOTE above)
      match update_PTE_Bits(sv_params, pte, ac) {
        None() => {
          add_to_TLB(xxid, stage, vAddr, pAddr, pte, pteAddr, level, global,
                     sv_params.vpn_size_bits,    // TODO: ppn_size_bits?
                     pagesize_bits);
          TRi_Address(pAddr, ext_ptw)
        },
        Some(pte') =>
          // See riscv_platform.sail
          if not(plat_enable_dirty_update()) then
            // pte needs dirty/accessed update but that is not enabled
            TRi_Failure(PTW_PTE_Update(), ext_ptw)
          else {
            // Writeback the PTE (which has new A/D bits)
            let pte_phys_addr : xlenbits = match stage {
                VS => match translate_stage(pteAddr, Write(Data), User, G, ext_ptw) {
                  TRi_Address(pte_pa, ext_ptw) => pte_pa[(sizeof(xlen) - 1) .. 0],
                  TRi_Failure(f, ext_ptw)  => return TRi_Failure(PTW_Implicit(implicit_error(f),
                                                                              pteAddr,
                                                                              Write(Data)),
                                                                 ext_ptw),
                },
                _  => pteAddr[(sizeof(xlen) - 1) .. 0]
              };
            let mv = mem_write_value_priv(pte_phys_addr, // pteAddr,
                                          8,
                                          pte',
                                          Supervisor,
                                          false,
                                          false,
                                          false);
            match mv {
              MemValue(_) => {
                add_to_TLB(xxid, stage, vAddr, pAddr, pte', pteAddr, level, global,
                           sv_params.vpn_size_bits,    // TODO: ppn_size_bits?
                           pagesize_bits);
                TRi_Address(pAddr, ext_ptw)
              },
              MemException(e) =>
                TRi_Failure(PTW_Access(), ext_ptw)
            }
          }
        }
      }
    }
}

// PRIVATE
function translate(sv_params : SV_Params,
                   stage     : AddressTranslationStage,
                   xxid      : bits(16),
                   ptb       : bits(64),
                   vAddr_arg : bits(64),
                   ac        : AccessType(ext_access_type),
                   priv      : Privilege,
                   mxr       : bool,
                   do_sum    : bool,
                   ext_ptw   : ext_ptw)
                   -> TRi_Result = {
  let va_mask : bits(64) = zero_extend(ones(sv_params.va_size_bits));
  let vAddr   = (vAddr_arg & va_mask);

  // On first reading, assume lookup_TLB returns None(), since TLBs
  // are not part of RISC-V archticture spec (see TLB_NOTE above)
  match lookup_TLB(xxid, stage, vAddr) {
    Some(index, ent) => translate_TLB_hit(sv_params, stage, xxid, ptb, vAddr, ac, priv,
                                          mxr, do_sum, ext_ptw, index, ent),
    None()           => translate_TLB_miss(sv_params, stage, xxid, ptb, vAddr, ac, priv,
                                           mxr, do_sum, ext_ptw)
  }
}

// PRIVATE: perform address translation for a specific stage
function translate_stage(vAddr,
                         ac,
                         priv,
                         stage,
                         ext_ptw) = {
  match stage {
    S  => {
      mode = translationMode(priv, stage);
      // print("[DEBUG] Using " ^ to_str(mode) ^ " for S-stage address translation"); /* Debug: Print address translation mode */
      let (valid_va, sv_params) : (bool, SV_Params) = match mode {
        Bare => return TRi_Address(vAddr, ext_ptw),
        Sv32  => (true,                               sv32_params),
        Sv39  => (is_valid_vAddr(sv39_params, vAddr), sv39_params),
        Sv48  => (is_valid_vAddr(sv48_params, vAddr), sv48_params),
        // Sv57 => (is_valid_vAddr(sv57_params, vAddr), sv57_params),    // FUTURE
        _     => internal_error(__FILE__, __LINE__, "Invalid S-stage address translation mode")
      };
      if not(valid_va) then
        TRi_Failure(PTW_Invalid_Addr(), ext_ptw)
      else {
        let mxr    : bool     = mstatus.MXR() == 0b1;
        let do_sum : bool     = mstatus.SUM() == 0b1;
        let asid   : bits(16) = satp_to_asid(sv_params, satp);
        let ptb    : bits(64) = satp_to_PT_base(sv_params, satp);
        translate(sv_params,
                  S,
                  asid,
                  ptb,
                  vAddr,
                  ac,
                  priv,
                  mxr,
                  do_sum,
                  ext_ptw)
      }
    },
    VS => {
      mode = translationMode(priv, stage);
      // print("[DEBUG] Using " ^ to_str(mode) ^ " for VS-stage address translation"); /* Debug: Print address translation mode */
      let (valid_va, sv_params) : (bool, SV_Params) = match mode {
        Bare => return TRi_Address(vAddr, ext_ptw),
        Sv32  => (true,                               sv32_params),
        Sv39  => (is_valid_vAddr(sv39_params, vAddr), sv39_params),
        Sv48  => (is_valid_vAddr(sv48_params, vAddr), sv48_params),
        // Sv57 => (is_valid_vAddr(sv57_params, vAddr), sv57_params),    // FUTURE
        _     => internal_error(__FILE__, __LINE__, "Invalid VS-stage address translation mode")
      };
      if not(valid_va) then
        TRi_Failure(PTW_Invalid_Addr(), ext_ptw)
      else {
        let mxr    : bool     = mstatus.MXR() == 0b1 | vsstatus.MXR() == 0b1; // HS-level MXR overwrites VS-stage page protections
        let do_sum : bool     = vsstatus.SUM() == 0b1;
        let asid   : bits(16) = satp_to_asid(sv_params, vsatp);
        let ptb    : bits(64) = satp_to_PT_base(sv_params, vsatp);
        translate(sv_params,
                  VS,
                  asid,
                  ptb,
                  vAddr,
                  ac,
                  priv,
                  mxr,
                  do_sum,
                  ext_ptw)
      }
    },
    G  => {
      mode = translationMode(priv, stage);
      // print("[DEBUG] Using " ^ to_str(mode) ^ " for G-stage address translation"); /* Debug: Print address translation mode */
      let (valid_va, sv_params) : (bool, SV_Params) = match mode {
        Bare => return TRi_Address(vAddr, ext_ptw),
        Sv32x4  => (true,                                 sv32x4_params),
        Sv39x4  => (is_valid_vAddr(sv39x4_params, vAddr), sv39x4_params),
        Sv48x4  => (is_valid_vAddr(sv48x4_params, vAddr), sv48x4_params),
        // Sv57x4  => (is_valid_vAddr(sv57x4_params, vAddr), sv57x4_params), // FUTURE
        _       => internal_error(__FILE__, __LINE__, "Invalid G-stage address translation mode")
      };
      if not(valid_va) then
        TRi_Failure(PTW_Invalid_Addr(), ext_ptw)
      else {
        let mxr    : bool     = mstatus.MXR() == 0b1;
        let do_sum : bool     = mstatus.SUM() == 0b1;
        let vmid   : bits(16) = zero_extend(hgatp_to_vmid(sv_params, hgatp));
        let ptb    : bits(64) = hgatp_to_PT_base(sv_params, hgatp);
        translate(sv_params,
                  G,
                  vmid,
                  ptb,
                  vAddr,
                  ac,
                  User,                 // All G-stage memory accesses are considered User-level
                  mxr,
                  do_sum,
                  ext_ptw)
      }
    },
  }
}

// Convert exceptions resulting from G-stage page walks to architectural exceptions:
//   - Guest-page-fault exceptions are raised instead of regular page-walk exceptions
//   - Any exception is always reported for the original access type
// PRIVATE
function GStage_exception(e : ExceptionType,
                                  a : AccessType(ext_access_type))
                                  -> ExceptionType = {
  match(e) {
    E_Fetch_Addr_Align()   => E_Addr_Align_of_AccessType(a),
    E_Load_Addr_Align()    => E_Addr_Align_of_AccessType(a),
    E_SAMO_Addr_Align()    => E_Addr_Align_of_AccessType(a),
    E_Fetch_Access_Fault() => E_Access_Fault_of_AccessType(a),
    E_Load_Access_Fault()  => E_Access_Fault_of_AccessType(a),
    E_SAMO_Access_Fault()  => E_Access_Fault_of_AccessType(a),
    E_Fetch_Page_Fault()   => E_GPage_Fault_of_AccessType(a),
    E_Load_Page_Fault()    => E_GPage_Fault_of_AccessType(a),
    E_SAMO_Page_Fault()    => E_GPage_Fault_of_AccessType(a),
    E_Fetch_GPage_Fault()  => E_GPage_Fault_of_AccessType(a),
    E_Load_GPage_Fault()   => E_GPage_Fault_of_AccessType(a),
    E_SAMO_GPage_Fault()   => E_GPage_Fault_of_AccessType(a),
    _ => e // Other exceptions are not access type specific
  }
}

// Result of Address Translation (AT)
// PUBLIC
union TR_Result('paddr : Type, 'exception : Type, 'context : Type) = {
  TR_Address : ('paddr, ext_ptw),
  TR_Failure : ('exception, 'context, ext_ptw)
}

// Addr-translation function for specific privilege & virtualization mode
// PUBLIC: invoked from HLV, HSV and HLVX
function translateAddr_pv(vAddr : xlenbits,
                          ac    : AccessType(ext_access_type),
                          priv  : Privilege,
                          virt  : Virtualization)
                          -> TR_Result(xlenbits, ExceptionType, ExceptionContext) = {
  // print("[DEBUG] Translate " ^ BitStr(vAddr) ^ " for " ^ to_str(priv, virt) ^ "-mode");
  // Internally the vmem code works with 64-bit values, whether xlen==32 or xlen==64
  // This 'extend' is a no-op when xlen==64 and extends when xlen==32
  let vAddr_64b : bits(64) = zero_extend(vAddr);
  // PTW extensions (non-standard): initialize the PTW extension state
  let ext_ptw   : ext_ptw = init_ext_ptw;

  if virt == V0 then
    match translate_stage(vAddr_64b, ac, priv, S, ext_ptw) {
      TRi_Address(pa, ext_ptw) => TR_Address(truncate(pa, sizeof(xlen)), ext_ptw),
      TRi_Failure(f, ext_ptw)  => TR_Failure(translationException(ac, f),
                                             translationEContext(f, vAddr_64b, false),
                                             ext_ptw)
    }
  else
    match translate_stage(vAddr_64b, ac, priv, VS, ext_ptw) {
      TRi_Address(gpa, ext_ptw) => match translate_stage(gpa, ac, priv, G, ext_ptw){
        TRi_Address(spa, ext_ptw) => TR_Address(truncate(spa, sizeof(xlen)), ext_ptw),
        TRi_Failure(f, ext_ptw)  => TR_Failure(GStage_exception(translationException(ac, f), ac),
                                               {translationEContext(f, vAddr_64b, true) with excinfo2 = Some(truncate(gpa >> 2, sizeof(xlen)))},
                                               ext_ptw)
      },
      TRi_Failure(f, ext_ptw)  => TR_Failure(translationException(ac, f),
                                             translationEContext(f, vAddr_64b, true),
                                             ext_ptw)
    }
}

// Top-level addr-translation function
// PUBLIC: invoked from instr-fetch and load/store/amo
function translateAddr(vAddr   : xlenbits,
                       ac      : AccessType(ext_access_type),
                       width   : word_width) // FIXME: use width to verify access is permitted upto (vAddr +  width)
                      -> TR_Result(xlenbits, ExceptionType, ExceptionContext) = {
  // Effective privilege takes into account mstatus.MPRV, mstatus.MPP
  // See riscv_sys_regs.sail for effectivePrivilege() and cur_privilege
  let effPriv   : Privilege      = effectivePrivilege(ac, mstatus, cur_privilege);
  // Effective virtualization takes into account mstatus.MPRV, mstatus.MPV
  let effVirt   : Virtualization = effectiveVirtualization(ac, mstatus, mstatush, cur_virtualization);

  translateAddr_pv(vAddr, ac, effPriv, effVirt)
}

// ****************************************************************
// Initialize Virtual Memory state

// PUBLIC: invoked from init_model()
function init_vmem() -> unit = init_TLB()

// ****************************************************************
