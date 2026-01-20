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

// Extract ext bits of PTE above the PPN.
private val ext_bits_of_PTE : forall 'pte_size, 'pte_size in {32, 64}. bits('pte_size) -> PTE_Ext
function ext_bits_of_PTE(pte) =
  Mk_PTE_Ext(if 'pte_size == 64 then pte[63 .. 54] else default_sv32_ext_pte)

// Extract full PPN from a PTE
private val PPN_of_PTE : forall 'pte_size, 'pte_size in {32, 64}.
  bits('pte_size) -> bits(if 'pte_size == 32 then 22 else 44)
function PPN_of_PTE(pte) = if 'pte_size == 32 then pte[31 .. 10] else pte[53 .. 10]

// 8 LSBs of PTEs in Sv32, Sv39, Sv48 and Sv57
// TODO: This would ideally be private.
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

// Check if a PTE is a pointer to next level (non-leaf)
private function pte_is_non_leaf(pte_flags : PTE_Flags) -> bool =
    pte_flags[X] == 0b0
  & pte_flags[W] == 0b0
  & pte_flags[R] == 0b0

// Not supported in the model yet.
function clause currentlyEnabled(Ext_Svnapot) = false
function clause currentlyEnabled(Ext_Svpbmt) = false

// Svrsw60t59b: PTE Reserved for software bits 60-59
function clause currentlyEnabled(Ext_Svrsw60t59b) = hartSupports(Ext_Svrsw60t59b) & currentlyEnabled(Ext_Sv39)

// Check if a PTE is valid
private function pte_is_invalid(pte_flags : PTE_Flags, pte_ext : PTE_Ext) -> bool =
    pte_flags[V] == 0b0
  // The encoding R=0, W=1, and X=0, is defined to represent an SS
  // page. When menvcfg.SSE=0, this encoding remains reserved.
  // TODO: handle V=1 and henvcfg.SSE=0 at VS/VU levels
  | (pte_flags[R] == 0b0 & pte_flags[W] == 0b1 & pte_flags[X] == 0b0 & menvcfg[SSE] == 0b0)
  | (pte_flags[R] == 0b0 & pte_flags[W] == 0b1 & pte_flags[X] == 0b1)
  // Note, the following requirements depend on the privileged spec version.
  // Early versions do not require this check. This will need to be behind
  // a flag when the Sail model allows specifying the spec version.
  | (pte_ext[N] != 0b0 & not(currentlyEnabled(Ext_Svnapot)))
  | (pte_ext[PBMT] != zeros() & not(currentlyEnabled(Ext_Svpbmt)))
  | (pte_ext[RSW_60t59b] != zeros() & not(currentlyEnabled(Ext_Svrsw60t59b)))
  | pte_ext[reserved] != zeros()

// ----------------
// Check access permissions in PTE

union pte_check_failure = {
  PTE_No_Permission : unit,
  PTE_No_Access     : unit,
  PTE_Ext_Failure   : ext_ptw_fail
}

// For (non-standard) extensions: this function gets the extension-available bits
// of the PTE in extPte, and the accumulated information of the page-table-walk
// in ext_ptw. It should return the updated ext_ptw in both success and failure cases.

union PTE_Check = {
  PTE_Check_Success : ext_ptw,
  PTE_Check_Failure : (ext_ptw, pte_check_failure)
}

// This assumes that the PTE is valid; i.e. `pte_is_invalid` has been checked before
// calling this function.
private function check_PTE_permission(
  access    : MemoryAccessType(mem_payload),
  priv      : Privilege,
  // Make eXecutable Readable
  mxr       : bool,
  // permit Supervisor User Memory access
  do_sum    : bool,
  pte_flags : PTE_Flags,
  _ext      : PTE_Ext,
  _ext_ptw  : ext_ptw
) -> PTE_Check = {
  let pte_U = bit_to_bool(pte_flags[U]);
  let pte_R = bit_to_bool(pte_flags[R]);
  let pte_W = bit_to_bool(pte_flags[W]);
  let pte_X = bit_to_bool(pte_flags[X]);

  // Since we assume a valid PTE: Writable pages must be readable. Write-only
  // pages are reserved.
  assert(pte_W ==> pte_R);

  // Step 6 of VATP (see vmem.sail).
  let priv_ok : bool = match priv {
    User       => pte_U,
    // SUM allows supervisor mode to access U-mode pages, but only for
    // loads and stores; not instruction fetch.
    Supervisor => not(pte_U) | (do_sum & is_load_store(access)),
    Machine    => internal_error(__FILE__, __LINE__, "m-mode mem perm check"),
    VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
  };
  if not(priv_ok) then return PTE_Check_Failure((), PTE_No_Permission());

  // Step 7 of VATP (see vmem.sail).

  // Enforce Shadow Stack (SS) protection rules for a shadow stack page.
  if not(pte_R) & pte_W & not(pte_X) then {
    // Since we assume a valid PTE: this encoding is only valid when menvcfg[SSE] is 1.
    assert(bool_bit(menvcfg[SSE]));

    let shadow_stack_ok : bool = match access {
      // "Implicit accesses, including instruction fetches to an SS page, are not permitted.
      // Such accesses will raise an access-fault exception appropriate to the access type."
      InstructionFetch() => false,
      // "the shadow stack is readable by all instructions that only load from
      // memory."
      Load(Data)         => true,
      Load(ShadowStack)  => true,
      LoadReserved(Data) => true,

      // "Memory mapped as an SS page cannot be written to by instructions other
      // than SSAMOSWAP.W/D, SSPUSH, and C.SSPUSH."
      Store(Data)                         => false,
      StoreConditional(Data)              => false,
      Atomic(_, Data, Data)               => false,
      Store(ShadowStack)                  => true,
      Atomic(_, ShadowStack, ShadowStack) => true,

      // "Access to a SS page using cache-block operation (CBO.*) instructions
      // is not permitted. Such accesses will raise a store/AMO access-fault
      // exception."
      CacheAccess(_) => false,

      LoadReserved(ShadowStack)      => internal_error(__FILE__, __LINE__, "Invalid payload (ShadowStack) for LoadReserved."),
      StoreConditional(ShadowStack)  => internal_error(__FILE__, __LINE__, "Invalid payload (ShadowStack) for StoreConditional."),
      Atomic(_, ShadowStack, Data)   => internal_error(__FILE__, __LINE__, "Invalid payloads (ShadowStack, Data) for Atomic."),
      Atomic(_, Data, ShadowStack)   => internal_error(__FILE__, __LINE__, "Invalid payloads (Data, ShadowStack) for Atomic."),

    };
    if not(shadow_stack_ok) then return PTE_Check_Failure((), PTE_No_Access());
  } else if is_shadow_stack_access(access) then {
    // "Should a shadow stack instruction access a page that is not designated
    // as a shadow stack page and is not marked as read-only (pte.xwr=001), a
    // store/AMO access-fault exception will be invoked. Conversely, if the page
    // being accessed by a shadow stack instruction is a read-only page, a
    // store/AMO page-fault exception will be triggered."
    let is_read_only = pte_R & not(pte_W) & not(pte_X);
    return PTE_Check_Failure((), if is_read_only then PTE_No_Permission() else PTE_No_Access());
  };

  // Step 8 of VATP (see vmem.sail).

  // Handle `mxr` (Make eXecutable Readable).
  let pte_R = pte_R | (pte_X & mxr);
  let access_ok : bool = match access {
    Load(_)                     => pte_R,
    LoadReserved(_)             => pte_R,
    Store(_)                    => pte_W,
    StoreConditional(_)         => pte_W,
    Atomic(_, _, _)             => pte_W & pte_R,
    InstructionFetch(_)         => pte_X,
    CacheAccess(CB_zero())      => pte_W,
    CacheAccess(CB_prefetch(p)) => match p {
      PREFETCH_R => pte_R,
      PREFETCH_W => pte_W,
      PREFETCH_I => pte_X,
    },
    // "A cache-block management instruction is permitted to access
    // the specified cache block whenever a load instruction or store
    // instruction is permitted to access the corresponding physical
    // addresses."
    //
    // TODO: "If neither a load instruction nor store instruction is
    // permitted to access the physical addresses, but an instruction
    // fetch is permitted to access the physical addresses, whether a
    // cache-block management instruction is permitted to access the
    // cache block is UNSPECIFIED."
    CacheAccess(CB_manage(_))   => pte_R | pte_W,
  };
  if not(access_ok) then return PTE_Check_Failure((), PTE_No_Permission());

  PTE_Check_Success(())
}

// Update PTE bits if needed; return new PTE if updated
private function update_PTE_Bits forall 'pte_size, 'pte_size in {32, 64} . (
  pte : bits('pte_size),
  access : MemoryAccessType(mem_payload),
) -> option(bits('pte_size)) = {
  let pte_flags = Mk_PTE_Flags(pte[7 .. 0]);

  // Update 'dirty' bit?
  let update_d : bool = (pte_flags[D] == 0b0)
                        & (match access {
                             InstructionFetch()          => false,
                             Load(_)                     => false,
                             LoadReserved(_)             => false,
                             Store(_)                    => true,
                             // NOTE: According to the spec: "it is UNSPECIFIED
                             // whether any side effects of implicit address
                             // translation and protection memory accesses (such
                             // as setting a page-table entry D bit) occur on a
                             // failed SC.W."  However, at this point, we do not
                             // know whether the SC is going to succeed or fail,
                             // since the PMA/PMP checks are done after address
                             // translation.  In order to be correct for an SC
                             // that succeeds, we update the D bit of the PTE
                             // here.  TODO: support the alternative: i.e.,
                             // _not_ update the D bit if the SC fails for
                             // whatever reason.
                             StoreConditional(_)         => true,
                             Atomic(_, _, _)             => true,
                             // "As implied by omission, a cache-block
                             // management instruction does not check the dirty
                             // bit and neither raises an exception nor sets the
                             // bit."
                             CacheAccess(CB_manage(_))   => false,
                             // "During address translation, the
                             // [cache-block zero] instruction also
                             // checks the accessed and dirty bits and
                             // may either raise an exception or set the
                             // bits as required."
                             CacheAccess(CB_zero())      => true,
                             // "During address translation, the [cache-block
                             // prefetch] instruction does not check the
                             // accessed and dirty bits and neither raises an
                             // exception nor sets the bits."
                             CacheAccess(CB_prefetch(_)) => false,
                           });
  // Update 'accessed' bit?
  // Cache-block management and zero instructions update the accessed bit,
  // but cache-block prefetch instructions do not.
  let update_a = (pte_flags[A] == 0b0) & not(is_prefetch_access(access));

  if update_d | update_a then {
    let pte_flags = [pte_flags with
                      A = 0b1,
                      D = (if update_d then 0b1 else pte_flags[D])];
    Some([pte with 7 .. 0 = pte_flags.bits])
  } else {
    None()
  }
}
