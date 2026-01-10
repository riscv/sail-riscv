// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

/*=======================================================================================*/
/*  SPMP (Supervisor Mode Physical Memory Protection) Register Definitions              */
/*                                                                                       */
/*  This module implements the SPMP CSR interface as specified in .    */
/*  SPMP provides 64 protection entries with configuration and address registers.       */
/*                                                                                       */
/*  CSR Address Space:                                   */
/*    spmpcfg0-spmpcfg15   (Configuration registers)                       */
/*    spmpaddr0-spmpaddr63 (Address registers)                             */
/*                                                                                       */
/*  Privilege Level: Supervisor (0x1XX address space)                                   */
/*                                                                                       */
/*  Lock Bit (L) Access Control Rules:                                                  */
/*    - L bit is only accessible to M-mode for writes                                   */
/*    - M-mode: Can read/write L bit and modify locked entries                          */
/*    - S-mode: Cannot modify locked entries (writes ignored when L=1)                 */
/*    - L bit is not sticky - can only be reset by M-mode                              */
/*    - Setting L=1 locks entry even when A=OFF                                        */
/*    - For locked TOR entries, S-mode writes to previous addr register ignored        */
/*=======================================================================================*/

/* SPMP platform configuration parameters.
 * These values are typically set at build time based on platform capabilities. */
// let sys_spmp_enabled : bool = config memory.spmp.enabled  // Platform SPMP support
let sys_spmp_count : nat = config memory.spmp.count       // Number of SPMP entries

/* G parameter that specifies the SPMP grain size. The grain size is 2^(G+2), e.g.
 * G=0 -> 4 bytes (minimum), G=1 -> 8 bytes, G=2 -> 16 bytes, etc.
 * This allows software to probe the minimum SPMP granularity per spec. */
let sys_spmp_grain : range(0, 63) = config memory.spmp.grain

/*=======================================================================================*/
/*  Smpmpdeleg Extension - Resource Sharing between PMP and SPMP                       */
/*                                                                                       */
/*  This extension is MANDATORY for implementations that support Sspmp in conjunction  */
/*  with M-mode. It allows hardware resources to be dynamically allocated between       */
/*  PMP and SPMP through the mpmpdeleg CSR.                                             */
/*=======================================================================================*/

/* mpmpdeleg CSR bitfield definition
 * Bits [6:0]: pmpnum - Starting index for SPMP delegation
 * All PMP entries with index >= pmpnum are delegated as SPMP entries
 */
bitfield Mpmpdeleg : xlenbits = {
  /* Bits [XLEN-1:7]: Reserved (WPRI) */
  pmpnum : 6 .. 0  /* WARL field - starting index for delegation */
}

/* mpmpdeleg CSR register */
register mpmpdeleg : Mpmpdeleg

/* Get the number of PMP entries (which is the starting index for SPMP) */
function getPmpNum() -> nat = {
  unsigned(mpmpdeleg[pmpnum])
}

/* Initialize mpmpdeleg to delegate no entries by default */
function init_mpmpdeleg() -> unit = {
  /* Default: pmpnum = 64 (no delegation, all entries remain as PMP) */
  mpmpdeleg = Mk_Mpmpdeleg(zeros());
  mpmpdeleg = [mpmpdeleg with pmpnum = 0b1000000];  // Set pmpnum to 64
}

/*=======================================================================================*/
/*  SPMP Configuration Register CSR Name Mappings                                     */
/*                                                                                       */
/*  Each spmpcfg register contains configuration for multiple SPMP entries:             */
/*    - RV32: 4 entries per register (8 bits each)                                      */
/*    - RV64: 8 entries per register (8 bits each)                                      */
/*                                                                                       */
/*  Configuration bits per entry:                       */
/*    [7]: L - Lock bit (prevents further modifications when set)                       */
/*    [6]: S - Supervisor/User mode shared permission management                        */
/*    [5]: Reserved (WPRI - Write Preserve, Read Ignore)                               */
/*    [4:3]: A - Address matching mode (OFF/TOR/NA4/NAPOT)                             */
/*    [2]: X - Execute permission                                                       */
/*    [1]: W - Write permission                                                         */
/*    [0]: R - Read permission                                                          */
/*=======================================================================================*/
/*  SPMP CSR Name Mappings - REMOVED                                                    */
/*                                                                                       */
/*  SPMP CSRs are now accessed indirectly through siselect/sireg interface:            */
/*  - siselect[11:0] = entry_index (0-63)                                              */
/*  - sireg  = spmpaddr[entry_index]                                                   */
/*  - sireg2 = spmpcfg[entry_index]                                                    */
/*=======================================================================================*/

mapping clause csr_name_map = 0x1F0  <-> "spmpswitch" // SPMP domain switch register
mapping clause csr_name_map = 0x1F1  <-> "spmpswitchh" // SPMP domain switch register high (RV32 only)

/*=======================================================================================*/
/*  SPMP Context Switching Optimization - Sspmpsw Extension                            */
/*                                                                                       */
/*  The spmpswitch registers provide context switching optimization by allowing         */
/*  software to activate/deactivate SPMP entries without modifying configuration.      */
/*                                                                                       */
/*  Register Layout:                                                                     */
/*    - RV32: spmpswitch (entries 0-31) + spmpswitchh (entries 32-63)                  */
/*    - RV64: spmpswitch (entries 0-63)                                                 */
/*                                                                                       */
/*  Activation Rule (per spec):                                                         */
/*    An entry i is active only when: sspmpswitch[i] & spmpcfg[i].A != 0               */
/*    - Switch bit must be set (= 1) AND                                               */
/*    - Address matching mode must not be OFF                                          */
/*                                                                                       */
/*  Lock Bit Behavior:                                                                   */
/*    When spmpcfg[i].L == 1, the corresponding sspmpswitch[i] bit becomes READ-ONLY.  */
/*    This prevents modification but does NOT automatically activate the entry.        */
/*    A locked entry with switch bit = 0 remains inactive.                             */
/*                                                                                       */
/*  TOR Mode Special Rule (per Sspmpsw spec):                                          */
/*    For TOR entries, address matching [spmpaddr[i-1], spmpaddr[i]) is INDEPENDENT    */
/*    of the configuration or activation state of entry i-1:                           */
/*    - spmpcfg[i-1].A can be OFF                                                      */
/*    - sspmpswitch[i-1] can be 0 (inactive)                                           */
/*    The TOR range calculation always uses spmpaddr[i-1] value.                       */
/*                                                                                       */
/*  Memory Ordering:                                                                     */
/*    Writes to spmpswitch CSRs are NOT ordered with respect to subsequent memory      */
/*    accesses. Software must execute SFENCE.VMA (rs1=x0, rs2=x0) to enforce ordering. */
/*=======================================================================================*/

/* SPMP switch registers - control activation of SPMP entries */
register spmpswitch : xlenbits
register spmpswitchh : bits(32)  // Only used in RV32

/* SPMP configuration entries */

/* The names of enum are global in Sail and cannot be defined repeatedly.
 * Reuse PmpAddrMatchType */
// enum PmpAddrMatchType = {OFF, TOR, NA4, NAPOT}

val spmpAddrMatchType_of_bits : bits(2) -> PmpAddrMatchType
function spmpAddrMatchType_of_bits(bs) = {
  match bs {
    0b00 => OFF,
    0b01 => TOR,
    0b10 => NA4,
    0b11 => NAPOT
  }
}

val spmpAddrMatchType_to_bits : PmpAddrMatchType -> bits(2)
function spmpAddrMatchType_to_bits(bs) = {
  match bs {
    OFF   => 0b00,
    TOR   => 0b01,
    NA4   => 0b10,
    NAPOT => 0b11
  }
}

/* SPMP Configuration Entry Bitfield - 10 bits per entry
 * Based on SPMP specification Figure 3:
 *   Bit [9]: SHARED (Shared-Region bit, SPMP extension)
 *   Bit [8]: U (User-mode access, SPMP extension)
 *   Bit [7]: L (Lock)
 *   Bits [6:5]: Reserved (WPRI)
 *   Bits [4:3]: A (Address matching mode: OFF/TOR/NA4/NAPOT)
 *   Bit [2]: X (Execute)
 *   Bit [1]: W (Write)
 *   Bit [0]: R (Read)
 */
bitfield Spmpcfg_ent : bits(10) = {
  SHARED : 9,      /* SHARED bit - marks a Shared-Region rule (WARL) */
  U      : 8,      /* U bit - marks U-mode-only when set, S-mode-only when unset (WARL) */
  L      : 7,      /* Lock bit - prevents further modifications when set (WARL) */
  /* Bits [6:5]: Reserved (WPRI) */
  A      : 4 .. 3, /* Address matching mode (OFF/TOR/NA4/NAPOT) (WARL) */
  X      : 2,      /* Execute permission */
  W      : 1,      /* Write permission */
  R      : 0       /* Read permission */
}

/* Helper function to extract RWX as a 3-bit field for permission encoding checks.
 * The RWX field is a combined 3-bit encoding (bits [2:0] = XWR).
 *
 * Valid Encodings (per SPMP spec):
 *   000 (0x0): No permissions
 *   001 (0x1): Read-only (R--)
 *   100 (0x4): Execute-only (--X)
 *   101 (0x5): Read+Execute (R-X)
 *   110 (0x6): Write+Execute (-WX, valid for Shared-Region S-mode)
 *   111 (0x7): Read+Write+Execute (RWX)
 *
 * Reserved Encodings (per SPMP spec):
 *   010 (0x2): Write-only (--W, reserved for future standard use)
 *   011 (0x3): Read+Write (RW-, reserved for future standard use)
 *
 * See spmpCheckRWX() in spmp_control.sail for the full permission matrix including
 * privilege-level specific rules and Shared-Region special constraints.
 */

register spmpcfg_n : vector(64, Spmpcfg_ent)
register spmpaddr_n : vector(64, xlenbits)

/* Helpers to handle locked entries - defined after Spmpcfg_ent bitfield */
function spmpLocked(cfg: Spmpcfg_ent) -> bool =
   cfg[L] == 0b1

function spmpTORLocked(cfg: Spmpcfg_ent) -> bool =
   (cfg[L] == 0b1) & (spmpAddrMatchType_of_bits(cfg[A]) == TOR)

/* mpmpdeleg CSR access (M-mode only) */
mapping clause csr_name_map = 0x1F2 <-> "mpmpdeleg"

function clause is_CSR_accessible(0x1F2, _, _) = sys_spmp_enabled
function clause read_CSR(0x1F2) = mpmpdeleg.bits
function clause write_CSR((0x1F2, value)) = {
  /* Only M-mode can write mpmpdeleg */
  if cur_privilege == Machine then {
    let new_pmpnum = value[6 .. 0];
    let pmpnum_val = unsigned(new_pmpnum);

    /*
     * "The pmpnum value cannot be set to an index that is less than or equal to
     *  that of any locked PMP entry."
     *
     * Example: If PMP[7] is locked, any attempt to write a value less than 8
     * to pmpnum is ignored.
     *
     * "The pmpnum value can be set to override locked SPMP entries."
     * Example: If SPMP[0] is locked, M-mode can still increment pmpnum.
     *
     * So we ONLY check locked PMP entries, NOT locked SPMP entries.
     */

    /* Find the highest index of any locked PMP entry */
    var max_locked_pmp_idx : int = -1;  /* -1 means no locked PMP entry */
    foreach (i from 0 to 63) {
      /* Check if PMP entry is locked by checking L bit directly */
      if pmpcfg_n[i][L] == 0b1 then {
        max_locked_pmp_idx = i;
      }
    };

    /* pmpnum must be > max_locked_pmp_idx (i.e., >= max_locked_pmp_idx + 1)
     * This ensures no locked PMP entry is converted to SPMP.
     * If no PMP entry is locked (max_locked_pmp_idx == -1), any value is allowed.
     */
    let min_allowed_pmpnum : int = max_locked_pmp_idx + 1;

    if pmpnum_val >= min_allowed_pmpnum then {
      /* Valid pmpnum value - clamp to [0, 64] */
      if pmpnum_val <= 64 then {
        mpmpdeleg = [mpmpdeleg with pmpnum = new_pmpnum];
      } else {
        /* If value exceeds 64, set to 64 (no delegation) per WARL behavior */
        mpmpdeleg = [mpmpdeleg with pmpnum = 0b1000000];  // 64 in binary
      }
    }
    /* else: ignore write if pmpnum would be <= any locked PMP entry index */
  };
  Ok(mpmpdeleg.bits)
}

/*=======================================================================================*/
/*  SPMP Indirect CSR Access Functions                                                  */
/*                                                                                       */
/*  These functions implement the indirect CSR access mechanism for SPMP:               */
/*  - siselect[11:0] = entry_index (0-63)                                              */
/*  - sireg  = spmpaddr[entry_index] (indirect address access)                         */
/*  - sireg2 = spmpcfg[entry_index]  (indirect configuration access)                   */
/*                                                                                       */
/*  Access Rules:                                                                        */
/*  - S-mode can set spmp[i]cfg.L to lock an SPMP entry                               */
/*  - When spmp[i]cfg.L is set, SPMP writes via siselect are ignored                   */
/*  - Only M-mode access via miselect can reset spmp[i]cfg.L                          */
/*                                                                                       */
/*  IMPORTANT - Memory Ordering Requirements:                                           */
/*                                                                                       */
/*  Indirect accesses to SPMP CSRs are NOT ordered with respect to each other or       */
/*  with subsequent memory accesses. This enables fast context switching of SPMP       */
/*  registers without performance overhead.                                             */
/*                                                                                       */
/*  To enforce ordering between SPMP CSR writes and subsequent memory accesses,        */
/*  software MUST execute:                                                              */
/*                                                                                       */
/*      SFENCE.VMA with rs1=x0 and rs2=x0                                               */
/*                                                                                       */
/*  This instruction synchronizes all preceding SPMP CSR writes with all subsequent    */
/*  memory accesses and implicit accesses to memory management structures.              */
/*                                                                                       */
/*  Example usage pattern:                                                              */
/*                                                                                       */
/*      li      t0, <entry_index>          # Select SPMP entry                          */
/*      csrw    siselect, t0               # Set siselect to entry index                */
/*      li      t1, <config_value>         # Prepare new configuration                  */
/*      csrw    sireg2, t1                 # Write new spmpcfg value                    */
/*      li      t2, <addr_value>           # Prepare new address                        */
/*      csrw    sireg, t2                  # Write new spmpaddr value                   */
/*      sfence.vma x0, x0                  # REQUIRED: Enforce ordering                 */
/*      # Now safe to access memory with new SPMP protection                            */
/*                                                                                       */
/*  Rationale:                                                                           */
/*  - SFENCE.VMA already orders memory management structure updates                     */
/*  - SPMP entries are treated as memory management structures                          */
/*  - Relaxed ordering enables performance optimization for context switches            */
/*=======================================================================================*/

// enum IregType = { Mireg, Sireg }

/* Get valid SPMP entry range based on delegation */
function getSpmpValidRange() -> (nat, nat) = {
  let pmp_count = getPmpNum();
  let total_resources = 64;
  let spmp_start = pmp_count;
  let spmp_count_val = total_resources - pmp_count;
  // Ensure we don't return negative values for nat type
  if spmp_count_val <= 0 then (0, 0)
  else (spmp_start, total_resources - 1) // [pmpnum, 63] - hardware indices
}

/* Check if LOGICAL SPMP entry index is valid for current privilege.
 * logical_idx is the index from siselect (0-63 corresponding to 0x100-0x13F).
 * Valid range is [0, spmp_count) where spmp_count = 64 - pmpnum.
 */
function spmpCheckLogicalEntryAccess(logical_idx: int, priv: Privilege) -> bool = {
  let pmpnum = getPmpNum();
  let spmp_count : int = 64 - pmpnum;
  (logical_idx >= 0) & (logical_idx < spmp_count)
}

/* Convert logical SPMP index to hardware index.
 * logical_idx: 0-63 from siselect (0x100-0x13F)
 * returns: hardware index = pmpnum + logical_idx
 */
function spmpLogicalToHardwareIdx(logical_idx: int) -> int = {
  let pmpnum = getPmpNum();
  pmpnum + logical_idx
}

/* Read SPMP address register via indirect access (S-mode).
 * entry_idx is the LOGICAL index (0-63) from siselect value (0x100-0x13F).
 * This needs to be converted to hardware index: hw_idx = pmpnum + entry_idx
 */
function spmp_read_addr_indirect(entry_idx: int) -> xlenbits = {
  if spmpCheckLogicalEntryAccess(entry_idx, cur_privilege) then {
    let hw_idx = spmpLogicalToHardwareIdx(entry_idx);
    if hw_idx >= 0 & hw_idx < 64 then {
      spmpaddr_n[hw_idx]
    } else {
      zeros()
    }
  } else {
    zeros()
  }
}

/* Enhanced SPMP configuration read with range checking (S-mode).
 * entry_idx is the LOGICAL index (0-63) from siselect value (0x100-0x13F).
 */
function spmp_read_cfg_indirect(entry_idx: int) -> Spmpcfg_ent = {
  if spmpCheckLogicalEntryAccess(entry_idx, cur_privilege) then {
    let hw_idx = spmpLogicalToHardwareIdx(entry_idx);
    if hw_idx >= 0 & hw_idx < 64 then {
      spmpcfg_n[hw_idx]
    } else {
      Mk_Spmpcfg_ent(0b0000000000)
    }
  } else {
    Mk_Spmpcfg_ent(0b0000000000)
  }
}

/* Write SPMP address with granularity masking.
 * This function applies the minimum granularity mask to SPMP address writes,
 * allowing software to probe the SPMP granularity per spec.
 *
 * Parameters:
 *   locked: Whether the entry is locked (L=1)
 *   tor_locked: Whether the next entry is locked TOR mode
 *   reg: Current address register value
 *   v: New value to write
 *
 * Returns: Masked address value according to granularity settings
 *
 * Per spec: "Software can probe the minimum SPMP granularity by writing all ones
 * to spmpaddr[i] and reading back the result. If G is the index of the least-
 * significant bit set, the granularity is 2^(G+2) bytes."
 */
function spmpWriteAddr(locked: bool, tor_locked: bool, reg: xlenbits, v: xlenbits) -> xlenbits = {
  let G = sys_spmp_grain;

  /* If locked or TOR-locked, preserve existing value */
  if locked | tor_locked then reg
  else {
    /* Apply granularity mask based on platform configuration.
     * For RV32: full 32-bit value, for RV64: bits [53:0] only (54-bit physical address)
     * Then mask low G bits to enforce minimum granularity. */
    let addr = if xlen == 32 then v else zero_extend(v[53..0]);
    // print_endline("SPMP Write Addr: " ^ hex_bits_str(addr));
    /* Apply granularity mask: low G bits read as zeros.
     * This allows software to detect minimum granularity by writing all 1s. */
    if G == 0 then addr
    else {
      let mask : xlenbits = zero_extend(ones(min(G, xlen)));
      let masked_addr = addr & ~(mask);
      // print_endline("SPMP Write Addr Masked: " ^ hex_bits_str(masked_addr));
      masked_addr
    }
  }
}

/* Write SPMP address register via indirect access through siselect.
 * entry_idx is the LOGICAL index (0-63) from siselect value (0x100-0x13F).
 *
 * Per SPMP spec: "Attempts to write to locked spmpaddr[i] registers using the
 * siselect CSR are ignored. If a locked entry has spmpcfg[i].A set to TOR,
 * writes to the preceding spmpaddr[i-1] via siselect are also ignored."
 *
 * Write restrictions (applies to ALL privilege levels using siselect):
 *   - Cannot write to locked entries (L=1) via siselect
 *   - Cannot write to spmpaddr[i-1] if spmp[i]cfg is locked TOR entry
 *   - M-mode must use miselect interface to modify locked entries
 */
function spmp_write_addr_indirect(entry_idx: int, value: xlenbits) -> unit = {
  if spmpCheckLogicalEntryAccess(entry_idx, cur_privilege) then {
    let hw_idx = spmpLogicalToHardwareIdx(entry_idx);
    if hw_idx >= 0 & hw_idx < 64 then {
      let cfg = spmpcfg_n[hw_idx];
      let is_locked = spmpLocked(cfg);

      /* Check TOR locking: if next entry is locked TOR, this addr is also locked */
      let next_hw_idx = hw_idx + 1;
      let next_cfg = if next_hw_idx < 64 then spmpcfg_n[next_hw_idx] else Mk_Spmpcfg_ent(0b0000000000);
      let is_tor_locked = spmpTORLocked(next_cfg);

      /* Apply granularity masking and lock check */
      spmpaddr_n[hw_idx] = spmpWriteAddr(is_locked, is_tor_locked, spmpaddr_n[hw_idx], value);
    }
  }
}

/* WARL validation and L bit access control for SPMP configuration writes.
 *
 * This function performs two checks:
 * 1. WARL validation: Rejects reserved encodings (SHARED=1+U=0, RWX=010, RWX=011)
 * 2. L bit transition control: S-mode can set L bit (0->1) but cannot clear it (1->0)
 *
 * Note: This function does NOT check if entry is locked. Lock checking is the
 * responsibility of the caller:
 * - spmp_write_cfg_indirect: Checks lock, rejects writes to locked entries (any privilege)
 * - spmp_mmode_write_cfg_indirect: No lock check, M-mode can modify locked entries via miselect
 *
 * Parameters:
 * - n: hardware index (not used in validation, kept for interface consistency)
 * - cfg: current configuration value
 * - v: new configuration value to write
 * - priv: privilege level of the write operation
 */
function spmpWriteCfg(n: int, cfg: Spmpcfg_ent, v: bits(10), priv: Privilege) -> Spmpcfg_ent = {
  let new_cfg = Mk_Spmpcfg_ent(v);
  let is_machine_mode = (priv == Machine);

  // Extract fields for WARL validation
  let rwx = new_cfg[R] @ new_cfg[W] @ new_cfg[X];
  let shared = new_cfg[SHARED];
  let u_bit = new_cfg[U];
  let new_l_bit = new_cfg[L];
  let old_l_bit = cfg[L];

  /* WARL (Write Any, Read Legal) validation:
   * According to spec, the following encodings are reserved for future standard use:
   * 1. SHARED=1, U=0 (reserved combination)
   * 2. RWX=010 (--W, write-only, reserved)
   * 3. RWX=011 (RW-, read+write but no execute, reserved)
   *
   * Note: RWX=110 (-WX) is NOT reserved - it's valid for Shared-Region S-mode access
   *
   * For reserved encodings, the write is ignored and the old value is preserved.
   */

  // Check for reserved SHARED=1, U=0 combination
  if (shared == 0b1) & (u_bit == 0b0) then {
    cfg  // Ignore write, preserve old value
  }
  else if (rwx == 0b010) | (rwx == 0b011) then {
    cfg  // Reserved RWX encoding - ignore write, preserve old value
  }
  else {
    /* L bit access control:
     * - M-mode: can set or clear L bit freely
     * - S-mode: can only set L bit (0->1), cannot clear it (1->0)
     * Per spec: "The lock bit (spmpcfg[i].L) of an SPMP entry can only be
     * cleared by M-mode through an indirect access using miselect."
     */
    if not(is_machine_mode) & (old_l_bit == 0b1) & (new_l_bit == 0b0) then {
      /* S-mode attempting to clear L bit - preserve old L bit */
      [new_cfg with L = old_l_bit]
    } else {
      new_cfg  // Valid encoding - allow write
    }
  }
}

/* Write SPMP configuration register via indirect access through siselect.
 * entry_idx is the LOGICAL index (0-63) from siselect value (0x100-0x13F).
 *
 * Per SPMP spec: "Attempts to write to locked spmpcfg[i] registers using the
 * siselect CSR are ignored."
 *
 * Write restrictions (applies to ALL privilege levels using siselect):
 *   - Cannot write to locked entries (L=1) via siselect
 *   - S-mode can set L bit (0->1) but cannot clear it (1->0)
 *   - M-mode must use miselect interface to modify locked entries
 */
function spmp_write_cfg_indirect(entry_idx: int, cfg: Spmpcfg_ent) -> unit = {
  if spmpCheckLogicalEntryAccess(entry_idx, cur_privilege) then {
    let hw_idx = spmpLogicalToHardwareIdx(entry_idx);
    if hw_idx >= 0 & hw_idx < 64 then {
      let current_cfg = spmpcfg_n[hw_idx];
      let is_locked = spmpLocked(current_cfg);

      /* Per spec: writes to locked entries via siselect are ignored (any privilege) */
      if not(is_locked) then {
        /* Apply WARL validation using spmpWriteCfg function */
        let new_cfg = spmpWriteCfg(hw_idx, current_cfg, cfg.bits, cur_privilege);
        spmpcfg_n[hw_idx] = new_cfg;
      }
      /* else: locked entry, write ignored per spec */
    }
  }
}

/* M-mode version with same range checking for consistency.
 * entry_idx is the LOGICAL index (0-63) from miselect value (0x100-0x13F).
 * This needs to be converted to hardware index: hw_idx = pmpnum + entry_idx
 *
 * M-mode privileges:
 * - Can always write to any SPMP entry, even locked ones
 * - Can CLEAR the L bit (this is the ONLY way to clear L bit per spec)
 * - Can modify any field of locked entries
 */
function spmp_mmode_write_cfg_indirect(entry_idx: int, cfg: Spmpcfg_ent) -> unit = {
  let pmpnum = getPmpNum();
  let spmp_count : int = 64 - pmpnum;  // Number of delegated SPMP entries

  // Check if logical index is within valid SPMP range
  if entry_idx >= 0 & entry_idx < spmp_count then {
    // Convert logical index to hardware index
    let hw_idx = pmpnum + entry_idx;
    if hw_idx < 64 then {
      let current_cfg = spmpcfg_n[hw_idx];

      /* Apply WARL validation for reserved encodings.
       * M-mode can override lock status, so we pass Machine privilege.
       * This allows M-mode to clear L bit and modify all fields.
       */
      let validated_cfg = spmpWriteCfg(hw_idx, current_cfg, cfg.bits, Machine);
      spmpcfg_n[hw_idx] = validated_cfg;
    }
  }
  // else: out-of-range logical index - write is ignored
}

/* M-mode configuration register read via miselect interface.
 * entry_idx is the LOGICAL index (0-63) from miselect value (0x100-0x13F).
 * This needs to be converted to hardware index: hw_idx = pmpnum + entry_idx
 */
function spmp_mmode_read_cfg_indirect(entry_idx: int) -> Spmpcfg_ent = {
  let pmpnum = getPmpNum();
  let spmp_count : int = 64 - pmpnum;  // Number of delegated SPMP entries

  // Check if logical index is within valid SPMP range
  if entry_idx >= 0 & entry_idx < spmp_count then {
    // Convert logical index to hardware index
    let hw_idx = pmpnum + entry_idx;
    if hw_idx < 64 then {
      spmpcfg_n[hw_idx]
    } else {
      Mk_Spmpcfg_ent(0b0000000000)
    }
  } else {
    // Out-of-range logical index - read returns 0
    Mk_Spmpcfg_ent(0b0000000000)
  }
}

/* M-mode address register write via miselect interface.
 * entry_idx is the LOGICAL index (0-63) from miselect value (0x100-0x13F).
 * This needs to be converted to hardware index: hw_idx = pmpnum + entry_idx
 *
 * M-mode privileges via miselect:
 * - Can write to ANY SPMP entry, including locked ones
 * - This is the ONLY way to modify locked entries per spec
 * - No restrictions on TOR-locked entries
 * - Still applies granularity masking for consistency
 */
function spmp_mmode_write_addr_indirect(entry_idx: int, value: xlenbits) -> unit = {
  let pmpnum = getPmpNum();
  let spmp_count : int = 64 - pmpnum;  // Number of delegated SPMP entries

  // Check if logical index is within valid SPMP range
  if entry_idx >= 0 & entry_idx < spmp_count then {
    // Convert logical index to hardware index
    let hw_idx = pmpnum + entry_idx;
    if hw_idx < 64 then {
      /* M-mode can write to locked entries, but still apply granularity masking.
       * Pass locked=false to allow write, but granularity mask is still applied. */
      spmpaddr_n[hw_idx] = spmpWriteAddr(false, false, spmpaddr_n[hw_idx], value);
    }
  }

  // else: out-of-range logical index - write is ignored
}

/* M-mode address register read via miselect interface.
 * entry_idx is the LOGICAL index (0-63) from miselect value (0x100-0x13F).
 * This needs to be converted to hardware index: hw_idx = pmpnum + entry_idx
 */
function spmp_mmode_read_addr_indirect(entry_idx: int) -> xlenbits = {
  let pmpnum = getPmpNum();
  let spmp_count : int = 64 - pmpnum;  // Number of delegated SPMP entries

  // Check if logical index is within valid SPMP range
  if entry_idx >= 0 & entry_idx < spmp_count then {
    // Convert logical index to hardware index
    let hw_idx = pmpnum + entry_idx;
    if hw_idx < 64 then {
      spmpaddr_n[hw_idx]
    } else {
      zeros()
    }
  } else {
    // Out-of-range logical index - read returns 0
    zeros()
  }
}


/*=======================================================================================*/
/*  SPMP Configuration Write - Legacy Note                                              */
/*                                                                                       */
/*  NOTE: SPMP does NOT have direct CSR access (like spmpcfg0-15, spmpaddr0-63).        */
/*  All SPMP register access is through siselect/sireg (S-mode) or miselect/mireg       */
/*  (M-mode) indirect access mechanism. See functions above for implementation.        */
/*=======================================================================================*/

/* NOTE: spmpWriteCfgReg, spmpWriteAddrReg, and spmpWriteAddr functions have been removed.
 * SPMP does NOT have direct CSR access. All access is through:
 *   - S-mode: siselect (0x150) + sireg (0x151) / sireg2 (0x152)
 *   - M-mode: miselect (0x350) + mireg (0x351) / mireg2 (0x352)
 * See spmp_write_addr_indirect() and spmp_write_cfg_indirect() for implementation.
 */


/*=======================================================================================*/
// spmpswitch - SPMP domain switch register (RV64 and RV32)
function clause is_CSR_accessible(0x1F0, _, _) = sys_spmp_enabled
function clause read_CSR(0x1F0) = spmpswitch
function clause write_CSR((0x1F0, value)) = {
  /* According to spec: When an entry i is locked (spmpcfg[i].L == 1),
   * its corresponding sspmpswitch[i] bit becomes read-only.
   * This means no modification is allowed for locked entries. */

  let spmp_start = getPmpNum();
  let spmp_end = 63;

  var new_switch : xlenbits = value;

  /* For each SPMP entry, check if it's locked and restore its original switch bit if locked */
  foreach (hw_idx from spmp_start to spmp_end) {
    /* In RV32, spmpswitch only handles entries [0:31] */
    let in_range = if xlen == 32 then hw_idx < 32 else true;

    if in_range then {
      let cfg = spmpcfg_n[hw_idx];
      let is_locked = spmpLocked(cfg);

      if is_locked then {
        /* For locked entries, restore the original bit from spmpswitch */
        let bit_idx = hw_idx;
        assert(bit_idx >= 0 & bit_idx < xlen);
        new_switch = vector_update_subrange(new_switch, bit_idx, bit_idx, spmpswitch[bit_idx..bit_idx]);
      }
      /* For unlocked entries, keep the new value from 'value' */
    }
  };

  spmpswitch = new_switch;
  Ok(spmpswitch)
}

// spmpswitchh - SPMP domain switch register high (RV32 only)
// Controls activation of SPMP entries [32:63] on RV32 systems
function clause is_CSR_accessible(0x1F1, _, _) = sys_spmp_enabled & (xlen == 32)
function clause read_CSR(0x1F1) = {
  if xlen == 32
  then zero_extend(spmpswitchh)
  else zeros()
}
function clause write_CSR((0x1F1, value)) = {
  if xlen == 32 then {
    /* Similar to spmpswitch, locked entries become read-only */
    let spmp_start = getPmpNum();
    let spmp_end = 63;

    var new_switchh : bits(32) = value[31 .. 0];

    /* For entries [32:63], check if locked and restore original switch bit if locked */
    foreach (hw_idx from spmp_start to spmp_end) {
      if hw_idx >= 32 then {  // Only process entries [32:63]
        let cfg = spmpcfg_n[hw_idx];
        let is_locked = spmpLocked(cfg);

        if is_locked then {
          /* For locked entries, restore the original bit from spmpswitchh */
          let bit_idx = hw_idx - 32;
          assert(bit_idx >= 0 & bit_idx < 32);
          new_switchh = vector_update_subrange(new_switchh, bit_idx, bit_idx, spmpswitchh[bit_idx..bit_idx]);
        }
        /* For unlocked entries, keep the new value from 'value' */
      }
    };

    spmpswitchh = new_switchh;
  };
  Ok(zero_extend(spmpswitchh))
}

/* Get the effective switch register value for 64-bit view */
function spmpGetFullSwitchReg() -> bits(64) = {
  if xlen == 32 then spmpswitchh @ spmpswitch
  else spmpswitch
}

/* Initialize SPMP switch registers on reset */
function spmpSwitchReset() -> unit = {
  spmpswitch = zeros();
  spmpswitchh = zeros();
}

/*=======================================================================================*/
/*  Sscsrind Extension - Indirect CSR Access for SPMP                                  */
/*                                                                                       */
/*  This section implements the Sscsrind extension required by Sspmp specification.     */
/*  SPMP registers are accessed indirectly through siselect/sireg/sireg2 interface:    */
/*                                                                                       */
/*  CSR Addresses:                                                                       */
/*    - siselect (0x150): Selects which SPMP entry to access                           */
/*    - sireg    (0x151): Accesses spmpaddr[entry] for the selected entry              */
/*    - sireg2   (0x152): Accesses spmpcfg[entry] for the selected entry               */
/*    - sireg3-6 (0x153-0x157): Reserved as WPRI                                        */
/*                                                                                       */
/*  siselect Value Mapping:                                                              */
/*    - 0x100: spmpaddr[0], spmpcfg[0]                                                  */
/*    - 0x101: spmpaddr[1], spmpcfg[1]                                                  */
/*    - ...                                                                             */
/*    - 0x13F: spmpaddr[63], spmpcfg[63]                                                */
/*                                                                                       */
/*  Access Rules:                                                                        */
/*    - Out-of-bounds index: read returns 0, write is ignored                          */
/*    - Locked entry (L=1): S-mode writes are ignored                                  */
/*    - M-mode can always read/write, including locked entries                         */
/*    - TOR locked entry: S-mode writes to previous addr register ignored              */
/*                                                                                       */
/*  Memory Ordering:                                                                     */
/*    - Indirect SPMP CSR accesses are NOT ordered with respect to each other          */
/*    - Software must execute SFENCE.VMA (rs1=x0, rs2=x0) to enforce ordering          */
/*=======================================================================================*/

/* siselect register - selects SPMP entry for indirect access */
register siselect : xlenbits

/* CSR name mappings for indirect access registers */
mapping clause csr_name_map = 0x150  <-> "siselect"
mapping clause csr_name_map = 0x151  <-> "sireg"
mapping clause csr_name_map = 0x152  <-> "sireg2"
mapping clause csr_name_map = 0x153  <-> "sireg3"
mapping clause csr_name_map = 0x155  <-> "sireg4"
mapping clause csr_name_map = 0x156  <-> "sireg5"
mapping clause csr_name_map = 0x157  <-> "sireg6"

/* SPMP siselect range constants */
let SPMP_SISELECT_BASE : bits(12) = 0x100  /* siselect value for SPMP entry 0 */
let SPMP_SISELECT_MAX  : bits(12) = 0x13F  /* siselect value for SPMP entry 63 */

/* Check if siselect value is in SPMP range */
function siselect_is_spmp() -> bool = {
  let sel = unsigned(siselect[11..0]);
  (sel >= unsigned(SPMP_SISELECT_BASE)) & (sel <= unsigned(SPMP_SISELECT_MAX))
}

/* Get SPMP entry index from siselect value (0-63) */
function siselect_get_spmp_index() -> int = {
  let sel = unsigned(siselect[11..0]);
  sel - unsigned(SPMP_SISELECT_BASE)
}

/* Check if the selected SPMP logical entry index is valid (within implemented range).
 * entry_idx is the LOGICAL index (0-63 from siselect 0x100-0x13F).
 * Valid range is [0, spmp_count) where spmp_count = 64 - pmpnum.
 */
function siselect_spmp_entry_valid(entry_idx: int) -> bool = {
  spmpCheckLogicalEntryAccess(entry_idx, cur_privilege)
}

/*---------------------------------------------------------------------------------------*/
/*  siselect CSR (0x150) - Select SPMP entry for indirect access                        */
/*---------------------------------------------------------------------------------------*/
function clause is_CSR_accessible(0x150, _, _) = currentlyEnabled(Ext_S) & sys_spmp_enabled

function clause read_CSR(0x150) = siselect

function clause write_CSR((0x150, value)) = {
  siselect = value;
  Ok(siselect)
}

/*---------------------------------------------------------------------------------------*/
/*  sireg CSR (0x151) - Access spmpaddr[entry] via indirect access                       */
/*                                                                                       */
/*  When siselect is in range [0x100, 0x13F]:                                           */
/*    - Read: Returns spmpaddr[siselect - 0x100]                                        */
/*    - Write: Writes to spmpaddr[siselect - 0x100] (if not locked)                     */
/*                                                                                       */
/*  When siselect is out of range:                                                       */
/*    - Read: Returns 0                                                                  */
/*    - Write: Ignored                                                                   */
/*---------------------------------------------------------------------------------------*/
function clause is_CSR_accessible(0x151, _, _) = currentlyEnabled(Ext_S) & sys_spmp_enabled

function clause read_CSR(0x151) = {
  if siselect_is_spmp() then {
    let entry_idx = siselect_get_spmp_index();
    /* Use indirect access function which handles logical-to-hardware index conversion */
    spmp_read_addr_indirect(entry_idx)
  } else {
    zeros()  /* Non-SPMP siselect value returns 0 */
  }
}

function clause write_CSR((0x151, value)) = {
  if siselect_is_spmp() then {
    let entry_idx = siselect_get_spmp_index();
    /* Use indirect access function which handles:
     * - Logical-to-hardware index conversion
     * - Range checking
     * - Lock status checking (including TOR locking)
     * - M-mode/S-mode privilege checking
     */
    spmp_write_addr_indirect(entry_idx, value);
  };
  /* else: non-SPMP siselect write ignored */
  Ok(value)
}

/*---------------------------------------------------------------------------------------*/
/*  sireg2 CSR (0x152) - Access spmpcfg[entry] via indirect access                       */
/*                                                                                       */
/*  When siselect is in range [0x100, 0x13F]:                                           */
/*    - Read: Returns zero_extend(spmpcfg[siselect - 0x100])                            */
/*    - Write: Writes to spmpcfg[siselect - 0x100] (if not locked, with WARL checks)   */
/*                                                                                       */
/*  WARL (Write Any, Read Legal) validation:                                            */
/*    - SHARED=1, U=0: Reserved combination, write ignored                             */
/*    - RWX=010, 011, 110: Reserved encodings, write ignored                           */
/*                                                                                       */
/*  When siselect is out of range:                                                       */
/*    - Read: Returns 0                                                                  */
/*    - Write: Ignored                                                                   */
/*---------------------------------------------------------------------------------------*/
function clause is_CSR_accessible(0x152, _, _) = currentlyEnabled(Ext_S) & sys_spmp_enabled

function clause read_CSR(0x152) = {
  if siselect_is_spmp() then {
    let entry_idx = siselect_get_spmp_index();
    /* Use indirect access function which handles logical-to-hardware index conversion */
    let cfg = spmp_read_cfg_indirect(entry_idx);
    zero_extend(cfg.bits)
  } else {
    zeros()  /* Non-SPMP siselect value returns 0 */
  }
}

function clause write_CSR((0x152, value)) = {
  if siselect_is_spmp() then {
    let entry_idx = siselect_get_spmp_index();
    /* Use indirect access function which handles:
     * - Logical-to-hardware index conversion
     * - Range checking
     * - Lock status checking
     * - M-mode/S-mode privilege checking
     * - WARL validation
     */
    let new_cfg = Mk_Spmpcfg_ent(value[9..0]);
    spmp_write_cfg_indirect(entry_idx, new_cfg);
  };
  /* else: non-SPMP siselect write ignored */
  Ok(value)
}

/*---------------------------------------------------------------------------------------*/
/*  sireg3-sireg6 CSRs (0x153, 0x155-0x157) - Reserved as WPRI                          */
/*                                                                                       */
/*  These registers are reserved for future use. Per spec:                              */
/*    - Read: Returns 0                                                                  */
/*    - Write: Ignored (WPRI behavior)                                                  */
/*---------------------------------------------------------------------------------------*/
function clause is_CSR_accessible(0x153, _, _) = currentlyEnabled(Ext_S) & sys_spmp_enabled
function clause is_CSR_accessible(0x155, _, _) = currentlyEnabled(Ext_S) & sys_spmp_enabled
function clause is_CSR_accessible(0x156, _, _) = currentlyEnabled(Ext_S) & sys_spmp_enabled
function clause is_CSR_accessible(0x157, _, _) = currentlyEnabled(Ext_S) & sys_spmp_enabled

function clause read_CSR(0x153) = zeros()  /* sireg3 - reserved WPRI */
function clause read_CSR(0x155) = zeros()  /* sireg4 - reserved WPRI */
function clause read_CSR(0x156) = zeros()  /* sireg5 - reserved WPRI */
function clause read_CSR(0x157) = zeros()  /* sireg6 - reserved WPRI */

function clause write_CSR((0x153, _)) = Ok(zeros())  /* sireg3 - ignored */
function clause write_CSR((0x155, _)) = Ok(zeros())  /* sireg4 - ignored */
function clause write_CSR((0x156, _)) = Ok(zeros())  /* sireg5 - ignored */
function clause write_CSR((0x157, _)) = Ok(zeros())  /* sireg6 - ignored */

/*---------------------------------------------------------------------------------------*/
/*  M-mode Indirect Access (miselect/mireg) for SPMP                                    */
/*                                                                                       */
/*  Per Resource_Sharing.adoc spec:                                                     */
/*  M-mode uses miselect (0x350) and mireg (0x351), mireg2 (0x352) for indirect access. */
/*  This allows M-mode to access SPMP entries including:                                */
/*    - Reading/writing locked entries                                                  */
/*    - Resetting L bit to unlock entries (ONLY miselect can clear L bit!)             */
/*                                                                                       */
/*  The siselect range 0x100-0x13F is shared between S-mode and M-mode indirect access.*/
/*  Both modes use the SAME view of SPMP entries (indices 0-47 if 48 delegated).        */
/*---------------------------------------------------------------------------------------*/

/* miselect register - M-mode version of siselect for indirect SPMP access */
register miselect : xlenbits

/* CSR name mappings for M-mode indirect access registers */
mapping clause csr_name_map = 0x350  <-> "miselect"
mapping clause csr_name_map = 0x351  <-> "mireg"
mapping clause csr_name_map = 0x352  <-> "mireg2"
mapping clause csr_name_map = 0x353  <-> "mireg3"
mapping clause csr_name_map = 0x355  <-> "mireg4"
mapping clause csr_name_map = 0x356  <-> "mireg5"
mapping clause csr_name_map = 0x357  <-> "mireg6"

/* SPMP miselect range constants */
let SPMP_MISELECT_BASE : bits(12) = 0x100  /* miselect value for SPMP entry 0 */
let SPMP_MISELECT_MAX  : bits(12) = 0x13F  /* miselect value for SPMP entry 63 */

/* Check if miselect value is in SPMP range (0x100-0x13F) */
function miselect_is_spmp() -> bool = {
  let sel = unsigned(miselect[11..0]);
  (sel >= unsigned(SPMP_MISELECT_BASE)) & (sel <= unsigned(SPMP_MISELECT_MAX))
}

/* Get SPMP entry index from miselect value */
function miselect_get_spmp_index() -> int = {
  let sel = unsigned(miselect[11..0]);
  sel - unsigned(SPMP_MISELECT_BASE)
}

/* Check if SPMP entry is valid for indirect access via miselect
 * M-mode uses the same view as S-mode: indices [0, spmp_count) */
function miselect_spmp_entry_valid() -> bool = {
  let (start, end_idx) = getSpmpValidRange();
  let entry_idx = miselect_get_spmp_index();
  entry_idx < (end_idx - start + 1)
}

/*---------------------------------------------------------------------------------------*/
/*  miselect CSR (0x350) - M-mode indirect select register                              */
/*---------------------------------------------------------------------------------------*/
function clause is_CSR_accessible(0x350, _, _) = sys_spmp_enabled
function clause read_CSR(0x350) = miselect
function clause write_CSR((0x350, value)) = {
  miselect = value;
  Ok(miselect)
}

/*---------------------------------------------------------------------------------------*/
/*  mireg CSR (0x351) - M-mode indirect access to spmpaddr                              */
/*  Reads/writes spmpaddr[miselect_get_spmp_index()] when miselect in SPMP range       */
/*---------------------------------------------------------------------------------------*/
function clause is_CSR_accessible(0x351, _, _) = sys_spmp_enabled
function clause read_CSR(0x351) = {
  if miselect_is_spmp() then {
    let entry_idx = miselect_get_spmp_index();
    spmp_mmode_read_addr_indirect(entry_idx)
  } else {
    /* miselect not in SPMP range - return 0 */
    zeros()
  }
}
function clause write_CSR((0x351, value)) = {
  if miselect_is_spmp() then {
    let entry_idx = miselect_get_spmp_index();
    spmp_mmode_write_addr_indirect(entry_idx, value);
  };
  /* else: miselect not in SPMP range - ignored */
  Ok(zeros())
}

/*---------------------------------------------------------------------------------------*/
/*  mireg2 CSR (0x352) - M-mode indirect access to spmpcfg                              */
/*  Reads/writes spmpcfg[miselect_get_spmp_index()] when miselect in SPMP range        */
/*  M-mode can clear L bit via this interface (the ONLY way to unlock SPMP entries)    */
/*---------------------------------------------------------------------------------------*/
function clause is_CSR_accessible(0x352, _, _) = sys_spmp_enabled
function clause read_CSR(0x352) = {
  if miselect_is_spmp() then {
    let entry_idx = miselect_get_spmp_index();
    let cfg = spmp_mmode_read_cfg_indirect(entry_idx);
    zero_extend(cfg.bits)
  } else {
    /* miselect not in SPMP range - return 0 */
    zeros()
  }
}
function clause write_CSR((0x352, value)) = {
  if miselect_is_spmp() then {
    let entry_idx = miselect_get_spmp_index();
    /* M-mode has full access - can write any field including clearing L bit.
     * This is the ONLY way to unlock SPMP entries per spec:
     * "The lock bit (spmpcfg[i].L) of an SPMP entry can only be cleared by
     *  M-mode through an indirect access using miselect."
     */
    let new_cfg = Mk_Spmpcfg_ent(value[9..0]);
    spmp_mmode_write_cfg_indirect(entry_idx, new_cfg);
  };
  /* else: miselect not in SPMP range - ignored */
  Ok(zeros())
}

/*---------------------------------------------------------------------------------------*/
/*  mireg3-mireg6 CSRs (0x353, 0x355-0x357) - Reserved as WPRI                          */
/*---------------------------------------------------------------------------------------*/
function clause is_CSR_accessible(0x353, _, _) = sys_spmp_enabled
function clause is_CSR_accessible(0x355, _, _) = sys_spmp_enabled
function clause is_CSR_accessible(0x356, _, _) = sys_spmp_enabled
function clause is_CSR_accessible(0x357, _, _) = sys_spmp_enabled

function clause read_CSR(0x353) = zeros()  /* mireg3 - reserved WPRI */
function clause read_CSR(0x355) = zeros()  /* mireg4 - reserved WPRI */
function clause read_CSR(0x356) = zeros()  /* mireg5 - reserved WPRI */
function clause read_CSR(0x357) = zeros()  /* mireg6 - reserved WPRI */

function clause write_CSR((0x353, _)) = Ok(zeros())  /* mireg3 - ignored */
function clause write_CSR((0x355, _)) = Ok(zeros())  /* mireg4 - ignored */
function clause write_CSR((0x356, _)) = Ok(zeros())  /* mireg5 - ignored */
function clause write_CSR((0x357, _)) = Ok(zeros())  /* mireg6 - ignored */

/* Initialize miselect register on reset */
function miselect_reset() -> unit = {
  miselect = zeros();
}

/* Initialize siselect register on reset */
function siselect_reset() -> unit = {
  siselect = zeros();
}
