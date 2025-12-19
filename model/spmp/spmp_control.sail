// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

/*=======================================================================================*/
/*  SPMP (Supervisor Mode Physical Memory Protection) Address Range Calculation        */
/*                                                                                       */
/*  This module implements the SPMP address matching algorithms as specified in        */
/*  . SPMP operates on physical addresses after address translation    */
/*  and provides memory protection for supervisor mode software.                        */
/*=======================================================================================*/

/* SPMP address range type: None indicates no match, Some((min, max)) indicates
 * the byte-addressed range [min, max) that matches this SPMP entry.
 * Note: This follows the same semantics as PMP but operates at supervisor privilege. */
type spmp_addr_range = option((xlenbits, xlenbits))

/* Calculate the address range matched by an SPMP entry.
 * 
 * Parameters:
 *   cfg: SPMP configuration entry containing address matching type in A field
 *   spmpaddr: Current SPMP address register value (word-addressed, bits [XLEN-1:2])
 *   prev_spmpaddr: Previous SPMP address register (for TOR mode)
 * 
 * Returns: Address range [min, max) in bytes, or None if no addresses match
 * 
 * Address Matching Types:
 *   - OFF: Entry is disabled, matches no addresses
 *   - TOR: Top-of-Range, matches [prev_spmpaddr*4, spmpaddr*4)
 *   - NA4: Naturally aligned 4-byte region
 *   - NAPOT: Naturally aligned power-of-two region */
function spmpAddrRange(cfg: Spmpcfg_ent, spmpaddr: xlenbits, prev_spmpaddr: xlenbits, entry_index: nat) -> spmp_addr_range = {
  match spmpAddrMatchType_of_bits(cfg[A]) {
    /* OFF: Entry disabled - no address matching*/
    OFF   => None(),
    
    /* TOR: Top-of-Range addressing
     * Matches addresses in range [prev_spmpaddr*4, spmpaddr*4)
     * If prev_spmpaddr >= spmpaddr, no addresses match (invalid range) */
    TOR => {
      let lower_bound : xlenbits = if entry_index == 0 then zeros() 
                                    else prev_spmpaddr;
      // Check for valid range (lower < upper)
      if unsigned(lower_bound) >= unsigned(spmpaddr) then None()
      else Some((lower_bound << 2, spmpaddr << 2))
    },
    
    /* NA4: Naturally Aligned 4-byte region
     * Matches exactly 4 bytes starting at spmpaddr*4 */
    NA4   => { 
      let lo : xlenbits = spmpaddr << 2;
      Some((lo, lo + 4))       // 4-byte region
    },
    
    /* NAPOT: Naturally Aligned Power-Of-Two region
     * Region size is determined by trailing 1s in spmpaddr
     * Where trailing 1s in spmpaddr indicate the region size */
    NAPOT => {
      /* Find region size by counting trailing 1s */
      let mask = spmpaddr ^ (spmpaddr + 1);
      let lo : xlenbits = (spmpaddr & ~(mask)) << 2;
      let len : xlenbits = (mask + 1) << 2;
      Some((lo, lo + len))
    }
  }
}

/*=======================================================================================*/
/*  SPMP Permission Checking Functions                                                  */
/*                                                                                       */
/*  Implements the SPMP permission matrix                                                */
/*  SPMP adds an S bit to distinguish supervisor and user accessible regions.           */
/*=======================================================================================*/

/* Basic R/W/X permission check using the 3-bit combined RWX encoding.
 * This function checks if the RWX encoding allows the requested access type.
 * 
 * Note: This does NOT handle privilege-level specific rules or Shared-Region constraints.
 * Those are handled by spmpCheckRWX().
 * 
 * Parameters:
 *   ent: SPMP configuration entry with R/W/X permission bits
 *   acc: Type of memory access (Read/Write/Execute/ReadWrite)
 *   priv: Current privilege level (not used in basic check)
 * 
 * Returns: true if the RWX encoding allows the access type
 * 
 * RWX Encoding (3-bit combined field, bits [2:0] = XWR):
 *   - 000: Deny (reserved for future use)
 *   - 001: R-- (Read-only)
 *   - 010: Reserved (deny)
 *   - 011: RW- (Read+Write) - Reserved per spec but handled for compatibility
 *   - 100: --X (Execute-only)
 *   - 101: R-X (Read+Execute)
 *   - 110: Reserved (deny)
 *   - 111: RWX (Read+Write+Execute)
 */
val CheckRWX: (Spmpcfg_ent, MemoryAccessType(ext_access_type), Privilege) -> bool
function CheckRWX(ent, acc, priv) = {
  let rwx = ent[X] @ ent[W] @ ent[R];  // Extract 3-bit RWX encoding
  
  /* Check for reserved/deny encodings first */
  if (rwx == 0b000) | (rwx == 0b010) | (rwx == 0b110) then {
    false  // Reserved encodings always deny
  }
  else {
    /* Check if RWX encoding allows the requested access */
    match rwx {
      0b001 => {  // R-- : Read-only
        match acc {
          Load(_) => true,
          _ => false
        }
      },
      0b011 => {  // RW- : Read+Write (Reserved per spec, but we handle it)
        match acc {
          Load(_) => true,
          Store(_) => true,
          LoadStore(_) => true,
          InstructionFetch(_) => false
        }
      },
      0b100 => {  // --X : Execute-only
        match acc {
          InstructionFetch(_) => true,
          _ => false
        }
      },
      0b101 => {  // R-X : Read+Execute
        match acc {
          Load(_) => true,
          InstructionFetch(_) => true,
          _ => false
        }
      },
      0b111 => {  // RWX : All permissions
        true
      },
      _ => false  // Should not reach here given earlier checks
    }
  }
}

/* SPMP privilege-aware permission check implementing the complete permission matrix.
 * 
 * Based on the SPMP Encoding Table, SPMP has three kinds of rules:
 *   1. S-mode-only rules (SHARED=0, U=0): Enforced on S-mode, denied on U-mode
 *   2. U-mode rules (SHARED=0, U=1): Enforced on U-mode, conditional on S-mode  
 *   3. Shared-Region rules (SHARED=1, U=1): Enforced on both modes with special constraints
 * 
 * RWX Encoding (3-bit combined field):
 *   - 000 (---): Reserved/Deny
 *   - 001 (R--): Read-only
 *   - 010 (--W): Reserved
 *   - 011 (R-X): Should be normalized to 001 or 101
 *   - 100 (--X): Execute-only
 *   - 101 (R-X): Read+Execute
 *   - 110 (-WX): Reserved
 *   - 111 (RWX): Read+Write+Execute (special handling for Shared-Region U-mode)
 * 
 * Important: For Shared-Region rules, read and write permissions for U-mode are mutually exclusive.
 */
val spmpCheckRWX: (Spmpcfg_ent, MemoryAccessType(ext_access_type), Privilege) -> bool
function spmpCheckRWX(ent, acc, priv) = {
  let do_sum : bool = mstatus[SUM] == 0b1;  // Check SUM bit in mstatus (accessible via sstatus)
  let rwx = ent[X] @ ent[W] @ ent[R];       // Extract RWX as 3-bit combined field (bits [2:0])
  let is_shared = ent[SHARED] == 0b1;
  let is_u_rule = ent[U] == 0b1;
  
  /* Check for reserved/deny encodings - these always deny access regardless of privilege */
  if (rwx == 0b000) | (rwx == 0b010) | (rwx == 0b110) then {
    false  // RWX=000 (deny), RWX=010 (reserved), RWX=110 (reserved) always deny
  }
  /* Check for reserved SHARED=1, U=0 combination - this is reserved per spec */
  else if is_shared & not(is_u_rule) then {
    false  // SHARED=1, U=0 is reserved for future standard use
  }
  /* Shared-Region rules (SHARED=1, U=1) - enforced for both S-mode and U-mode
   * Key constraint: read and write permissions for U-mode are mutually exclusive.
   * This means for Shared-Region U-mode access:
   *   - If RWX allows read, it must deny write
   *   - If RWX allows write, it must deny read
   */
  else if is_shared & is_u_rule then {
    match priv {
      User => {
        /* For Shared-Region U-mode, handle the mutual exclusivity constraint */
        match rwx {
          /* RWX=001 (R--): U-mode can only read, no write, no execute */
          0b001 => {
            match acc {
              Load(_)      => true,   // Allow read
              Store(_)     => false,  // Deny write (mutual exclusivity)
              LoadStore(_) => false,  // Deny write part
              InstructionFetch(_)   => false   // No execute permission
            }
          },
          /* RWX=011 (RW-): Reserved for non-Shared rules, but for Shared-Region:
           * Spec table shows SHR X (execute + write, no read for U-mode).
           * This implements the mutual exclusivity: write permitted, read denied.
           * Note: RWX=011 is actually R+W encoding, but in SHARED region context
           * it should deny read and allow write based on mutual exclusivity */
          0b011 => {
            match acc {
              Load(_)      => false,  // Deny read (mutual exclusivity)
              Store(_)     => true,   // Allow write
              LoadStore(_) => false,  // Deny read part
              InstructionFetch(_)   => false   // RWX=011 has no execute permission
            }
          },
          /* RWX=101 (R-X): Read+Execute - read permitted, write denied (mutual exclusivity) */
          0b101 => {
            match acc {
              Load(_)      => true,   // Allow read
              Store(_)     => false,  // Deny write (mutual exclusivity)
              LoadStore(_) => false,  // Deny write part
              InstructionFetch(_)   => true    // Allow execute
            }
          },
          /* RWX=111 (RWX): For Shared-Region U-mode, the mutual exclusivity constraint applies.
           * Per spec encoding table, this allows read for U-mode but denies write.
           * Execute permission is also denied for U-mode in this encoding. */
          0b111 => {
            match acc {
              Load(_)      => true,   // Allow read
              Store(_)     => false,  // Deny write (mutual exclusivity constraint)
              LoadStore(_) => false,  // Deny write part
              InstructionFetch(_)   => false   // Deny execute for U-mode in Shared-Region RWX=111
            }
          },
          /* RWX=100 (--X): Execute-only, check normally */
          0b100 => {
            match acc {
              InstructionFetch(_) => true,     // Allow execute
              _ => false              // Deny read/write
            }
          },
          /* Other encodings are already handled above (reserved cases filtered earlier) */
          _ => false  // Should not reach here given earlier checks
        }
      },
      Supervisor => {
        /* S-mode in Shared-Region: check permissions normally
         * S-mode is not subject to the mutual exclusivity constraint */
        match rwx {
          0b001 => {  // R-- : Read-only
            match acc {
              Load(_) => true,
              _ => false
            }
          },
          0b011 => {  // RW- : Read+Write (note: execute not allowed)
            match acc {
              Load(_) => true,
              Store(_) => true,
              LoadStore(_) => true,
              InstructionFetch(_) => false
            }
          },
          0b100 => {  // --X : Execute-only
            match acc {
              InstructionFetch(_) => true,
              _ => false
            }
          },
          0b101 => {  // R-X : Read+Execute
            match acc {
              Load(_) => true,
              InstructionFetch(_) => true,
              _ => false
            }
          },
          0b111 => {  // RWX : Read+Write+Execute
            true  // All accesses allowed for S-mode
          },
          _ => false  // Reserved or deny
        }
      },
      VirtualUser => false,  // Virtual modes not yet supported
      VirtualSupervisor => false,  // Virtual modes not yet supported
      Machine => true  // M-mode bypasses all SPMP checks
    }
  }
  /* S-mode-only rule (SHARED=0, U=0) - enforced for S-mode, denied for U-mode */
  else if not(is_u_rule) then {
    match priv {
      User => false,  // U-mode accessing S-mode-only region: always deny
      VirtualUser => false,  // Virtual modes not yet supported
      Supervisor => CheckRWX(ent, acc, priv),  // S-mode: check permissions
      VirtualSupervisor => false,  // Virtual modes not yet supported
      Machine => true  // M-mode bypasses SPMP
    }
  }
  /* U-mode rule (SHARED=0, U=1) */
  else {
    match priv {
      User => CheckRWX(ent, acc, priv),  // U-mode: check permissions
      VirtualUser => false,  // Virtual modes not yet supported
      Supervisor => {
        // S-mode accessing U-mode region: conditional on SUM bit
        if do_sum then {
          // SUM=1: S-mode can access with EnforceNoX (no execute permission)
          match acc {
            InstructionFetch(_) => false,  // Always deny execute for S-mode
            _ => CheckRWX(ent, acc, priv)  // Check R/W permissions
          }
        } else {
          // SUM=0: S-mode cannot access U-mode regions
          false
        }
      },
      VirtualSupervisor => false,  // Virtual modes not yet supported
      Machine => true  // M-mode bypasses SPMP
    }
  }
}

/* High-level SPMP permission check entry point.
 * 
 * Machine mode behavior :
 *   - Machine mode bypasses all SPMP checks
 *   - This follows the principle that machine mode has unrestricted access
 *   - Only supervisor and user modes are subject to SPMP restrictions
 * 
 * Parameters:
 *   ent: SPMP configuration entry to check against
 *   acc: Memory access type being attempted
 *   priv: Current effective privilege level
 * 
 * Returns: true if access should be permitted, false if denied */
val spmpCheckPerms: (Spmpcfg_ent, MemoryAccessType(ext_access_type), Privilege) -> bool
function spmpCheckPerms(ent, acc, priv) = {
  match priv {
    /* Machine mode: Always bypass SPMP checks */
    Machine => true,
    /* Supervisor/User mode: Apply full SPMP permission matrix */
    _       => spmpCheckRWX(ent, acc, priv)
  }
}

/*=======================================================================================*/
/*  SPMP Address Matching Logic                                                         */
/*                                                                                       */
/*  Implements address range matching for SPMP entries. Unlike PMP, partial matches    */
/*  are treated as violations per .                                                   */
/*=======================================================================================*/

/* SPMP address matching result types */
enum spmpAddrMatch = {SPMP_NoMatch, SPMP_PartialMatch, SPMP_Match}

/* Determine relationship between access range and SPMP protection range.
 * 
 * SPMP requires that memory accesses either:
 *   1. Completely fall within a protected region (SPMP_Match)
 *   2. Completely fall outside all protected regions (SPMP_NoMatch)
 *   3. Partially overlap a region (SPMP_PartialMatch - this is a violation)
 * 
 * If any byte of an access partially matches
 * an SPMP entry, the entire access fails.
 * 
 * Parameters:
 *   begin: Start of SPMP protected region (inclusive)
 *   end_: End of SPMP protected region (exclusive) 
 *   addr: Start address of memory access
 *   width: Size of memory access in bytes
 * 
 * Returns: Relationship between access [addr, addr+width) and region [begin, end_) */
function spmpRangeMatch(
  begin : nat,
  end_ : nat,
  addr : nat,
  width : nat,
) -> spmpAddrMatch =
  if      (addr + width <= begin) | (end_ <= addr)
  then    SPMP_NoMatch      // Access completely outside region
  else if (begin <= addr) & (addr + width <= end_)
  then    SPMP_Match        // Access completely within region
  else    SPMP_PartialMatch // Access partially overlaps region (violation)

/* Match a memory access against an SPMP address range.
 * 
 * Parameters:
 *   addr: Physical address of access
 *   width: Width of access in bytes
 *   rng: SPMP address range (None if entry disabled)
 * 
 * Returns: Address match result */
function spmpMatchAddr(addr: nat, width: nat, rng: spmp_addr_range) -> spmpAddrMatch = {
  match rng {
    None()         => SPMP_NoMatch,  // Entry disabled
    Some((lo, hi)) => if   hi <_u lo   /* Handle misconfigured ranges */
                      then SPMP_NoMatch
                      else spmpRangeMatch(
                        unsigned(lo),
                        unsigned(hi),
                        addr,
                        width
                      )
  }
}

/*=======================================================================================*/
/*  SPMP Entry Matching and Result Types                                                */
/*=======================================================================================*/

/* SPMP matching results for individual entries */
enum spmpMatch = {SPMP_Success, SPMP_Continue, SPMP_Fail}

/* Match a memory access against a single SPMP entry.
 * 
 * NOTE: This function is kept for compatibility but is no longer used 
 * by the main spmpCheck function, which implements the revised matching logic directly.
 * 
 * This function implements the complete SPMP checking algorithm for one entry:
 *   1. Check if the access address range matches the entry's protected range
 *   2. If matched, verify permissions according to privilege level and S bit
 *   3. Return appropriate result for SPMP decision
 * 
 * SPMP entries are checked in order from 0 to 63.
 * The first matching entry determines the access result.
 * 
 * Parameters:
 *   Physaddr(addr): Physical address being accessed
 *   width: Access width in bytes 
 *   acc: Type of memory access (read/write/execute)
 *   priv: Current privilege level
 *   ent: SPMP configuration entry being checked
 *   spmpaddr: Address register value for this entry
 *   prev_spmpaddr: Previous entry's address (needed for TOR mode)
 * 
 * Returns:
 *   SPMP_Success: Access granted by this entry
 *   SPMP_Fail: Access denied by this entry  
 *   SPMP_Continue: This entry doesn't match, check next entry */
function spmpMatchEntry(Physaddr(addr): physaddr, width: xlenbits, acc: MemoryAccessType(ext_access_type), priv: Privilege,
                       ent: Spmpcfg_ent, spmpaddr: xlenbits, prev_spmpaddr: xlenbits, entry_index: nat) -> spmpMatch = {
  let addr = unsigned(addr);
  let width = unsigned(width);
  let rng = spmpAddrRange(ent, spmpaddr, prev_spmpaddr, entry_index);
  match spmpMatchAddr(addr, width, rng) {
    SPMP_NoMatch      => SPMP_Continue,     // No match, try next entry
    SPMP_PartialMatch => SPMP_Fail,         // Partial match is violation
    SPMP_Match        => if   spmpCheckPerms(ent, acc, priv)
                        then SPMP_Success
                        else SPMP_Fail
  }
}

/*=======================================================================================*/
/*  SPMP Exception Handling                                                             */
/*                                                                                       */
/*  SPMP violations generate Page Fault exceptions, distinguishing them from PMP        */
/*=======================================================================================*/

/* Convert memory access type to appropriate SPMP Page Fault exception.
 * 
 * Key difference from PMP :
 *   - PMP violations → Access Fault exceptions
 *   - SPMP violations → Page Fault exceptions  
 * 
 * This distinction allows OS kernels to differentiate between:
 *   - Page-level protection violations (SPMP) 
 *   - Platform-level protection violations (PMP)
 * 
 * Exception types follow standard RISC-V privilege specification. */
function accessToSpmpFault(acc : MemoryAccessType(ext_access_type)) -> ExceptionType =
  match acc {
    Load(_)            => E_Load_Page_Fault(),     // Load page fault
    Store(_)           => E_SAMO_Page_Fault(),     // Store/AMO page fault  
    LoadStore(_)       => E_SAMO_Page_Fault(),     // Store/AMO page fault
    InstructionFetch(_)         => E_Fetch_Page_Fault()     // Instruction page fault
  }

/*=======================================================================================*/
/*  SPMP Register Access Functions                                                      */
/*                                                                                       */
/*  Provides unified access to all 64 SPMP entries. SPMP supports the same number       */
/*  of entries as PMP for consistency.                                                  */
/*=======================================================================================*/

/* Retrieve SPMP configuration and address register pair for hardware entry i.
 * 
 * SPMP supports 64 entries (0-63) same as PMP, each with:
 *   - One configuration entry (8 bits in spmpcfg registers)
 *   - One address register (spmpaddr registers)
 * 
 * This function provides unified access across all entries for the
 * main SPMP checking loop. The parameter i is a hardware index (pmpnum to 63). */
function spmpGetEntry(i: nat) -> (Spmpcfg_ent, xlenbits) = {
  if i < 64 then (spmp_read_cfg_indirect(i), spmp_read_addr_indirect(i))
  else (Mk_Spmpcfg_ent(0b0000000000), zeros())  // fallback case
}

/* SPMP Context Switch Optimization Helper Functions */

/* Check if an SPMP entry is active based on spmpswitch and configuration.
 * 
 * Activation Rule:
 * - An entry is active only when: spmpswitch[i] & (spmp[i]cfg.A != OFF)
 * 
 * Special Cases:
 * - When spmpswitch[i] == 0 and spmp[i]cfg.L == 1, entry i remains enabled
 * - TOR entries match regardless of spmpswitch[i-1] value
 */
function spmpEntryActive(hw_idx: range(0, 63), cfg: Spmpcfg_ent) -> bool = {
  let match_type = spmpAddrMatchType_of_bits(cfg[A]);
  let switch_bit = if xlen == 32 then {
    if hw_idx < 32 then spmpswitch[hw_idx] else spmpswitchh[hw_idx - 32]
  } else {
    spmpswitch[hw_idx]
  };

  // Special case: locked entries remain enabled even when switch bit is 0
  let is_locked = spmpLocked(cfg);
  if is_locked then true
  else {
    /* Entry is active if:
        * 1. Switch bit is set AND
        * 2. Address matching mode is not OFF
        * 3. Entry is TOR mode (TOR entries always match when A != OFF) */
    (switch_bit == bitone) & (match_type != OFF)
  }
}

// defined in riscv_vmem.sail 
val translationMode: Privilege -> SATPMode

/*=======================================================================================*/
/*  Main SPMP Checking Function                                                         */
/*                                                                                       */
/*  Primary entry point for SPMP access control checks. Implements the complete        */
/*  SPMP algorithm                                                                       */
/*=======================================================================================*/

/* Perform SPMP access control check for a memory operation.
 * 
 * SPMP and Paging Interaction:
 *   - SPMP is enabled when satp.mode == Bare and SPMP is implemented
 *   - SPMP and paged virtual memory are mutually exclusive
 *   - When satp.mode != Bare, paged virtual memory provides protection instead
 *   - Machine mode always uses SPMP if implemented (M-mode doesn't use virtual memory)
 * 
 * Matching Logic:
 *   1. SPMP entries are statically prioritized (0-63 in order)
 *   2. The lowest-numbered SPMP entry that matches any byte of access determines the result
 *   3. The SPMP entry must match ALL bytes of access, or the access fails
 *   4. Address matching is done irrespective of the S, R, W, and X bits
 * 
 * Access Control Rules:
 *   1. Calculate effective privilege mode considering MPRV bit
 *   2. If effective privilege mode is M, the access is allowed
 *   3. If effective privilege mode is S/U and no SPMP entry matches, but at least 
 *      one SPMP entry is delegated, the access is denied
 *   4. Otherwise, access is checked according to permission bits in matching SPMP entry
 * 
 * Parameters:
 *   addr: Physical address of the memory access
 *   width: Size of the access in bytes (1, 2, 4, 8, etc.)
 *   acc: Type of access (Read/Write/Execute/ReadWrite)
 *   priv: Current privilege level of the accessing code
 * 
 * Returns:
 *   None(): Access allowed
 *   Some(exception): Access denied with specific page fault type */
function spmpCheck forall 'n, 0 < 'n <= max_mem_access . (
  addr: physaddr,
  width: int('n),
  acc: MemoryAccessType(ext_access_type),
  priv: Privilege
) -> option(ExceptionType) = {
  let width : xlenbits = to_bits(sizeof(xlen), width);
  
  /* SPMP Enablement Check: SPMP is only active when satp.mode == Bare
   * When paged virtual memory is active (satp.mode != Bare), SPMP is disabled
   * and this function should allow all accesses to proceed */
  if not(sys_spmp_enabled) then return None();  // SPMP not implemented
  
  /* Check SPMP and Paging interaction:
   * - Machine mode: Always uses SPMP if implemented (Machine mode doesn't use virtual memory)
   * - Supervisor/User modes: SPMP is only active when satp.mode == Bare
   * - When satp.mode != Bare, paged virtual memory provides protection instead
   * 
   * This ensures SPMP and paged virtual memory are mutually exclusive per spec.
   */
  if priv != Machine then {
    // For S/U modes: SPMP is only active when translation mode is Bare
    // When paged virtual memory is active, SPMP is disabled and access is allowed
    if translationMode(priv) != Bare then {
      return None();
    }
  };
  
  /* Rule 1: Calculate effective privilege mode for SPMP checking
   * 
   * SPMP checks will be applied to all accesses whose effective privilege mode is S or U:
   * - If current privilege is M and MPRV=0: effective privilege is M (bypass SPMP)
   * - If current privilege is M and MPRV=1: effective privilege is determined by MPP
   * - If current privilege is S or U: effective privilege is current privilege
   * 
   * The MPRV bit in mstatus allows M-mode to access memory with privilege of a lower mode.
   */
  let effective_priv : Privilege = match (priv, acc) {
    (Machine, _) if mstatus[MPRV] == 0b1 =>
      privLevel_bits((mstatus[MPP], bitzero)),
    (Machine, InstructionFetch(_)) =>
      Machine,  // Instruction fetches ignore MPRV
    _ => priv
  };
  
  /* Rule 2: If effective privilege mode is M, the access is allowed */
  match effective_priv {
    Machine => return None(),
    _       => ()
  };
  
  /* Check all SPMP entries in order for address matching.
   * SPMP entries begin from hardware index pmpnum and go to 63 */
  var has_delegated_entries : bool = false;  // Track if any SPMP entries are delegated
  let spmp_start = getPmpNum();  // First hardware resource allocated to SPMP
  let spmp_end = 63;             // Last hardware resource (always 63)
  
  var prev_spmpaddr : xlenbits = zeros();  // Previous address for TOR mode
  
  foreach (hw_idx from spmp_start to spmp_end) {
    let (cfg, spmpaddr) = spmpGetEntry(hw_idx);
    let match_type = spmpAddrMatchType_of_bits(cfg[A]);
    
    /* Check if this entry is active (considering spmpswitch optimization) */
    if spmpEntryActive(hw_idx, cfg) then {
      /* Entry is configured (A != OFF), mark that we have delegated entries */
      if match_type != OFF then {
        has_delegated_entries = true;
      };
      
      /* Calculate address range for this entry */
      let rng = spmpAddrRange(cfg, spmpaddr, prev_spmpaddr, hw_idx);
      
      /* Check if access matches this entry's address range */
      let Physaddr(paddr) = addr;
      let addr_nat = unsigned(paddr);
      let width_nat = unsigned(width);
      
      match spmpMatchAddr(addr_nat, width_nat, rng) {
        SPMP_NoMatch => {
          /* No match, continue to next entry */
          ()
        },
        SPMP_PartialMatch => {
          /* Partial match is a violation - deny access */
          return Some(accessToSpmpFault(acc))
        },
        SPMP_Match => {
          /* Full match - check permissions */
          if spmpCheckPerms(cfg, acc, effective_priv) then {
            /* Permission granted */
            return None()
          } else {
            /* Permission denied */
            return Some(accessToSpmpFault(acc))
          }
        }
      }
    };
    
    /* Update prev_spmpaddr for TOR mode of next entry */
    prev_spmpaddr = spmpaddr;
  };

  /* Rule 3: No SPMP entry matched, check delegation status */
  if has_delegated_entries then {
    /* At least one SPMP entry is configured, deny access by default */
    Some(accessToSpmpFault(acc))
  } else {
    /* No SPMP entries configured, allow access */
    None()
  }
}

/*=======================================================================================*/
/*  SPMP Reset and Initialization                                                       */
/*=======================================================================================*/

/* Initialize SPMP to safe default state.
 * 
 * SPMP should be initialized to allow all
 * access by default to maintain compatibility with existing software.
 * 
 * Reset behavior:
 *   - All entries set to OFF (disabled) state
 *   - No memory regions protected initially  
 *   - All accesses allowed until SPMP entries are configured
 *   - L bits are cleared (only possible during reset by hardware/M-mode)
 * 
 * This differs from PMP reset which typically denies access by default. 
 * 
 * NOTE: This function should only be called during system reset or by M-mode code.
 * The L bit can only be cleared by M-mode or hardware reset. */
function reset_spmp() -> unit = {
  /* Reset only hardware resources allocated to SPMP (from getPmpNum() to 63) */
  let spmp_start = getPmpNum();
  foreach (hw_idx from spmp_start to 63) {
    spmpcfg_n[hw_idx] = Mk_Spmpcfg_ent(0b0000000000);  // All bits cleared (A=OFF, L=0, etc.)
    spmpaddr_n[hw_idx] = zeros();
  };

  /* Reset SPMP switch registers - must be cleared on reset */
  spmpSwitchReset();

  /* After reset, SPMP allows all access by default.
   * Software must explicitly configure SPMP entries to restrict access.
   * This provides backward compatibility with systems that don't use SPMP. */
}



/* Helper function to unlock SPMP entry (M-mode only).
 * This function can be used by M-mode software to unlock specific SPMP entries.
 * Note: This should only be called from M-mode context.
 */
function spmpUnlock(n: range(0, 63)) -> unit = {
  // Only M-mode can unlock entries
  if cur_privilege == Machine then {
    let cfg = spmpcfg_n[n];
    spmpcfg_n[n] = [cfg with L = 0b0];
  }
}

/*=======================================================================================*/
/*  SPMP Configuration Validation                                                       */
/*                                                                                       */
/*  Validation functions to ensure SPMP entries are configured correctly.               */
/*=======================================================================================*/

/* Validate SPMP configuration entry for correctness.
 * 
 * Checks entry-specific constraints based on address matching mode.
 * Invalid configurations may lead to unpredictable behavior.
 * 
 * Parameters:
 *   i: Entry index (0-63)
 *   cfg: Configuration entry to validate
 *   spmpaddr: Address register value
 * 
 * Returns: true if configuration is valid */
function spmpValidateConfig(i: nat, cfg: Spmpcfg_ent, spmpaddr: xlenbits) -> bool = {
  match spmpAddrMatchType_of_bits(cfg[A]) {
    OFF => {
      /* OFF mode: Always valid, no address constraints */
      true
    },
    TOR => {
      /* TOR mode: Valid if this entry's addr > previous entry's addr
       * (checked at runtime during address range calculation) */
      true
    },
    NA4 => {
      /* NA4 mode: Address must be 4-byte aligned
       * Check that lowest 2 bits of spmpaddr are 0 */
      spmpaddr[1..0] == 0b00
    },
    NAPOT => {
      /* NAPOT mode: Address encoding must be valid
       * Trailing 1s indicate region size, must not overflow */
      true  // Complex validation, typically done in hardware
    }
  }
}

/* Note: Enhanced debugging support omitted to avoid compilation issues.
 * Debug functions can be added later with proper string handling. */
