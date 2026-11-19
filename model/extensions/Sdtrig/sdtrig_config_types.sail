// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// The maximum number of triggers that can be configured.  This is
// primarily used to restrict the representation of indices in the
// configuration to small integers, as opposed to using natural
// numbers.  If you are changing this value, please also update
// the comment in `config.json.in` specifying the maximum value
// for `extensions.Sdtrig.num_triggers`.
type max_num_triggers : Int = 128
let max_num_triggers = sizeof(max_num_triggers)
type config_trigger_index = range(0, max_num_triggers - 1)

// The types used for the configuration file.  These try to capture
// the optionality in the trigger configuration.

struct mhselect_config = {
  mcontext_match : bool,
  vmid_match     : bool,
}

struct sselect_config = {
  scontext_match : bool,
  asid_match     : bool,
}

struct textra_config = {
  mhselect : mhselect_config,
  sselect  : sselect_config,
}

struct supported_address_access_sizes = {
  bits8   : bool,
  bits16  : bool,
  bits32  : bool,
  bits48  : bool,
  bits64  : bool,
  bits128 : bool,
}

struct supported_data_access_sizes = {
  bits8   : bool,
  bits16  : bool,
  bits32  : bool,
  bits48  : bool,
  bits64  : bool,
}

struct mcontrol6_config = {
  maskmax6                             : nat,
  address_select_matches_all_addresses : bool,
  supported_address_access_sizes       : supported_address_access_sizes,
  supported_data_access_sizes          : supported_data_access_sizes,
  textra_cfg                           : option(textra_config),
  tselects                             : list(config_trigger_index),
}

struct icount_config = {
  count_is_hardwired_one  : bool,
  self_write_sets_pending : bool,
  textra_cfg              : option(textra_config),
  tselects                : list(config_trigger_index),
}

struct itrigger_config = {
  supported_interrupts    : xlenbits,
  textra_cfg              : option(textra_config),
  tselects                : list(config_trigger_index),
}

struct etrigger_config = {
  supported_exceptions    : xlenbits,
  textra_cfg              : option(textra_config),
  tselects                : list(config_trigger_index),
}

union trigger_config = {
  mcontrol6 : mcontrol6_config,
  icount    : icount_config,
  itrigger  : itrigger_config,
  etrigger  : etrigger_config,
}

let configured_triggers : list(trigger_config) = config extensions.Sdtrig.triggers
