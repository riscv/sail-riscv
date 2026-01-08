// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

private function check_privs() -> bool = {
  if hartSupports(Ext_S) & not(hartSupports(Ext_U))
  then {
    print_endline("User mode (U) should be enabled if supervisor mode (S) is enabled.");
    return false;
  };
  true
}

// This logic will need to change once MXL/SXL/UXL can differ.
private function check_mmu_config() -> bool = {
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
  if hartSupports(Ext_Svrsw60t59b) & not(hartSupports(Ext_Sv39))
  then {
    valid = false;
    print_endline("Svrsw60t59b is enabled but Sv39 is disabled: supporting Svrsw60t59b requires supporting Sv39.");
  };
  valid
}

private function check_vlen_elen() -> bool = {
  // Should this be conditioned on a vector extension being enabled?

  // Due to the `constraint elen_exp <= vlen_exp` the Sail compiler will
  // dead-code eliminate this check without the `: nat` type annotations.
  // Technically it could still eliminate the check even with `: nat`, and
  // by running any code that violates the `constraint` we're invoking UB.
  // However this does work in practice for now so it's probably better
  // than nothing. The proper fix is: https://github.com/rems-project/sail/issues/1387
  if (vlen_exp : nat) < (elen_exp : nat)
  then {
    print_endline("VLEN (set to 2^" ^ dec_str(vlen_exp) ^ ") cannot be less than ELEN (set to 2^" ^ dec_str(elen_exp) ^ ").");
    return false;
  };
  // The above comment about dead code elimination applies here too.
  if (vlen_exp : nat) < 3 | (vlen_exp : nat) > 16
  then {
    print_endline("VLEN set to 2^" ^ dec_str(vlen_exp) ^ " but must be within [2^3, 2^16].");
    return false;
  };
  if (elen_exp : nat) < 3 | (elen_exp : nat) > 16
  then {
    print_endline("ELEN set to 2^" ^ dec_str(elen_exp) ^ " but must be within [2^3, 2^16].");
    return false;
  };
  true
}

private function check_vext_config() -> bool = {
  var valid : bool = true;
  // Standard Vector Extensions
  if vector_support_level >= Integer & (elen_exp : nat) < 5 then {
    valid = false;
    print_endline("Zve*x is enabled but ELEN is 2^" ^ dec_str(elen_exp) ^ ": ELEN must be >= 2^5");
  };
  if vector_support_level >= Float_single & not(hartSupports(Ext_F)) then {
    valid = false;
    print_endline("Zve*f is enabled but F is disabled: supporting Zve*f requires F.");
  };
  if vector_support_level >= Float_double then {
    if (elen_exp : nat) < 6 then {
      valid = false;
      print_endline("Zve*d is enabled but ELEN is 2^" ^ dec_str(elen_exp) ^ ": ELEN must be >= 2^6");
    };
    if not(hartSupports(Ext_D)) then {
      valid = false;
      print_endline("Zve*d is enabled but D is disabled: supporting Zve*d requires D.");
    };
  };
  if hartSupports(Ext_Zve32x) & not(hartSupports(Ext_Zicsr)) then {
    valid = false;
    print_endline("Zve32x is enabled but Zicsr is disabled: supporting Zve32x requires Zicsr.");
  };
  if hartSupports(Ext_Zve32x) & not(hartSupports(Ext_Zvl32b)) then {
    valid = false;
    print_endline("VLEN (set to 2^" ^ dec_str(vlen_exp) ^ ") is below the minimum required for Zve32x (need Zvl32b).");
  };
  if hartSupports(Ext_Zve64x) & not(hartSupports(Ext_Zvl64b)) then {
    valid = false;
    print_endline("VLEN (set to 2^" ^ dec_str(vlen_exp) ^ ") is below the minimum required for Zve64x (need Zvl64b).");
  };
  if vector_support_level >= Full & not(hartSupports(Ext_Zvl128b)) then {
    valid = false;
    print_endline("VLEN (set to 2^" ^ dec_str(vlen_exp) ^ ") is below the minimum required for V (need Zvl128b).");
  };
  if hartSupports(Ext_Zvfhmin) & not(hartSupports(Ext_Zve32f)) then {
    valid = false;
    print_endline("Zvfhmin is enabled but Zve32f is disabled: Zvfhmin requires Zve32f.");
  };
  if hartSupports(Ext_Zvfh) & (not(hartSupports(Ext_Zve32f)) | not(hartSupports(Ext_Zfhmin))) then {
    valid = false;
    print_endline("Zvfh is enabled but Zve32f and/or Zfhmin are disabled: Zvfh requires Zve32f and Zfhmin.");
  };
  // Cryptography Extensions: Vector Instructions
  if hartSupports(Ext_Zvbb) & not(hartSupports(Ext_Zve32x)) then {
    valid = false;
    print_endline("Zvbb is enabled but Zve32x is disabled: Zvbb requires Zve32x.");
  };
  if hartSupports(Ext_Zvbc) & not(hartSupports(Ext_Zve64x) | hartSupports(Ext_V)) then {
    valid = false;
    print_endline("Zvbc is enabled but Zve64x and V are disabled: Zvbc requires Zve64x or V.");
  };
  if hartSupports(Ext_Zvkb) & not(hartSupports(Ext_Zve32x)) then {
    valid = false;
    print_endline("Zvkb is enabled but Zve32x is disabled: Zvkb requires Zve32x.");
  };
  if hartSupports(Ext_Zvkg) & not(hartSupports(Ext_Zve32x)) then {
    valid = false;
    print_endline("Zvkg is enabled but Zve32x is disabled: Zvkg requires Zve32x.");
  };
  if hartSupports(Ext_Zvkned) & not(hartSupports(Ext_Zve32x)) then {
    valid = false;
    print_endline("Zvkned is enabled but Zve32x is disabled: Zvkned requires Zve32x.");
  };
  if hartSupports(Ext_Zvknha) & not(hartSupports(Ext_Zve32x)) then {
    valid = false;
    print_endline("Zvknha is enabled but Zve32x is disabled: Zvknha requires Zve32x.");
  };
  if hartSupports(Ext_Zvknhb) & not(hartSupports(Ext_Zve64x) | hartSupports(Ext_V)) then {
    valid = false;
    print_endline("Zvknhb is enabled but Zve64x and V are disabled: Zvknhb requires Zve64x or V.");
  };
  if hartSupports(Ext_Zvksed) & not(hartSupports(Ext_Zve32x)) then {
    valid = false;
    print_endline("Zvksed is enabled but Zve32x is disabled: Zvksed requires Zve32x.");
  };
  if hartSupports(Ext_Zvksh) & not(hartSupports(Ext_Zve32x)) then {
    valid = false;
    print_endline("Zvksh is enabled but Zve32x is disabled: Zvksh requires Zve32x.");
  };
  if hartSupports(Ext_Zvkt) & not(hartSupports(Ext_Zve32x)) then {
    valid = false;
    print_endline("Zvkt is enabled but Zve32x is disabled: Zvkt requires Zve32x.");
  };
  valid;
}

// Return true if a list of PMA regions are sorted and don't overlap.
private function check_pma_regions(pmas : list(PMA_Region), prev_base : bits(64), prev_size : bits(64)) -> bool =
  match pmas {
    [||] => true,
    pma :: rest => {
      if pma.base <_u prev_base + prev_size then {
        print_endline("Memory region starting at " ^ bits_str(pma.base) ^
                      " is not above the end of the previous region starting at " ^
                      bits_str(prev_base) ^ " and ending at " ^ bits_str(prev_base + prev_size) ^ ".");
        return false;
      };
      check_pma_regions(rest, pma.base, pma.size)
    },
  }

// Return true iff [addr, addr+size) is fully contained in a single configured PMA memory region.
function dtb_within_configured_pma_memory(addr : bits(64), size : bits(64)) -> bool =
  is_some(matching_pma_bits_range(pma_regions, addr, size))

// Check that all memory regions are sorted and don't overlap.
private function check_mem_layout() -> bool =
  if pma_regions == [||] then {
    print_endline("No memory regions specified.");
    false
  } else check_pma_regions(pma_regions, zeros(), zeros())

private function check_pmp() -> bool = {
  var valid : bool = true;
  if (config memory.pmp.na4_supported : bool) & sys_pmp_grain != 0
  then {
    valid = false;
    print_endline("NA4 is not supported if the PMP grain G is non-zero.");
  };
  if sys_pmp_usable_count > sys_pmp_count
  then {
    valid = false;
    print_endline("The number of usable PMP entries cannot exceed the total number of PMP entries.");
  };
  valid
}

private function check_required_sstvala_option(name : string, value : bool) -> bool = {
  if not(value) then {
    print_endline("The Sstvala extension is enabled but " ^ name ^ " have not been configured (under `base.xtval_nonzero`) to write xtval.");
    false
  } else {
    true
  }
}

private function check_misc_extension_dependencies() -> bool = {
  var valid : bool = true;
  if hartSupports(Ext_F) & hartSupports(Ext_Zfinx) then {
    valid = false;
    print_endline("The F and Zfinx extensions are mutually exclusive and cannot be supported simultaneously.");
  };
  if hartSupports(Ext_Zfinx) & not(hartSupports(Ext_Zicsr)) then {
    valid = false;
    print_endline("The Zfinx extensions is enabled but Zicsr is disabled: supporting Zfinx requires Zicsr.");
  };
  if hartSupports(Ext_Zdinx) & not(hartSupports(Ext_Zfinx)) then {
    valid = false;
    print_endline("The Zdinx extensions is enabled but Zfinx is disabled: supporting Zdinx requires Zfinx.");
  };
  if hartSupports(Ext_Zhinx) & not(hartSupports(Ext_Zfinx)) then {
    valid = false;
    print_endline("The Zhinx extensions is enabled but Zfinx is disabled: supporting Zhinx requires Zfinx.");
  };
  if hartSupports(Ext_Zhinxmin) & not(hartSupports(Ext_Zfinx)) then {
    valid = false;
    print_endline("The Zhinxmin extensions is enabled but Zfinx is disabled: supporting Zhinxmin requires Zfinx.");
  };
  if hartSupports(Ext_Zicfilp) & not(hartSupports(Ext_Zicsr)) then {
    valid = false;
    print_endline("The Zicfilp extension is enabled but Zicsr is disabled: supporting Zicfilp requires Zicsr.");
  };
  if hartSupports(Ext_Zfbfmin) & not(hartSupports(Ext_F)) then {
    valid = false;
    print_endline("The Zfbfmin extension is enabled but F is disabled: supporting Zfbfmin requires F.");
  };
  if hartSupports(Ext_Zvfbfmin) & not(hartSupports(Ext_Zve32f)) then {
    valid = false;
    print_endline("The Zvfbfmin extension is enabled but Zve32f is disabled: supporting Zvfbfmin requires Zve32f.")
  };
  if hartSupports(Ext_Zvfbfwma) & (not(hartSupports(Ext_Zfbfmin)) | not(hartSupports(Ext_Zvfbfmin))) then {
    valid = false;
    print_endline("The Zvfbfwma extension is enabled but either Zfbfmin or Zvfbfmin is disabled: supporting Zvfbfwma requires Zfbfmin and Zvfbfmin.")
  };
  if hartSupports(Ext_Sstvala) then {
    if not(hartSupports(Ext_S)) then {
      valid = false;
      print_endline("The Sstvala extension writes `stval` which requires supervisor mode (S) but supervisor mode is not enabled.");
    };
    // `stval` must be written with the faulting virtual address for load, store, and instruction page-fault,
    // access-fault, and misaligned exceptions, and for breakpoint exceptions other than those caused by execution of
    // the EBREAK or C.EBREAK instructions. For virtual-instruction and illegal-instruction exceptions, `stval` must be
    // written with the faulting instruction.
    // TODO: add validation for virtual-instruction exceptions.
    valid = valid & check_required_sstvala_option("load page-faults", load_page_fault_writes_xtval);
    valid = valid & check_required_sstvala_option("load access-faults", load_access_fault_writes_xtval);
    valid = valid & check_required_sstvala_option("misaligned load exceptions", misaligned_load_writes_xtval);
    valid = valid & check_required_sstvala_option("store/AMO page-faults", samo_page_fault_writes_xtval);
    valid = valid & check_required_sstvala_option("store/AMO access-faults", samo_access_fault_writes_xtval);
    valid = valid & check_required_sstvala_option("misaligned store/AMO exceptions", misaligned_samo_writes_xtval);
    valid = valid & check_required_sstvala_option("fetch page-faults", fetch_page_fault_writes_xtval);
    valid = valid & check_required_sstvala_option("fetch access-faults", fetch_access_fault_writes_xtval);
    valid = valid & check_required_sstvala_option("misaligned fetch exceptions", misaligned_fetch_writes_xtval);
    valid = valid & check_required_sstvala_option("hardware breakpoint exceptions", hardware_breakpoint_writes_xtval);
    valid = valid & check_required_sstvala_option("illegal instruction exceptions", illegal_instruction_writes_xtval);
  };
  if hartSupports(Ext_Ssqosid) & not(hartSupports(Ext_Zicsr)) then {
    valid = false;
    print_endline("The Ssqosid extensions is enabled but Zicsr is disabled: supporting Ssqosid requires Zicsr.");
  };
  valid
}

private function check_pma_regions_zicclsm(pmas : list(PMA_Region)) -> bool =
  match pmas {
    [||] => true,
    pma :: rest => {
      let attr = pma.attributes;
      if memory_region_type(attr) == MainMemory & attr.cacheable & attr.coherent
      & attr.misaligned_fault != NoFault then {
        return false;
      };
      check_pma_regions_zicclsm(rest)
    },
  }

private function check_extension_param_constraints() -> bool = {
  var valid : bool = true;
  if hartSupports(Ext_Zic64b) & (plat_cache_block_size_exp != 6) then {
    valid = false;
    print_endline("The Zic64b extension is enabled but the cache block size is not 64 bytes.");
  };
  let min_rss_exp = log2_xlen - 3;
  if (hartSupports(Ext_A) | hartSupports(Ext_Zalrsc)) & (plat_reservation_set_size_exp < min_rss_exp) then {
    valid = false;
    print_endline("The A or Zalrsc extensions are enabled, but the reservation set size of 2^" ^ dec_str(plat_reservation_set_size_exp) ^
                  " is too small; it should be at least 2^" ^ dec_str(min_rss_exp) ^
                  " for the LR/SC operands on this platform.");
  };
  if hartSupports(Ext_Zicclsm) & not(check_pma_regions_zicclsm(pma_regions)) then {
    valid = false;
    print_endline("The Zicclsm extension is enabled but at least one main memory region that is cacheable and coherent does not support misaligned accesses (misaligned_fault is not NoFault).");
  };
  valid
}

private function check_stateen_config() -> bool = {
  if not(hartSupports(Ext_Smstateen)) & not(hartSupports(Ext_Ssstateen)) then return true;
  var valid : bool = true;
  if config extensions.Stateen.SE0_readonly_zero : bool & hartSupports(Ext_H) then {
    valid = false;
    print_endline("Stateen SE0_readonly_zero is true but H extension is supported: SE0 must be writable when H is implemented.");
  };
  // TODO: Update when Zcmt is implemented
  if config extensions.Stateen.SE0_readonly_zero : bool & (hartSupports(Ext_Zfinx) | not(config extensions.Stateen.C_readonly_zero : bool)) then {
    valid = false;
    print_endline("Stateen SE0_readonly_zero is true but sstateen0 has writable bits (FCSR due to Zfinx support or C due to disabled C_readonly_zero): SE0 must be writable.");
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
  & check_misc_extension_dependencies()
  & check_extension_param_constraints()
  & check_stateen_config()
}
