// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

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
  N          : 9,
  // Page based memory types
  PBMT       : 8 .. 7,
  // Svrsw60t59b: Additional reserved-for-software bits
  RSW_60t59b : 6 .. 5,
  reserved   : 4 .. 0,
}

//
// On SV32, there are no reserved bits available to extensions. Therefore, by
// default, we initialize the PTE extension field with all zeros. However,
// extensions may wish, on SV39/48/56, to put flags in the reserved region of
// those PTEs. To avoid the need for "inhibit" bits in extensions (i.e., so
// that extensions can use the more common and more RISC-V flavored "enable"
// disposition), we allow extensions to use any constant value by overriding
// this default_sv32_ext_pte value.
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

// Svrsw60t59b: PTE Reserved for software bits 60-59
function clause currentlyEnabled(Ext_Svrsw60t59b) = hartSupports(Ext_Svrsw60t59b) & currentlyEnabled(Ext_Sv39)

// PRIVATE: check if a PTE is valid
function pte_is_invalid(pte_flags : PTE_Flags, pte_ext : PTE_Ext) -> bool =
    pte_flags[V] == 0b0
  | (pte_flags[W] == 0b1 & pte_flags[R] == 0b0)
  // Early versions of the spec did not require reserved bits to be zero.
  | pte_reserved_bits_must_be_zero & (
    // All bits are currently reserved for non-leaf PTEs.
      pte_is_non_leaf(pte_flags) & pte_ext.bits != zeros()
    // N/PBMT/60t59b are reserved if not implemented.
    | pte_ext[N]          != zeros() & not(currentlyEnabled(Ext_Svnapot))
    | pte_ext[PBMT]       != zeros() & not(currentlyEnabled(Ext_Svpbmt))
    | pte_ext[RSW_60t59b] != zeros() & not(currentlyEnabled(Ext_Svrsw60t59b))
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
                              // Make eXecutable Readable
                              mxr       : bool,
                              // permit Supervisor User Memory access
                              do_sum    : bool,
                              pte_flags : PTE_Flags,
                              ext       : PTE_Ext,
                              ext_ptw   : ext_ptw) -> PTE_Check = {
  let pte_U = bits_to_bool(pte_flags[U]);
  let pte_R = bits_to_bool(pte_flags[R]);
  let pte_W = bits_to_bool(pte_flags[W]);
  let pte_X = bits_to_bool(pte_flags[X]);

  // Steps 6 and 8 of VATP, roughly (see vmem.sail).
  // (TODO: Step 7 awaits shadow stack implementation (Zicfiss).)
  let access_ok : bool = match ac {
    Read(_)             => pte_R | (pte_X & mxr),
    Write(_)            => pte_W,
    ReadWrite(_, _)     => pte_W & (pte_R | (pte_X & mxr)),
    InstructionFetch(_) => pte_X,
  };

  let priv_ok : bool = match priv {
    User       => pte_U,
    // SUM allows supervisor mode to access U-mode pages, but only for
    // loads and stores; not instruction fetch.
    Supervisor => not(pte_U) | (do_sum & is_load_store(ac)),
    Machine    => internal_error(__FILE__, __LINE__, "m-mode mem perm check"),
    VirtualUser => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
  };

  if access_ok & priv_ok then PTE_Check_Success(()) else PTE_Check_Failure((), ())
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
