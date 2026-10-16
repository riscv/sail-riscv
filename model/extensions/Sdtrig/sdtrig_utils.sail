// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// This was declared in `sdtrig_types.sail` since it is needed to define `mcontrol6`
// but the implementation needs the vector of fully-defined triggers.
function allow_chain_at(idx) = {
  // TODO: Once `dmode` is supported, set `chain` to false
  // if the next trigger has `dmode` set to true.
  // TODO: Once `dmode` is supported, ignore writes that set `dmode` if
  // the previous trigger is in a chain and has an unset `dmode`.

  // Note: the below check will allow a chain at `idx` even if the
  // next trigger is of a different type.  This allows the debugger
  // more flexibility in configuring chains, since it can configure
  // them in increasing order.  Disallowing will require debuggers to
  // configure them in reverse order, and prevent modelling other
  // implementations that allow such chain termination.

  var prev_chain_length : nat = 0;
  var in_chain : bool = true;
  foreach (i from idx - 1 downto 0) {
    if in_chain then {
      if trigger_is_in_chain(triggers[i])
      then prev_chain_length = prev_chain_length + 1
      else in_chain = false;
    }
  };

  var next_chain_length : nat = 0;
  in_chain = true;
  foreach (i from idx + 1 to num_triggers - 1) {
    if in_chain then {
      next_chain_length = next_chain_length + 1;
      in_chain = trigger_is_in_chain(triggers[i]);
    };
  };

  prev_chain_length + 1 + next_chain_length <= sdtrig_max_chain_limit
}
