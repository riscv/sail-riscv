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

mapping clause csr_name_map = 0x183  <-> "spmpen"      // SPMP per-entry enable register
mapping clause csr_name_map = 0x193  <-> "spmpenh"     // SPMP per-entry enable register high (RV32 only)

/*=======================================================================================*/
/*  SPMP Context Switching Optimization - Sspmpen Extension                            */
/*                                                                                       */
/*  The spmpen registers provide context switching optimization by allowing         */
/*  software to activate/deactivate SPMP entries without modifying configuration.      */
/*                                                                                       */
/*  Register Layout:                                                                     */
/*    - RV32: spmpen (entries 0-31) + spmpenh (entries 32-63)                  */
/*    - RV64: spmpen (entries 0-63)                                                 */
/*                                                                                       */
/*  Activation Rule (per spec):                                                         */
/*    An entry i is active only when: sspmpen[i] & spmpcfg[i].A != 0               */
/*    - Switch bit must be set (= 1) AND                                               */
/*    - Address matching mode must not be OFF                                          */
/*                                                                                       */
/*  Lock Bit Behavior:                                                                   */
/*    When spmpcfg[i].L == 1, the corresponding sspmpen[i] bit becomes READ-ONLY.  */
/*    This prevents modification but does NOT automatically activate the entry.        */
/*    A locked entry with switch bit = 0 remains inactive.                             */
/*                                                                                       */
/*  TOR Mode Special Rule (per Sspmpen spec):                                          */
/*    For TOR entries, address matching [spmpaddr[i-1], spmpaddr[i]) is INDEPENDENT    */
/*    of the configuration or activation state of entry i-1:                           */
/*    - spmpcfg[i-1].A can be OFF                                                      */
/*    - sspmpen[i-1] can be 0 (inactive)                                           */
/*    The TOR range calculation always uses spmpaddr[i-1] value.                       */
/*                                                                                       */
/*  Memory Ordering:                                                                     */
/*    Writes to spmpen CSRs are NOT ordered with respect to subsequent memory      */
/*    accesses. Software must execute SFENCE.VMA (rs1=x0, rs2=x0) to enforce ordering. */
/*=======================================================================================*/

/* SPMP enable registers - control activation of SPMP entries */
register spmpen : xlenbits
register spmpenh : bits(32)  // Only used in RV32

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
mapping clause csr_name_map = 0x316 <-> "mpmpdeleg"

function clause is_CSR_accessible(0x316, _, _) = hartSupports(Ext_Sspmp)
function clause read_CSR(0x316) = mpmpdeleg.bits
function clause write_CSR((0x316, value)) = {
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

/* Check if LOGICAL SPMP entry index is valid for current delegation state.
 * logical_idx is the index from siselect (0-63 corresponding to 0x100-0x13F).
 * Valid range is [0, spmp_count) where spmp_count = 64 - pmpnum.
 */
function spmpCheckLogicalEntryAccess(logical_idx: int) -> bool = {
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
  if spmpCheckLogicalEntryAccess(entry_idx) then {
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
  if spmpCheckLogicalEntryAccess(entry_idx) then {
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
  if spmpCheckLogicalEntryAccess(entry_idx) then {
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
 * - cfg: current configuration value
 * - v: new configuration value to write
 * - priv: privilege level of the write operation
 */
function spmpWriteCfg(cfg: Spmpcfg_ent, v: bits(10), priv: Privilege) -> Spmpcfg_ent = {
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
   *
   * Sspmpss permits RWX=010 with SHARED=0 when menvcfg.SSE=1. satp.MODE is checked on access.
   */
  let ss_encoding_allowed = currentlyEnabled(Ext_Sspmpss) & menvcfg[SSE] == 0b1 & (rwx == 0b010) & (shared == 0b0);

  // Check for reserved SHARED=1, U=0 combination
  if (shared == 0b1) & (u_bit == 0b0) then {
    cfg  // Ignore write, preserve old value
  }
  else if ((rwx == 0b010) & not(ss_encoding_allowed)) | (rwx == 0b011) then {
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
  if spmpCheckLogicalEntryAccess(entry_idx) then {
    let hw_idx = spmpLogicalToHardwareIdx(entry_idx);
    if hw_idx >= 0 & hw_idx < 64 then {
      let current_cfg = spmpcfg_n[hw_idx];
      let is_locked = spmpLocked(current_cfg);

      /* Per spec: writes to locked entries via siselect are ignored (any privilege) */
      if not(is_locked) then {
        /* Apply WARL validation using spmpWriteCfg function */
        let new_cfg = spmpWriteCfg(current_cfg, cfg.bits, cur_privilege);
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
      let validated_cfg = spmpWriteCfg(current_cfg, cfg.bits, Machine);
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


// spmpen - SPMP per-entry enable register (RV64 and RV32)
function clause is_CSR_accessible(0x183, _, _) = hartSupports(Ext_Sspmpen)
function clause read_CSR(0x183) = spmpen
function clause write_CSR((0x183, value)) = {
  let spmp_start = getPmpNum();
  let spmp_end = 63;
  /* Bits below spmp_start correspond to PMP entries, not SPMP entries.
   * They are read-only-zero. Only bits [spmp_start .. 63] are writable.
   */
  var new_switch : xlenbits = zeros();
  foreach (hw_idx from spmp_start to spmp_end) {
    let in_range = if xlen == 32 then hw_idx < 32 else true;
    if in_range then {
      let cfg = spmpcfg_n[hw_idx];
      let is_locked = spmpLocked(cfg);
      let bit_idx = hw_idx;
      assert(bit_idx >= 0 & bit_idx < xlen);
      if is_locked then {
        new_switch = vector_update_subrange(new_switch, bit_idx, bit_idx, spmpen[bit_idx..bit_idx]);
      } else {
        new_switch = vector_update_subrange(new_switch, bit_idx, bit_idx, value[bit_idx..bit_idx]);
      }
    }
  };
  spmpen = new_switch;
  /* print_endline("DEBUG sail spmpen: new_switch=" ^ bits_str(new_switch)); */
  Ok(spmpen)
}

// spmpenh - SPMP per-entry enable register high (RV32 only)
function clause is_CSR_accessible(0x193, _, _) = hartSupports(Ext_Sspmpen) & (xlen == 32)
function clause read_CSR(0x193) = {
  if xlen == 32
  then zero_extend(spmpenh)
  else zeros()
}
function clause write_CSR((0x193, value)) = {
  if xlen == 32 then {
    let spmp_start = getPmpNum();
    let spmp_end = 63;
    var new_switchh : bits(32) = value[31 .. 0];
    foreach (hw_idx from spmp_start to spmp_end) {
      if hw_idx >= 32 then {
        let cfg = spmpcfg_n[hw_idx];
        let is_locked = spmpLocked(cfg);
        if is_locked then {
          let bit_idx = hw_idx - 32;
          assert(bit_idx >= 0 & bit_idx < 32);
          new_switchh = vector_update_subrange(new_switchh, bit_idx, bit_idx, spmpenh[bit_idx..bit_idx]);
        }
      }
    };
    spmpenh = new_switchh;
  };
  Ok(zero_extend(spmpenh))
}

/* Get the effective enable register value for 64-bit view */
function spmpGetFullEnReg() -> bits(64) = {
  if xlen == 32 then spmpenh @ spmpen
  else spmpen
}

/* Initialize SPMP enable registers on reset */
function spmpEnReset() -> unit = {
  spmpen = zeros();
  spmpenh = zeros();
}
