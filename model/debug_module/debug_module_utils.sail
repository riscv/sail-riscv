//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

// Get the current hart state from dmstatus
function get_hart_state() -> DebugHartState = {
  if dmstatus[allunavail] == 0b1 then UNAVAILABLE
  else if dmstatus[allhalted] == 0b1 then HALTED
  else if dmstatus[allrunning] == 0b1 then RUNNING
  else internal_error(__FILE__, __LINE__, "Hart in invalid state")
}

// Set the hart state in dmstatus
function set_hart_state(state : DebugHartState) -> unit = {
  // Set sticky bit when becoming unavailable
  if state == UNAVAILABLE then dmstatus[stickyunavail] = 0b1;

  let is_unavailable = bool_to_bits(state == UNAVAILABLE);
  let is_halted      = bool_to_bits(state == HALTED);
  let is_running     = bool_to_bits(state == RUNNING);

  dmstatus[allunavail]  = is_unavailable;
  dmstatus[anyunavail]  = is_unavailable;
  dmstatus[allhalted]   = is_halted;
  dmstatus[anyhalted]   = is_halted;
  dmstatus[allrunning]  = is_running;
  dmstatus[anyrunning]  = is_running;
}

function set_havereset(havereset : bool) -> unit = {
  dmstatus[allhavereset] = bool_to_bits(havereset);
  dmstatus[anyhavereset] = bool_to_bits(havereset);
}

function set_resumeack(resumeack : bool) -> unit = {
  dmstatus[allresumeack] = bool_to_bits(resumeack);
  dmstatus[anyresumeack] = bool_to_bits(resumeack);
}

function set_hart_exists(exists : bool) -> unit = {
  dmstatus[allnonexistent] = bool_to_bits(not(exists));
  dmstatus[anynonexistent] = bool_to_bits(not(exists));
}

function set_abstractcs_busy(is_busy : bool) -> unit = {
  abstractcs[busy] = bool_to_bits(is_busy);
}

function is_abstractcs_busy() -> bool = {
  bits_to_bool(abstractcs[busy])
}

val read_arg : forall 'n, 'n in {32, 64, 128}. (range(0, 2), int('n)) -> bits('n)
function read_arg(arg_num, argument_width) = {
  let value : bits('n) = match (arg_num, argument_width) {
    // arg0
    (0, 32)  => data_regs[0],
    (0, 64)  => data_regs[1] @ data_regs[0],
    (0, 128) => data_regs[3] @ data_regs[2] @ data_regs[1] @ data_regs[0],
    // arg1
    (1, 32)  => data_regs[1],
    (1, 64)  => data_regs[3] @ data_regs[2],
    (1, 128) => data_regs[7] @ data_regs[6] @ data_regs[5] @ data_regs[4],
    // arg2
    (2, 32)  => data_regs[2],
    (2, 64)  => data_regs[5] @ data_regs[4],
    (2, 128) => data_regs[11] @ data_regs[10] @ data_regs[9] @ data_regs[8],
  };
  value
}

val write_arg : forall 'n, 'n in {32, 64, 128}. (range(0, 2), int('n), bits('n)) -> unit
function write_arg(arg_num, argument_width, value) = {
  match (arg_num, argument_width) {
    // arg0
    (0, 32)  => data_regs[0] = value,
    (0, 64)  => {
      data_regs[0] = value[31..0];
      data_regs[1] = value[63..32];
    },
    (0, 128) => {
      data_regs[0] = value[31..0];
      data_regs[1] = value[63..32];
      data_regs[2] = value[95..64];
      data_regs[3] = value[127..96];
    },
    // arg1
    (1, 32)  => data_regs[1] = value,
    (1, 64)  => {
      data_regs[2] = value[31..0];
      data_regs[3] = value[63..32];
    },
    (1, 128) => {
      data_regs[4] = value[31..0];
      data_regs[5] = value[63..32];
      data_regs[6] = value[95..64];
      data_regs[7] = value[127..96];
    },
    // arg2
    (2, 32)  => data_regs[2] = value,
    (2, 64)  => {
      data_regs[4] = value[31..0];
      data_regs[5] = value[63..32];
    },
    (2, 128) => {
      data_regs[8]  = value[31..0];
      data_regs[9]  = value[63..32];
      data_regs[10] = value[95..64];
      data_regs[11] = value[127..96];
    },
  };
}

function is_supported_reg_access(aarsize : bits(3), regno : bits(16)) -> bool = {
  let aarsize = unsigned(aarsize);
  // We only support 32-bit and 64-bit access
  if not(aarsize == 2 | aarsize == 3) then false
  else {
    match regno {
      // Cover both CSRs and GPRs
      regno if regno <=_u REGNO_GPR_MAX => not(aarsize == 3 & dxlen == 32),
      // Cover FPRs
      regno if regno <=_u REGNO_FPR_MAX => not(aarsize == 3 & flen == 32),
      _ => false
    };
  }
}

function is_valid_aamsize(aamsize : bits(3)) -> bool = {
  let aamsize = unsigned(aamsize);
  if aamsize > 4 then false
  else match dxlen {
    32 => aamsize <= 2,
    64 => aamsize <= 3,
    _ => false,
  }
}

function aamsize_to_bytes(aamsize : bits(3)) -> word_width = {
  let aamsize = unsigned(aamsize);
  assert(aamsize < 4, "aamsize value exceeds maximum");
  match aamsize {
    0 => 1,
    1 => 2,
    2 => 4,
    3 => 8,
  }
}

function legalize_hawindow(d : Hawindow, x : bits(32)) -> Hawindow = {
  // Currently, we only support one hart
  [d with maskdata = zeros()]
}

function legalize_authdata(d : Authdata, x : bits(32)) -> Authdata = {
  Mk_Authdata(x)
}

function legalize_dmcs2(d : Dmcs2, x : bits(32)) -> Dmcs2 = {
  let x = Mk_Dmcs2(x);
  [d with
    grouptype    = x[grouptype],
    dmexttrigger = x[dmexttrigger],
    group        = x[group],
    hgwrite      = 0b0,
    hgselect     = 0b0
  ]
}

function legalize_sbcs(d : Sbcs, x : bits(32)) -> Sbcs = {
  let x = Mk_Sbcs(x);
  [d with
    sbbusyerror     = if x[sbbusyerror] == ones() then zeros() else d[sbbusyerror], // R/W1C
    sbreadonaddr    = x[sbreadonaddr],
    sbaccess        = x[sbaccess],
    sbautoincrement = x[sbautoincrement],
    sberror         = if x[sberror] == ones() then zeros() else d[sberror], // R/W1C
    // TODO: No system bus access support yet
    sbasize     = zeros(),
    sbaccess128 = 0b0,
    sbaccess64  = 0b0,
    sbaccess32  = 0b0,
    sbaccess16  = 0b0,
    sbaccess8   = 0b0
  ]
}

function legalize_sbaddress0(d : Sbaddress0, x : bits(32)) -> Sbaddress0 = {
  Mk_Sbaddress0(x)
}

function legalize_sbaddress1(d : Sbaddress1, x : bits(32)) -> Sbaddress1 = {
  Mk_Sbaddress1(x)
}

function legalize_sbaddress2(d : Sbaddress2, x : bits(32)) -> Sbaddress2 = {
  Mk_Sbaddress2(x)
}

function legalize_sbaddress3(d : Sbaddress3, x : bits(32)) -> Sbaddress3 = {
  Mk_Sbaddress3(x)
}

function legalize_sbdata0(d : Sbdata0, x : bits(32)) -> Sbdata0 = {
  Mk_Sbdata0(x)
}

function legalize_sbdata1(d : Sbdata1, x : bits(32)) -> Sbdata1 = {
  Mk_Sbdata1(x)
}

function legalize_sbdata2(d : Sbdata2, x : bits(32)) -> Sbdata2 = {
  Mk_Sbdata2(x)
}

function legalize_sbdata3(d : Sbdata3, x : bits(32)) -> Sbdata3 = {
  Mk_Sbdata3(x)
}
