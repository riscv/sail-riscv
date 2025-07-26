/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function check_privs() -> bool = {
  if hartSupports(Ext_S) & not(hartSupports(Ext_U))
  then {
    print_endline("User mode (U) should be enabled if supervisor mode (S) is enabled.");
    return false;
  };
  true
}

// This logic will need to change once MXL/SXL/UXL can differ.
function check_mmu_config() -> bool = {
  var valid : bool = true;
  if xlen == 64 then {
    if not(hartSupports(Ext_S)) & (hartSupports(Ext_Sv57) | hartSupports(Ext_Sv48) | hartSupports(Ext_Sv39))
    then {
      valid = false;
      print_endline("Supervisor mode (S) disabled but one of (Sv57, Sv48, Sv39) is enabled: cannot support address translation without supervisor mode.");
    };
    if hartSupports(Ext_Sv57) & not(hartSupports(Ext_Sv48))
    then {
      valid = false;
      print_endline("Sv57 is enabled but Sv48 is disabled: supporting Sv57 requires supporting Sv48.");
    };
    if hartSupports(Ext_Sv48) & not(hartSupports(Ext_Sv39))
    then {
      valid = false;
      print_endline("Sv48 is enabled but Sv39 is disabled: supporting Sv48 requires supporting Sv39.");
    };
    if hartSupports(Ext_Sv32)
    then {
      valid = false;
      print_endline("Sv32 is enabled: Sv32 is not supported on RV64.");
    };
  } else {
    assert(xlen == 32);
    if not(hartSupports(Ext_S)) & hartSupports(Ext_Sv32)
    then {
      valid = false;
      print_endline("Supervisor mode (S) is disabled but Sv32 is enabled: cannot support address translation without supervisor mode.");
    };
    if hartSupports(Ext_Sv39) | hartSupports(Ext_Sv48) |  hartSupports(Ext_Sv57)
    then {
      valid = false;
      print_endline("One or more of Sv39/Sv48/Sv57 is enabled: these are not supported on RV32.");
    };
  };
  valid
}

function check_vlen_elen() -> bool = {
  // Should this be conditioned on a vector extension being enabled?
  if VLEN_pow < ELEN_pow
  then {
    print_endline("VLEN (set to 2^" ^ dec_str(VLEN_pow) ^ ") cannot be less than ELEN (set to 2^" ^ dec_str(ELEN_pow) ^ ").");
    return false;
  };
  true
}

function check_vext_config() -> bool = {
  var valid : bool = true;
  if hartSupports(Ext_Zve32x)  & not(hartSupports(Ext_Zvl32b)) then {
    valid = false;
    print_endline("VLEN (set to 2^" ^ dec_str(VLEN_pow) ^ ") is below the minimum required for Zve32x (need Zvl32b).");
  };
  if hartSupports(Ext_Zve32f)  & (not(hartSupports(Ext_Zve32x)) | not(hartSupports(Ext_F))) then {
    valid = false;
    print_endline("Zve32f is enabled but Zve32x and/or F are disabled: supporting Zve32f requires Zve32x and F.");
  };
  if hartSupports(Ext_Zve64x) & not(hartSupports(Ext_Zvl64b)) then {
    valid = false;
    print_endline("VLEN (set to 2^" ^ dec_str(VLEN_pow) ^ ") is below the minimum required for Zve64x (need Zvl64b).");
  };
  if hartSupports(Ext_Zve64x) & not(hartSupports(Ext_Zve32x)) then {
    valid = false;
    print_endline("Zve64x is enabled but Zve32x is disabled: supporting Zve64x requires Zve32x.");
  };
  if hartSupports(Ext_Zve64f)  & (not(hartSupports(Ext_Zve64x)) | not(hartSupports(Ext_Zve32f))) then {
    valid = false;
    print_endline("Zve64f is enabled but Zve64x and/or Zve32f are disabled: Zve64f requires Zve64x and Zve32f.");
  };
  if hartSupports(Ext_Zve64d)  & (not(hartSupports(Ext_Zve64f)) | not(hartSupports(Ext_D))) then {
    valid = false;
    print_endline("Zve64d is enabled but Zve64f and/or D are disabled: Zve64d requires Zve64f and D.");
  };
  if hartSupports(Ext_V) & not(hartSupports(Ext_Zvl128b)) then {
    valid = false;
    print_endline("VLEN (set to 2^" ^ dec_str(VLEN_pow) ^ ") is below the minimum required for V (need Zvl128b).");
  };
  if hartSupports(Ext_V) & not(hartSupports(Ext_Zve64d)) then {
    valid = false;
    print_endline("V is enabled but Zve64d is disabled: V requires Zve64d.");
  };
  if hartSupports(Ext_Zvfhmin) & not(hartSupports(Ext_Zve32f)) then {
    valid = false;
    print_endline("Zvfhmin is enabled but Zve32f is disabled: Zvfhmin requires Zve32f.");
  };
  if hartSupports(Ext_Zvfh)    & (not(hartSupports(Ext_Zve32f)) | not(hartSupports(Ext_Zfhmin))) then {
    valid = false;
    print_endline("Zvfh is enabled but Zve32f and/or Zfhmin are disabled: Zvfh requires Zve32f and Zfhmin.");
  };
  valid;
}

function has_overlap(a_lo : nat, a_hi : nat, b_lo : nat, b_hi : nat) -> bool = {
  not((a_lo < b_lo & a_hi < b_lo) | (b_lo < a_lo & b_hi < a_lo))
}

// This will change when we have a more general memory layout.
function check_mem_layout() -> bool = {
  var valid : bool = true;
  // Memory regions should not overlap. There are currently only three: ram, rom and clint.
  let ram_lo = unsigned(plat_ram_base);
  let ram_hi = unsigned(plat_ram_base) + unsigned(plat_ram_size);
  let rom_lo = unsigned(plat_rom_base);
  let rom_hi = unsigned(plat_rom_base) + unsigned(plat_rom_size);
  let clint_lo = unsigned(plat_clint_base);
  let clint_hi = unsigned(plat_clint_base) + unsigned(plat_clint_size);
  if has_overlap(rom_lo, rom_hi, ram_lo, ram_hi)
  then {
    valid = false;
    print_endline("The RAM and ROM regions overlap.");
  };
  if has_overlap(clint_lo, clint_hi, rom_lo, rom_hi)
  then {
    valid = false;
    print_endline("The Clint and ROM regions overlap.");
  };
  if has_overlap(clint_lo, clint_hi, ram_lo, ram_hi)
  then {
    valid = false;
    print_endline("The Clint and RAM regions overlap.");
  };

  // Should memory regions also be 4K aligned?
  valid
}

function check_pmp() -> bool = {
  var valid : bool = true;
  if (config memory.pmp.na4_supported : bool) & sys_pmp_grain != 0
  then {
    valid = false;
    print_endline("NA4 is not supported if the PMP grain G is non-zero.");
  };
  valid
}

function config_is_valid() -> bool = {
    check_privs()
  & check_mmu_config()
  & check_mem_layout()
  & check_vlen_elen()
  & check_vext_config()
  & check_pmp()
}
