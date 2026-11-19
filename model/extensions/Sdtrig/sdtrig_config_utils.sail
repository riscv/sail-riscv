// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

private function is_supported_match_size(
  address_access_sizes : supported_address_access_sizes,
  data_access_sizes    : supported_data_access_sizes,
  s                    : bits(3),
  select               : Compare_Selection
) -> bool = {
  if not(trig_match_size_forwards_matches(s)) then return false;

  match select {
    // data compares are limited by the size of `tdata2`,
    // which is validated in `validate_config`.
    Compare_Data    => match trig_match_size(s) {
      0   => true,
      8   => data_access_sizes.bits8,
      16  => data_access_sizes.bits16,
      32  => data_access_sizes.bits32,
      48  => data_access_sizes.bits48,
      64  => data_access_sizes.bits64,
      128 => false,
    },
    Compare_Address => match trig_match_size(s) {
      0   => true,
      8   => address_access_sizes.bits8,
      16  => address_access_sizes.bits16,
      32  => address_access_sizes.bits32,
      48  => address_access_sizes.bits48,
      64  => address_access_sizes.bits64,
      128 => address_access_sizes.bits128,
    },
  }
}

private function idx_is_member(idx : config_trigger_index, idxs : list(config_trigger_index)) -> bool =
  match idxs {
    [||]      => false,
    i :: rest => if i == idx then true else idx_is_member(idx, rest),
  }

private function collect_info(idx : trigger_index, cfgs : list(trigger_config), info : bits(16)) -> bits(16) = {
  let flag = zero_extend(16, 0b1);

  match cfgs {
    [||] =>
      info,
    cfg :: rest => {
      var updated_info = info;
      match cfg {
        icount(c) =>
          if idx_is_member(idx, c.tselects) then {
            updated_info = updated_info | (flag << unsigned(trig_type_bits(TT_icount)))
          },
        itrigger(c) =>
          if idx_is_member(idx, c.tselects) then {
            updated_info = updated_info | (flag << unsigned(trig_type_bits(TT_itrigger)))
          },
        etrigger(c) =>
          if idx_is_member(idx, c.tselects) then {
            updated_info = updated_info | (flag << unsigned(trig_type_bits(TT_etrigger)))
          },
        mcontrol6(c) =>
          if idx_is_member(idx, c.tselects) then {
            updated_info = updated_info | (flag << unsigned(trig_type_bits(TT_mcontrol6)))
          },
      };
      collect_info(idx, rest, updated_info)
    },
  }
}

private function info_at_index(idx : trigger_index, cfgs : list(trigger_config)) -> bits(16) = {
  let flag = zero_extend(16, 0b1);

  // the model disables triggers via type 15, so it is always supported
  let info : bits(16) = flag << unsigned(trig_type_bits(TT_disabled));

  collect_info(idx, cfgs, info)
}

private function find_trigger_config_at(t : Trig_Type, idx : trigger_index, cfgs : list(trigger_config)) -> option(trigger_config) =
  match cfgs {
    [||] => None(),
    cfg :: rest => match (t, cfg) {
      // types that cannot be configured yet
      (TT_none,   _)       => None(),
      (TT_legacy, _)       => None(),
      (TT_mcontrol, _)     => None(),
      (TT_tmexttrigger, _) => None(),
      (TT_custom, _)       => None(),
      (TT_disabled, _)     => None(),
      (TT_reserved, _)     => None(),
      // configurable types
      (TT_icount, icount(c)) =>
        if idx_is_member(idx, c.tselects) then Some(cfg) else find_trigger_config_at(t, idx, rest),
      (TT_itrigger, itrigger(c)) =>
        if idx_is_member(idx, c.tselects) then Some(cfg) else find_trigger_config_at(t, idx, rest),
      (TT_etrigger, etrigger(c)) =>
        if idx_is_member(idx, c.tselects) then Some(cfg) else find_trigger_config_at(t, idx, rest),
      (TT_mcontrol6, mcontrol6(c)) =>
        if idx_is_member(idx, c.tselects) then Some(cfg) else find_trigger_config_at(t, idx, rest),
      _ =>
        find_trigger_config_at(t, idx, rest)
    }
  }

private function get_mcontrol6_config(cfg : trigger_config) -> option(mcontrol6_config) =
  match cfg {
    mcontrol6(c) => Some(c),
    _            => None(),
  }

private function get_icount_config(cfg : trigger_config) -> option(icount_config) =
  match cfg {
    icount(c) => Some(c),
    _         => None(),
  }

private function get_itrigger_config(cfg : trigger_config) -> option(itrigger_config) =
  match cfg {
    itrigger(c) => Some(c),
    _           => None(),
  }

private function get_etrigger_config(cfg : trigger_config) -> option(etrigger_config) =
  match cfg {
    etrigger(c) => Some(c),
    _           => None(),
  }

// utilities for validation

function trigger_type_of_config(cfg : trigger_config) -> Trig_Type =
  match cfg {
    mcontrol6(_) => TT_mcontrol6,
    icount(_)    => TT_icount,
    itrigger(_)  => TT_itrigger,
    etrigger(_)  => TT_etrigger,
  }

function trigger_config_uses_textra(cfg : trigger_config) -> bool =
  match cfg {
    mcontrol6(c) => is_some(c.textra_cfg),
    icount(c)    => is_some(c.textra_cfg),
    itrigger(c)  => is_some(c.textra_cfg),
    etrigger(c)  => is_some(c.textra_cfg),
  }
