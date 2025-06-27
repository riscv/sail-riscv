/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// ****************************************************************
// PTE (Page Table Entry) in PTN (Page Table Node)

// PTE            EXT       PPNs      RSW   FLAGS
// Sv32            -       31..10    9..8    7..0
// Sv39/48/57    63..54    53..10    9..8    7..0

// The EXT bits of PTE are only present on RV64. They are not available on RV32
// however their default value on RV32 is not necessarily zero.

type pte_flags_bits = bits(8)

// Reserved PTE bits could be used by extensions on RV64. There are
// no such available bits on RV32.
type pte_ext_bits = bits(10)

bitfield PTE_Ext : pte_ext_bits = {
  // NAPOT page table entry
  N         : 9,
  // Page based memory types
  PBMT      : 8 .. 7,
  reserved  : 6 .. 0,
}

/*
 * On SV32, there are no reserved bits available to extensions. Therefore, by
 * default, we initialize the PTE extension field with all zeros. However,
 * extensions may wish, on SV39/48/56, to put flags in the reserved region of
 * those PTEs. To avoid the need for "inhibit" bits in extensions (i.e., so
 * that extensions can use the more common and more RISC-V flavored "enable"
 * disposition), we allow extensions to use any constant value by overriding
 * this default_sv32_ext_pte value.
 */
let default_sv32_ext_pte : pte_ext_bits = zeros()

// PRIVATE: extract ext bits of PTE above the PPN.
val ext_bits_of_PTE : forall 'pte_size, 'pte_size in {32, 64}. bits('pte_size) -> PTE_Ext
function ext_bits_of_PTE(pte) =
  Mk_PTE_Ext(if 'pte_size == 64 then pte[63 .. 54] else default_sv32_ext_pte)

// PRIVATE: extract full PPN from a PTE
val PPN_of_PTE : forall 'pte_size, 'pte_size in {32, 64}.
  bits('pte_size) -> bits(if 'pte_size == 32 then 22 else 44)
function PPN_of_PTE(pte) = if 'pte_size == 32 then pte[31 .. 10] else pte[53 .. 10]

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
function pte_is_non_leaf(pte_flags : PTE_Flags) -> bool =
    pte_flags[X] == 0b0
  & pte_flags[W] == 0b0
  & pte_flags[R] == 0b0

// Not supported in the model yet.
function clause currentlyEnabled(Ext_Svnapot) = false
function clause currentlyEnabled(Ext_Svpbmt) = false

// PRIVATE: check if a PTE is valid
function pte_is_invalid(pte_flags : PTE_Flags, pte_ext : PTE_Ext) -> bool =
    pte_flags[V] == 0b0
  | (pte_flags[W] == 0b1 & pte_flags[R] == 0b0)
  // Early versions of the spec did not require reserved bits to be zero.
  | pte_reserved_bits_must_be_zero & (
    // All bits are currently reserved for non-leaf PTEs.
      pte_is_non_leaf(pte_flags) & pte_ext.bits != zeros()
    // N/PBMT are reserved if not implemented.
    | pte_ext[N]        != zeros() & not(currentlyEnabled(Ext_Svnapot))
    | pte_ext[PBMT]     != zeros() & not(currentlyEnabled(Ext_Svpbmt))
    // Other bits are reserved even for leaf PTEs.
    | pte_ext[reserved] != zeros()
  )

// ----------------
// Check access permissions in PTE

// For (non-standard) extensions: this function gets the extension-available bits
// of the PTE in PTE_Ext, and the accumulated information of the page-table-walk
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
                              ext       : PTE_Ext,
                              ext_ptw   : ext_ptw) -> PTE_Check = {
  let pte_U = pte_flags[U];
  let pte_R = pte_flags[R];
  let pte_W = pte_flags[W];
  let pte_X = pte_flags[X];
  let success : bool =
    match (ac, priv) {
      // Steps 6 and 8 of VATP, roughly (see riscv_vmem.sail).
      // (TODO: Step 7 awaits shadow stack implementation (Zicfiss).)
      (Read(_),         User)       => (pte_U == 0b1)
                                       & ((pte_R == 0b1)
                                          | ((pte_X == 0b1 & mxr))),
      (Write(_),        User)       => (pte_U == 0b1) & (pte_W == 0b1),
      (ReadWrite(_, _), User)       => (pte_U == 0b1)
                                       & (pte_W == 0b1)
                                       & ((pte_R == 0b1) | ((pte_X == 0b1) & mxr)),
      (InstructionFetch(),    User) => (pte_U == 0b1) & (pte_X == 0b1),
      (Read(_),         Supervisor) => ((pte_U == 0b0) | do_sum)
                                       & ((pte_R == 0b1) | ((pte_X == 0b1) & mxr)),
      (Write(_),        Supervisor) => ((pte_U == 0b0) | do_sum)
                                       & (pte_W == 0b1),
      (ReadWrite(_, _), Supervisor) => ((pte_U == 0b0) | do_sum)
                                       & (pte_W == 0b1)
                                       & ((pte_R == 0b1)
                                          | ((pte_X == 0b1) & mxr)),
      (InstructionFetch(),Supervisor) => (pte_U == 0b0) & (pte_X == 0b1),
      (_,               Machine)    => internal_error(__FILE__, __LINE__,
                                                      "m-mode mem perm check")};
  if success then PTE_Check_Success(())
  else            PTE_Check_Failure((), ())
}

// Update PTE bits if needed; return new PTE if updated
// PRIVATE
function update_PTE_Bits forall 'pte_size, 'pte_size in {32, 64} . (
  pte : bits('pte_size),
  a   : AccessType(ext_access_type),
) -> option(bits('pte_size)) = {
  let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);

  // Update 'dirty' bit?
  let update_d : bool = (pte_flags[D] == 0b0)
                        & (match a {
                             InstructionFetch() => false,
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
    Some([pte with 7 .. 0 = pte_flags.bits])
  } else {
    None()
  }
}
