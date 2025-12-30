// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

/*=======================================================================================*/
/*  SPMP Context Switch Optimization Test Functions                                     */
/*                                                                                       */
/*  This file contains test helper functions for validating the spmpswitch register    */
/*  implementation according to Section 2.8 of the SPMP specification.                 */
/*=======================================================================================*/

/* Test helper: Set up an SPMP entry for testing spmpswitch behavior */
function spmpTestSetupEntry(idx: range(0, 63), addr: xlenbits, cfg_bits: bits(10)) -> unit = {
  spmp_write_addr_indirect(idx, addr);
  spmp_write_cfg_indirect(idx, Mk_Spmpcfg_ent(cfg_bits));
}

/* Test helper: Check if spmpswitch bit is set for given entry */
function spmpTestSwitchBit(idx: range(0, 63)) -> bool = {
  if xlen == 32 then {
    if idx < 32 then spmpswitch[idx] == bitone
    else spmpswitchh[idx - 32] == bitone
  } else {
    spmpswitch[idx] == bitone
  }
}

/* Test helper: Set spmpswitch bit for given entry */
function spmpTestSetSwitchBit(idx: range(0, 63), value: bool) -> unit = {
  let bit_value : bits(1) = if value then 0b1 else 0b0;
  if xlen == 32 then {
    if idx < 32 then {
      spmpswitch = vector_update_subrange(spmpswitch, idx, idx, bit_value);
    } else {
      let bit_pos = idx - 32;
      spmpswitchh = vector_update_subrange(spmpswitchh, bit_pos, bit_pos, bit_value);
    }
  } else {
    spmpswitch = vector_update_subrange(spmpswitch, idx, idx, bit_value);
  }
}

/* Test helper: Verify SPMP entry activation according to Section 2.8 rules */
function spmpTestEntryActivation(idx: range(0, 63)) -> bool = {
  let cfg = spmp_read_cfg_indirect(idx);
  let match_type = spmpAddrMatchType_of_bits(cfg[A]);
  let switch_bit = spmpTestSwitchBit(idx);
  let is_locked = spmpLocked(cfg);
  
  /* Entry activation rules from Section 2.8:
   * 1. Entry is active when: spmpswitch[i] & (spmp[i]cfg.A != OFF)
   * 2. Special case: When spmpswitch[i] == 0 and spmp[i]cfg.L == 1, entry remains enabled
   * 3. TOR entries match regardless of spmpswitch[i-1] value
   */
  
  if match_type == OFF then false  // Disabled entries are never active
  else if is_locked then true      // Locked entries always remain enabled
  else if match_type == TOR then true  // TOR entries always match when A != OFF
  else switch_bit                  // Normal case: follow switch bit
}

/* Test scenario: Basic spmpswitch functionality */
function spmpTestBasicSwitch() -> bool = {
  // Reset SPMP state
  reset_spmp();
  
  // Set up entry 0 with NAPOT mode (not locked)
  spmpTestSetupEntry(0, to_bits(xlen, unsigned(0x1000)), 0b0000010011);  // A=NAPOT, R=1, W=1, X=0, L=0, SHARED=0, U=0
  
  // Initially switch bit should be 0 (after reset)
  let initial_active = spmpTestEntryActivation(0);
  
  // Set switch bit and verify activation
  spmpTestSetSwitchBit(0, true);
  let switch_active = spmpTestEntryActivation(0);
  
  // Clear switch bit and verify deactivation
  spmpTestSetSwitchBit(0, false);
  let switch_inactive = spmpTestEntryActivation(0);
  
  // Test should show: inactive -> active -> inactive
  not(initial_active) & switch_active & not(switch_inactive)
}

/* Test scenario: Locked entry behavior */
function spmpTestLockedEntry() -> bool = {
  // Reset SPMP state
  reset_spmp();
  
  // Set up entry 1 with locked NAPOT mode
  spmpTestSetupEntry(1, to_bits(xlen, unsigned(0x2000)), 0b0010010011);  // A=NAPOT, R=1, W=1, X=0, L=1, SHARED=0, U=0
  
  // Clear switch bit (locked entry should still be active)
  spmpTestSetSwitchBit(1, false);
  let locked_active = spmpTestEntryActivation(1);
  
  // Set switch bit (should remain active)
  spmpTestSetSwitchBit(1, true);
  let locked_still_active = spmpTestEntryActivation(1);
  
  // Locked entries should always be active regardless of switch bit
  locked_active & locked_still_active
}

/* Test scenario: TOR entry behavior */
function spmpTestTOREntry() -> bool = {
  // Reset SPMP state
  reset_spmp();
  
  // Set up entry 2 with TOR mode (not locked)
  spmpTestSetupEntry(2, to_bits(xlen, unsigned(0x3000)), 0b0000000011);  // A=TOR, R=1, W=1, X=0, L=0, SHARED=0, U=0
  
  // TOR entries should be active regardless of switch bit when A != OFF
  spmpTestSetSwitchBit(2, false);
  let tor_without_switch = spmpTestEntryActivation(2);
  
  spmpTestSetSwitchBit(2, true);
  let tor_with_switch = spmpTestEntryActivation(2);
  
  // TOR entries should always be active when configured (A != OFF)
  tor_without_switch & tor_with_switch
}

/* Integration test: Context switch optimization scenario */
function spmpTestContextSwitchOptimization() -> bool = {
  // Reset SPMP state
  reset_spmp();
  
  // Set up multiple entries for different tasks
  spmpTestSetupEntry(0, to_bits(xlen, unsigned(0x1000)), 0b0000010011);  // Task 1 region: NAPOT, R=1, W=1, X=0
  spmpTestSetupEntry(1, to_bits(xlen, unsigned(0x2000)), 0b0000010011);  // Task 2 region: NAPOT, R=1, W=1, X=0
  spmpTestSetupEntry(2, to_bits(xlen, unsigned(0x3000)), 0b0000010011);  // Task 3 region: NAPOT, R=1, W=1, X=0
  
  // Initially all switch bits are 0 (inactive)
  let all_inactive = not(spmpTestEntryActivation(0)) & 
                     not(spmpTestEntryActivation(1)) & 
                     not(spmpTestEntryActivation(2));
  
  // Activate Task 1 only
  spmpTestSetSwitchBit(0, true);
  let task1_only = spmpTestEntryActivation(0) & 
                   not(spmpTestEntryActivation(1)) & 
                   not(spmpTestEntryActivation(2));
  
  // Switch to Task 2 (disable Task 1, enable Task 2)
  spmpTestSetSwitchBit(0, false);
  spmpTestSetSwitchBit(1, true);
  let task2_only = not(spmpTestEntryActivation(0)) & 
                   spmpTestEntryActivation(1) & 
                   not(spmpTestEntryActivation(2));
  
  // Enable multiple tasks simultaneously
  spmpTestSetSwitchBit(0, true);
  spmpTestSetSwitchBit(2, true);
  let multiple_tasks = spmpTestEntryActivation(0) & 
                       spmpTestEntryActivation(1) & 
                       spmpTestEntryActivation(2);
  
  all_inactive & task1_only & task2_only & multiple_tasks
}

/* Test runner: Execute all spmpswitch tests */
function spmpRunSwitchTests() -> bool = {
  spmpTestBasicSwitch() & 
  spmpTestLockedEntry() & 
  spmpTestTOREntry() & 
  spmpTestContextSwitchOptimization()
}
