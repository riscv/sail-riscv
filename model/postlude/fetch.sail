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

  let pc_va   : virtaddr = PC;
  let pc_bits : xlenbits = bits_of_virtaddr(pc_va);

  match ext_fetch_check_pc(pc_bits, pc_bits) {
    Some(e) => return F_Ext_Error(e),
    None()  => (),
  };

  if   (pc_bits[0] != bitzero | (pc_bits[1] != bitzero & not(currentlyEnabled(Ext_Zca))))
  then return F_Error(E_Fetch_Addr_Align(), pc_bits);

  match translateAddr(pc_va, InstructionFetch()) {
    Err(e, _) => F_Error(e, pc_bits),
    Ok(ppclo, _) => {
      // split instruction fetch into 16-bit granules to handle RVC, as
      // well as to generate precise fault addresses in any fetch
      // exceptions.
      match mem_read(InstructionFetch(), ppclo, 2, false, false, false) {
        Err(e)  => F_Error(e, pc_bits),
        Ok(ilo) =>
          if   isRVC(ilo)
          then F_RVC(ilo)
          else {
            // fetch PC check for the next instruction granule
            let pc_hi_bits : xlenbits = pc_bits + 2;
            let pc_hi_va   : virtaddr = mk_virtaddr(pc_hi_bits);

            match ext_fetch_check_pc(pc_bits, pc_hi_bits) {
              Some(e) => return F_Ext_Error(e),
              None()  => (),
            };

            match translateAddr(pc_hi_va, InstructionFetch()) {
              Err(e, _) => F_Error(e, pc_hi_bits),
              Ok(ppchi, _) =>
                match mem_read(InstructionFetch(), ppchi, 2, false, false, false) {
                  Err(e)  => F_Error(e, pc_hi_bits),
                  Ok(ihi) => F_Base(append(ihi, ilo))
                }
            }
          }
      }
    }
  }
}
