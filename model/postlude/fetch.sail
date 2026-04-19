// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Current fetch hooks for RISC-V extensions call extensions
// to check PC validity *before* standard fetch processing checks.

private function isRVC(h : half) -> bool = not(h[1 .. 0] == 0b11)

// This instruction byte fetcher is used for partial fetches, and
// hence doesn't return the FetchResult type that a full fetcher does.
// All the bytes fetched go through memory protection and PMA checks;
// this just barely works for Ziccif with ILEN=32 (bits) since there
// are no discarded bytes that lie outside protection boundaries.
// This will have to be generalized when ILEN is increased above 32
// (e.g. to 48): there could be discarded bytes that straddle
// protection boundaries in that case, and memory protection and PMA
// checks do not apply to discarded bytes.

private union FetchBytes_Result('width : Int), 'width >= 0 = {
  FetchBytes_Ext_Error : ext_fetch_addr_error,
  FetchBytes_Exception : ExceptionType,
  FetchBytes_Success   : bits('width * 8),
}

private function fetch_bytes forall 'n, 'n in {2, 4} . (fetch_start : xlenbits, granule_start : xlenbits, width : int('n)) -> FetchBytes_Result('n) = {
  match ext_fetch_check_pc(fetch_start, granule_start) {
    Some(e) => return FetchBytes_Ext_Error(e),
    None()  => (),
  };

  let (paddr, pbmt) : (physaddr, page_based_mem_type) = match translateAddr(Virtaddr(granule_start), InstructionFetch()) {
    Err(e, _)    => return FetchBytes_Exception(e),
    Ok(paddr, pbmt, _) => (paddr, pbmt),
  };

  match mem_read(InstructionFetch(), pbmt, paddr, width, false, false, false) {
    Err(e)    => FetchBytes_Exception(e),
    Ok(bytes) => FetchBytes_Success(bytes),
  }
}

private function fetch() -> FetchResult = {
  // TODO: Add a parameter to try_step() to allow forcing the fetch result and use that instead.

  if get_config_rvfi()
  then return rvfi_fetch();

  // Doing this check here assumes the external fetch checks are higher priority
  // than the following alignment check.
  match ext_fetch_check_pc(PC, PC) {
    Some(e) => return F_Ext_Error(e),
    None()  => (),
  };

  if   (PC[0] != 0b0 | (PC[1] != 0b0 & not(currentlyEnabled(Ext_Zca))))
  then return F_Error(E_Fetch_Addr_Align(), PC);

  // For a PC aligned at ILEN=32, perform an atomic fetch for Ziccif.
  //
  // NOTE: The atomicity requirements for the fetch can be implemented
  // in the memory model in two ways: (i) A single memory transaction
  // in Sail, i.e. the approach followed below, or (ii) multiple smaller
  // (e.g. 2-byte) fetches, along with rules in the memory model specifying
  // that nothing can intervene between these smaller
  // intra-instruction fetches.  The former approach is currently simpler
  // since it does not require any additional rules in the memory model.
  // However, if/when ILEN is increased to 48 and higher, it may be that
  // the complexities around memory protection could be addressed using
  // smaller fetches and augmenting the memory model with these additional
  // rules for intra-instruction split fetches.
  if is_aligned_addr(Virtaddr(PC), 4) & currentlyEnabled(Ext_Ziccif) then {
    match fetch_bytes(PC, PC, 4) {
      FetchBytes_Ext_Error(e)   => F_Ext_Error(e),
      FetchBytes_Exception(e)   => F_Error(e, PC),
      FetchBytes_Success(bytes) => if isRVC(bytes[15 .. 0]) then F_RVC(bytes[15 .. 0]) else F_Base(bytes),
    }
  } else {
    // Split instruction fetch into 16-bit granules to handle RVC, as
    // well as to generate precise fault addresses in any fetch
    // exceptions.
    match fetch_bytes(PC, PC, 2) {
      FetchBytes_Ext_Error(e) => F_Ext_Error(e),
      FetchBytes_Exception(e) => F_Error(e, PC),
      FetchBytes_Success(ilo) =>
        if   isRVC(ilo)
        then F_RVC(ilo)
        else match fetch_bytes(PC, PC + 2, 2) {
          FetchBytes_Ext_Error(e) => F_Ext_Error(e),
          FetchBytes_Exception(e) => F_Error(e, PC + 2),
          FetchBytes_Success(ihi) => F_Base(append(ihi, ilo)),
        },
    }
  }
}
