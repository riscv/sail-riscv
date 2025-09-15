// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Current fetch hooks for RISC-V extensions call extensions
// to check PC validity *before* standard fetch processing checks.

function isRVC(h : half) -> bool = not(h[1 .. 0] == 0b11)

val read_insn_bytes : forall 'n, 'n in {2, 4} .  (xlenbits, int('n)) -> result(bits('n * 8), FetchResult)
function read_insn_bytes(vaddr, num_bytes) = {
  match ext_fetch_check_pc(vaddr, vaddr + num_bytes) {
    Some(e) => Err(F_Ext_Error(e)),
    None()  =>
      match translateAddr(Virtaddr(vaddr), InstructionFetch()) {
        Err(e, _)     => Err(F_Error(e, vaddr)),
        Ok(paddr,  _) =>
          match mem_read(InstructionFetch(), paddr, num_bytes, false, false, false) {
            Err(e)         => Err(F_Error(e, vaddr)),
            Ok(insn_bytes) => Ok(insn_bytes)
          }
      }
  }
}

function fetch() -> FetchResult = {
  if get_config_rvfi()
  then return rvfi_fetch();

  match ext_fetch_check_pc(PC, PC) {
    Some(e) => return F_Ext_Error(e),
    None()  => (),
  };

  if   (PC[0] != bitzero | (PC[1] != bitzero & not(currentlyEnabled(Ext_Zca))))
  then return F_Error(E_Fetch_Addr_Align(), PC);

  // An implementation with the Ziccif extension fetches instructions in a manner
  // equivalent to the following state machine.
  // 1. Let M be min(ILEN,XLEN)/8, rounded up to the next power of 2. Let N be the
  //    pc modulo M. Atomically fetch M - N bytes from memory at address pc. Let T
  //    be the running total of bytes fetched, initially M - N.
  // 2. If the T bytes fetched begin with a complete instruction of length L <= T,
  //    then execute that instruction, discard the remaining T - L bytes fetched,
  //    and go back to step 1, using the updated pc.
  // 3. Otherwise, atomically fetch M bytes from memory at address pc + T,
  //    increment T by M, and go back to step 2.
  if PC[1] == bitzero & currentlyEnabled(Ext_Ziccif) then {
    match read_insn_bytes(PC, 4) {
      Err(fe) => fe,
      Ok(w32) => {
        if isRVC(w32[15..0]) then
          F_RVC(w32[15..0])
        else
          F_Base(w32)
      }
    }
  } else {
    match read_insn_bytes(PC, 2) {
      Err(fe) => fe,
      Ok(ilo) =>
        if isRVC(ilo) then
          F_RVC(ilo)
        else {
          let PC_hi = PC + 2;
          // Per rule 3, this should be a 4B fetch but the maximum ILEN is
          // 32 bits at the moment so this is equivalent
          match read_insn_bytes(PC_hi, 2) {
            Err(fe)  => fe,
            Ok(ihi) => {
              F_Base(append(ihi, ilo))
            }
          }
      }
    }
  }
}
