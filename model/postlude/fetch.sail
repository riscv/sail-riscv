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

private function fetch() -> FetchResult = {
  // fetch PC check for extensions: extensions return a transformed PC to fetch,
  // but any exceptions use the untransformed PC.
  // TODO: Add a parameter to try_step() to allow forcing the fetch result and use that instead.

  if get_config_rvfi()
  then return rvfi_fetch();

  match ext_fetch_check_pc(PC, PC) {
    Some(e) => return F_Ext_Error(e),
    None()  => (),
  };

  if   (PC[0] != bitzero | (PC[1] != bitzero & not(currentlyEnabled(Ext_Zca))))
  then return F_Error(E_Fetch_Addr_Align(), mem_exception_context(PC, false));

  match translateAddr(Virtaddr(PC), InstructionFetch()) {
    Err(e, _)    => F_Error(e),
    Ok(ppclo, _) => {
      // split instruction fetch into 16-bit granules to handle RVC, as
      // well as to generate precise fault addresses in any fetch
      // exceptions.
      match mem_read(InstructionFetch(), ppclo, 2, false, false, false) {
        Err(e)  => F_Error(e, mem_exception_context(PC, false)),
        Ok(ilo) =>
          if   isRVC(ilo)
          then F_RVC(ilo)
          else {
            // fetch PC check for the next instruction granule
            let PC_hi = PC + 2;
            match ext_fetch_check_pc(PC, PC_hi) {
              Some(e) => return F_Ext_Error(e),
              None()  => (),
            };

            match translateAddr(Virtaddr(PC_hi), InstructionFetch()) {
              Err(e, _)    => F_Error(e),
              Ok(ppchi, _) =>
                match mem_read(InstructionFetch(), ppchi, 2, false, false, false) {
                  Err(e)  => F_Error(e, mem_exception_context(PC, false)),
                  Ok(ihi) => F_Base(append(ihi, ilo))
                }
            }
          }
      }
    }
  }
}
