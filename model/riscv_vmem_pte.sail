/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// ****************************************************************
// PTE (Page Table Entry) in PTN (Page Table Node)

// PTE      MSBs      PPNs      RSW    BITs
// Sv32      -       31..10    9..8    7..0
// Sv39    63..54    53..10    9..8    7..0
// Sv48    63..54    53..10    9..8    7..0

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
                             Read(_)         => false,
                             Write(_)        => true,
                             ReadWrite(_, _) => true
                           });
  // Update 'accessed'-bit?
  let update_a = (pte_flags[A] == 0b0);

  if update_d | update_a then {
    let pte_flags = [pte_flags with
                      A = 0b1,
                      D = (if update_d then 0b1 else pte_flags[D])];
    Some(pte[63 .. 8] @ pte_flags.bits)
  }
  else
    None()
}
