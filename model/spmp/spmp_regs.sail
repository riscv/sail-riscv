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
/*  CSR Address Space ( Section 2.1):                                   */
/*    0x1A0-0x1AF: spmpcfg0-spmpcfg15   (Configuration registers)                       */
/*    0x1B0-0x1EF: spmpaddr0-spmpaddr63 (Address registers)                             */
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
let sys_spmp_enabled : bool = config memory.spmp.enabled  // Platform SPMP support
let sys_spmp_count : nat = config memory.spmp.count       // Number of SPMP entries

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
/*  SPMP Configuration Register CSR Name Mappings (0x1A0-0x1AF)                        */
/*                                                                                       */
/*  Each spmpcfg register contains configuration for multiple SPMP entries:             */
/*    - RV32: 4 entries per register (8 bits each)                                      */
/*    - RV64: 8 entries per register (8 bits each)                                      */
/*                                                                                       */
/*  Configuration bits per entry ( Section 2.2):                       */
/*    [7]: L - Lock bit (prevents further modifications when set)                       */
/*    [6]: S - Supervisor/User mode shared permission management (Section 2.3)         */
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
/*                                                                                       */
/*  Direct CSR access via 0x1A0-0x1EF addresses is disabled in favor of               */
/*  indirect access for better performance and context switching.                      */
/*=======================================================================================*/

mapping clause csr_name_map = 0x1F0  <-> "spmpswitch" // SPMP domain switch register
mapping clause csr_name_map = 0x1F1  <-> "spmpswitchh" // SPMP domain switch register high (RV32 only)

/*=======================================================================================*/
/*  SPMP Context Switching Optimization (Section 2.8)                                  */
/*                                                                                       */
/*  The spmpswitch registers provide context switching optimization by allowing         */
/*  software to activate/deactivate SPMP entries without modifying configuration.      */
/*                                                                                       */
/*  Register Layout:                                                                     */
/*    - RV32: spmpswitch (entries 0-31) + spmpswitchh (entries 32-63)                  */
/*    - RV64: spmpswitch (entries 0-63)                                                 */
/*                                                                                       */
/*  Activation Rule:                                                                     */
/*    An entry is active only when: spmpswitch[i] & (spmp[i]cfg.A != OFF)              */
/*                                                                                       */
/*  Special Cases:                                                                       */
/*    - When spmpswitch[i] == 0 and spmp[i]cfg.L == 1, entry i remains enabled        */
/*    - TOR entries match regardless of spmpswitch[i-1] value                          */
/*    - spmpswitch registers must be cleared on reset                                   */
/*=======================================================================================*/

/* SPMP switch registers - control activation of SPMP entries */
register spmpswitch : xlenbits
register spmpswitchh : bits(32)  // Only used in RV32

/* SPMP configuration entries */

/* Reuse PmpAddrMatchType */
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

/* Helper function to extract RWX as a 3-bit field for permission encoding checks
 * The RWX field is a combined 3-bit encoding where certain combinations have special meaning.
 * See spmpCheckRWX() in spmp_control.sail for the full permission matrix.
 * Encoding (bits [2:0] = XWR):
 *   000 (0x0): Deny all access
 *   001 (0x1): Read-only
 *   010 (0x2): Reserved (deny all)
 *   011 (0x3): Read/Write
 *   100 (0x4): Execute-only
 *   101 (0x5): Read/Execute
 *   110 (0x6): Reserved (deny all)
 *   111 (0x7): Read/Write/Execute  
 *   X = bit 2
 * But wait, let me check PMP implementation... */

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
    let old_pmpnum_val = unsigned(mpmpdeleg[pmpnum]);
    
    /* Check if new pmpnum would override locked entries (either PMP or SPMP)
     * - Decreasing pmpnum: PMP entries in [new_pmpnum, old_pmpnum) become SPMP entries
     *   => Check if any of these PMP entries are locked
     * - Increasing pmpnum: SPMP entries in [old_pmpnum, new_pmpnum) become PMP entries
     *   => Check if any of these SPMP entries are locked
     */
    var has_locked_entry : bool = false;
    
    if pmpnum_val < old_pmpnum_val then {
      /* Decreasing pmpnum - check if any PMP entries in [pmpnum_val, old_pmpnum) are locked */
      foreach (i from pmpnum_val to (old_pmpnum_val - 1)) {
        assert(i >= 0 & i < 64);
        if pmpLocked(pmpcfg_n[i]) then {
          has_locked_entry = true;
        }
      };
    } else if pmpnum_val > old_pmpnum_val then {
      /* Increasing pmpnum - check if any SPMP entries in [old_pmpnum, pmpnum_val) are locked */
      foreach (i from old_pmpnum_val to (pmpnum_val - 1)) {
        assert(i >= 0 & i < 64);
        if spmpLocked(spmpcfg_n[i]) then {
          has_locked_entry = true;
        }
      };
    };
    /* else: pmpnum_val == old_pmpnum_val, no change needed */
    
    /* If no locked entries would be overridden, allow the write */
    if not(has_locked_entry) then {
      /* Clamp pmpnum to valid range [0, 64] */
      if pmpnum_val <= 64 then {
        mpmpdeleg = [mpmpdeleg with pmpnum = new_pmpnum];
      } else {
        /* If value exceeds 64, set to 64 (no delegation) */
        mpmpdeleg = [mpmpdeleg with pmpnum = 0b1000000];  // 64 in binary
      }
    }
    /* else: ignore write if it would override locked entries */
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

/* Check if SPMP entry index is valid for current privilege */
function spmpCheckEntryAccess(entry_idx: range(0, 63), priv: Privilege) -> bool = {
  let (min_idx, max_idx) = getSpmpValidRange();
  (entry_idx >= min_idx) & (entry_idx <= max_idx)
}

/* Read SPMP address register via indirect access */
function spmp_read_addr_indirect(entry_idx: range(0, 63)) -> xlenbits = {
  if spmpCheckEntryAccess(entry_idx, cur_privilege) then {
    assert(entry_idx >= 0 & entry_idx < 64);
    spmpaddr_n[entry_idx]
  } else {
    zeros()
  }
}

/* Enhanced SPMP configuration read with range checking */
function spmp_read_cfg_indirect(entry_idx: range(0, 63)) -> Spmpcfg_ent = {
  if spmpCheckEntryAccess(entry_idx, cur_privilege) then {
    assert(entry_idx >= 0 & entry_idx < 64);
    spmpcfg_n[entry_idx]
  } else {
    Mk_Spmpcfg_ent(0b0000000000)
  }
}

/* Write SPMP address register via indirect access */
function spmp_write_addr_indirect(entry_idx: range(0, 63), value: xlenbits) -> unit = {
  if spmpCheckEntryAccess(entry_idx, cur_privilege) then {
    assert(entry_idx >= 0 & entry_idx < 64);
    let cfg = spmpcfg_n[entry_idx];
    if not(spmpLocked(cfg)) then {
      spmpaddr_n[entry_idx] = value;
    }
  }
}

/* Write SPMP configuration register via indirect access */
function spmp_write_cfg_indirect(entry_idx: range(0, 63), cfg: Spmpcfg_ent) -> unit = {
  if spmpCheckEntryAccess(entry_idx, cur_privilege) then {
    assert(entry_idx >= 0 & entry_idx < 64);
    let current_cfg = spmpcfg_n[entry_idx];
    if not(spmpLocked(current_cfg)) then {
      spmpcfg_n[entry_idx] = cfg;
    }
  }
}

/* M-mode version with same range checking for consistency */
function spmp_mmode_write_cfg_indirect(entry_idx: range(0, 63), cfg: Spmpcfg_ent) -> unit = {
  if spmpCheckEntryAccess(entry_idx, Machine) then {
    assert(entry_idx >= 0 & entry_idx < 64);
    // M-mode can always write, even to locked entries
    spmpcfg_n[entry_idx] = cfg;
  }
}

/* M-mode configuration register read via miselect interface */
function spmp_mmode_read_cfg_indirect(entry_idx: range(0, 63)) -> Spmpcfg_ent = {
  if spmpCheckEntryAccess(entry_idx, Machine) then {
    assert(entry_idx >= 0 & entry_idx < 64);
    spmpcfg_n[entry_idx]
  } else {
    Mk_Spmpcfg_ent(0b0000000000)
  }
}

/* M-mode address register write via miselect interface */
function spmp_mmode_write_addr_indirect(entry_idx: range(0, 63), value: xlenbits) -> unit = {
  if spmpCheckEntryAccess(entry_idx, Machine) then {
    assert(entry_idx >= 0 & entry_idx < 64);
    // M-mode can always write, even to locked entries
    spmpaddr_n[entry_idx] = value;
  }
}

/* M-mode address register read via miselect interface */
function spmp_mmode_read_addr_indirect(entry_idx: range(0, 63)) -> xlenbits = {
  if spmpCheckEntryAccess(entry_idx, Machine) then {
    assert(entry_idx >= 0 & entry_idx < 64);
    spmpaddr_n[entry_idx]
  } else {
    zeros()
  }
}


/* Packing and unpacking spmpcfg regs for xlen-width accesses
 * Each SPMP configuration entry is 10 bits wide (bits [9:0]).
 * RV32: Pack 3 entries per register (30 bits used, 2 bits padding)
 * RV64: Pack 6 entries per register (60 bits used, 4 bits padding)
 */

function spmpReadCfgReg(n : range(0, 15)) -> xlenbits = {
  let spmp_start = getPmpNum();  // First SPMP hardware index
  if xlen == 32
  then {
    // RV32: 3 entries per register (10 bits each)
    let base = spmp_start + n * 3;
    if base + 2 < 64 then {
      zero_extend(spmpcfg_n[base + 2].bits @ spmpcfg_n[base + 1].bits @ spmpcfg_n[base + 0].bits)
    } else {
      zeros()
    }
  }
  else {
    // RV64: 6 entries per register (10 bits each)
    let base = spmp_start + n * 6;
    if base + 5 < 64 then {
      zero_extend(spmpcfg_n[base + 5].bits @ spmpcfg_n[base + 4].bits @ 
                  spmpcfg_n[base + 3].bits @ spmpcfg_n[base + 2].bits @ 
                  spmpcfg_n[base + 1].bits @ spmpcfg_n[base + 0].bits)
    } else {
      zeros()
    }
  }
}

/* Check if SPMP entry write is allowed based on privilege level and lock status.
 * 
 * L bit access control rules:
 * - M-mode: Can always read/write L bit and modify locked entries
 * - S-mode: Cannot modify locked entries (writes are ignored when L=1)
 * - The L bit is only accessible to M-mode for writes
 */
function spmpWriteCfg(n: range(0, 63), cfg: Spmpcfg_ent, v: bits(10), priv: Privilege) -> Spmpcfg_ent = {
  // Check if entry is locked and current privilege
  let is_locked = spmpLocked(cfg);
  let is_machine_mode = (priv == Machine);
  
  // If locked and not in M-mode, ignore write completely
  if is_locked & not(is_machine_mode) then cfg
  else {
    let new_cfg = Mk_Spmpcfg_ent(v);
    
    // Extract fields for WARL validation
    let rwx = new_cfg[X] @ new_cfg[W] @ new_cfg[R];
    let shared = new_cfg[SHARED];
    let u_bit = new_cfg[U];
    
    /* WARL (Write Any, Read Legal) validation:
     * According to spec, the following encodings are reserved for future standard use:
     * 1. SHARED=1, U=0 (reserved combination)
     * 2. RWX=010 (--W, write-only, reserved)
     * 3. RWX=011 (RW-, read+write but no execute, reserved)
     * 4. RWX=110 (-WX, write+execute but no read, reserved)
     * 
     * For reserved encodings, the write is ignored and the old value is preserved.
     */
    
    // Check for reserved SHARED=1, U=0 combination
    if (shared == 0b1) & (u_bit == 0b0) then {
      cfg  // Ignore write, preserve old value
    }
    else {
      // Check for reserved RWX encodings
      if (rwx == 0b010) | (rwx == 0b011) | (rwx == 0b110) then {
        cfg  // Ignore write, preserve old value
      }
      else {
        new_cfg  // Valid encoding - allow write
      }
    }
  }
}

function spmpWriteCfgReg(n : range(0, 15), v : xlenbits) -> unit = {
  let spmp_start = getPmpNum();  // First SPMP hardware index
  if xlen == 32
  then {
    // RV32: 3 entries per register (10 bits each)
    let base = spmp_start + n * 3;
    foreach (i from 0 to 2) {
      if base + i < 64 then {
        spmpcfg_n[base + i] = spmpWriteCfg(base + i, spmpcfg_n[base + i], v[(i * 10 + 9) .. (i * 10)], cur_privilege);
      }
    }
  }
  else {
    // RV64: 6 entries per register (10 bits each)
    let base = spmp_start + n * 6;
    foreach (i from 0 to 5) {
      if base + i < 64 then {
        spmpcfg_n[base + i] = spmpWriteCfg(base + i, spmpcfg_n[base + i], v[(i * 10 + 9) .. (i * 10)], cur_privilege);
      }
    }
  }
}

/* SPMP address register write with privilege-aware locking.
 * 
 * Address register write rules:
 * - M-mode: Can always write to address registers, even for locked entries
 * - S-mode: Cannot write to address registers of locked entries
 * - S-mode: Cannot write to spmpaddr[i-1] if spmp[i]cfg is locked and A=TOR
 */
function spmpWriteAddr(locked: bool, tor_locked: bool, reg: xlenbits, v: xlenbits, priv: Privilege) -> xlenbits = {
  let is_machine_mode = (priv == Machine);
  
  if xlen == 32
  then if (locked | tor_locked) & not(is_machine_mode) then reg else v
  else if (locked | tor_locked) & not(is_machine_mode) then reg else v
}

function spmpWriteAddrReg(n : range(0, 63), v : xlenbits) -> unit = {
  // Get current privilege for L bit access control
  let priv = cur_privilege;
  
  let current_cfg = spmp_read_cfg_indirect(n);
  let next_cfg = if n + 1 < 64 then spmp_read_cfg_indirect(n + 1) else Mk_Spmpcfg_ent(0b0000000000);
  let current_addr = spmp_read_addr_indirect(n);
  
  let new_addr = spmpWriteAddr(
    spmpLocked(current_cfg),
    spmpTORLocked(next_cfg),
    current_addr,
    v,
    priv
  );
  
  spmp_write_addr_indirect(n, new_addr);
}


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
