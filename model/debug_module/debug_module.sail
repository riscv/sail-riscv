//=======================================================================================
//  This Sail RISC-V architecture model, comprising all files and
//  directories except where otherwise noted is subject the BSD
//  two-clause license in the LICENSE file.
//
//  SPDX-License-Identifier: BSD-2-Clause
//=======================================================================================

// Interface to the hart
function send_debug_request(request : DebugRequest) -> unit = {
  pending_debug_request = Some(request);
}

/// Set cmderr if no error already recorded (cmderr is sticky)
function set_cmderr_if_none(err : AbstractCommandError) -> unit = {
  if abstractcs[cmderr] == abstract_command_error(CMDERR_NONE) then
    abstractcs[cmderr] = abstract_command_error(err);
}

// Sets CMDERR_BUSY immediately, for data/progbuf
function check_abstract_busy_and_set_error() -> bool = {
  let busy = is_abstractcs_busy();
  if busy then set_cmderr_if_none(CMDERR_BUSY);
  busy
}

// Defers error until command completes for abstractauto/commands/abstractcs
function check_abstract_busy_and_set_pending_error() -> bool = {
  let busy = is_abstractcs_busy();
  if busy then pending_cmderr_busy = true;
  busy
}

function handle_access_register_cmd(cmd : bits(32)) -> AbstractCommandError = {
  let aarsize          = cmd[22 .. 20];
  let reserved         = cmd[23];
  let aarpostincrement = cmd[19];
  let postexec         = cmd[18];
  let transfer         = cmd[17];
  let write            = cmd[16];
  let regno            = cmd[15 .. 0];

  if reserved == bitone then CMDERR_NOT_SUPPORTED
  else if aarpostincrement == bitone then CMDERR_NOT_SUPPORTED  // TODO: Add support
  else if transfer == bitone & not(is_supported_reg_access(aarsize, regno)) then CMDERR_NOT_SUPPORTED
  else if postexec == bitone & not(config platform.debug_module.program_buffer.supported : bool) then CMDERR_NOT_SUPPORTED
  else match get_hart_state() {
    HALTED => {
      send_debug_request(AbstractCommand(AccessRegister(bit_to_bool(write), regno, aarsize, bit_to_bool(postexec), bit_to_bool(transfer))));
      CMDERR_NONE
    },
    _ => CMDERR_HALT_RESUME,
  }
}

function handle_quick_access_cmd(cmd : bits(32)) -> AbstractCommandError = {
  if cmd[23 .. 0] != zeros() then CMDERR_NOT_SUPPORTED
  else match get_hart_state() {
    RUNNING => {
      send_debug_request(AbstractCommand(QuickAccess()));
      CMDERR_NONE
    },
    _ => CMDERR_HALT_RESUME,
  }
}

function handle_access_memory_cmd(cmd : bits(32)) -> AbstractCommandError = {
  let aamvirtual       = cmd[23];
  let aamsize          = cmd[22 .. 20];
  let aampostincrement = cmd[19];
  let write            = cmd[16];

  if cmd[18 .. 17] != zeros() then CMDERR_NOT_SUPPORTED
  else if cmd[13 .. 0] != zeros() then CMDERR_NOT_SUPPORTED
  else if aampostincrement == bitone then CMDERR_NOT_SUPPORTED  // TODO: Add support
  else if not(is_valid_aamsize(aamsize)) then CMDERR_NOT_SUPPORTED
  else match get_hart_state() {
    HALTED => {
      let aamsize_bytes = aamsize_to_bytes(aamsize);
      let addr = read_arg(ARG1, dxlen);
      send_debug_request(AbstractCommand(MemoryAccess(bit_to_bool(aamvirtual), bit_to_bool(write), aamsize_bytes, addr)));
      CMDERR_NONE
    },
    _ => CMDERR_HALT_RESUME,
  }
}

// Main command handler - dispatches to specific command handlers
function handle_abstract_command(cmd : bits(32)) -> AbstractCommandError = {
  let cmdtype = unsigned(cmd[31 .. 24]);

  set_abstractcs_busy(true);

  let status : AbstractCommandError =
    if cmdtype > 2 then CMDERR_NOT_SUPPORTED
    else match abstract_command_type(cmdtype) {
      ACCESS_REGISTER => handle_access_register_cmd(cmd),
      QUICK_ACCESS    => handle_quick_access_cmd(cmd),
      ACCESS_MEMORY   => handle_access_memory_cmd(cmd),
    };

  // Clear busy flag if command failed validation
  if status != CMDERR_NONE then set_abstractcs_busy(false);

  status
}

function legalize_abstractcs(d : Abstractcs, x : bits(32)) -> Abstractcs = {
  let x = Mk_Abstractcs(x);
  if check_abstract_busy_and_set_pending_error() then d
  else [d with
    cmderr = if x[cmderr] == ones() then zeros() else d[cmderr], // R/W1C
  ]
}

// NOTE: The command register is WARZ, so the stored value doesn't matter
// for register reads. However, we preserve the command value internally when busy
// to ensure abstractauto re-executes the correct command.
function legalize_command(d : Command, x : bits(32)) -> Command = {
  // If busy, set pending error flag and preserve command value
  if check_abstract_busy_and_set_pending_error() then d
  else {
    let status : AbstractCommandError = match get_hart_state() {
      UNAVAILABLE => CMDERR_HALT_RESUME,
      _           => handle_abstract_command(x),
    };
    set_cmderr_if_none(status);
    Mk_Command(x)
  }
}

// Handle register access during abstract commands (busy check)
function handle_debug_module_register_access(old_value: bits(32), new_value : bits(32), is_write: bool) -> bits(32) = {
  let is_busy = check_abstract_busy_and_set_error();
  if is_busy | not(is_write) then old_value else new_value
}

// Trigger abstract command auto-execution if enabled
function trigger_abstractauto_if_enabled(autoexec_enabled: bit) -> unit = {
  if bit_to_bool(autoexec_enabled) then {
    let _ = legalize_command(command, command.bits);
  };
}

// NOTE: This register is optional but OpenOCD assumes it exists
// see https://github.com/riscv-collab/riscv-openocd/issues/587
function legalize_abstractauto(d : Abstractauto, x : bits(32)) -> Abstractauto = {
  let x = Mk_Abstractauto(x);
  if check_abstract_busy_and_set_pending_error() then d
  else {
    let DATA_AUTOEXEC_MASK    : bits(12) = to_bits_truncate(12, (2 ^ unsigned(MAX_DATA_SIZE)) - 1);
    let PROGBUF_AUTOEXEC_MASK : bits(16) = to_bits_truncate(16, (2 ^ unsigned(MAX_PROGBUF_SIZE)) - 1);
    [d with
      autoexecprogbuf = x[autoexecprogbuf] & PROGBUF_AUTOEXEC_MASK,
      autoexecdata    = x[autoexecdata] & DATA_AUTOEXEC_MASK,
    ]
  }
}

function update_halt_on_reset_config(x : Dmcontrol) -> unit = {
  match (x[setresethaltreq], x[clrresethaltreq]) {
    (0b1, 0b0) => haltonreset = true,
    (_,   0b1) => haltonreset = false,
    (_, _)     => ()
  }
}

// Mask control fields that must be ignored while abstract command is executing
function mask_dmcontrol_when_busy(x : Dmcontrol) -> Dmcontrol = {
  [x with
    haltreq         = 0b0,
    resumereq       = 0b0,
    ackhavereset    = 0b0,
    hartsello       = zeros(),
    hartselhi       = zeros(),
    setresethaltreq = 0b0,
    clrresethaltreq = 0b0,
  ]
}

// Process acknowledgment bits for existing harts
function process_acks(x : Dmcontrol) -> unit = {
  update_halt_on_reset_config(x);
  if x[ackhavereset] == 0b1 then set_havereset(false);
  if x[ackunavail]   == 0b1 then dmstatus[stickyunavail] = 0b0;
}

// Handle halt and resume requests during normal operation
function handle_halt_resume_requests(x : Dmcontrol) -> unit = {
  let state = get_hart_state();

  if x[haltreq] == 0b1 & state != HALTED then
    send_debug_request(Halt());

  if x[resumereq] == 0b1 & state != RUNNING then {
    set_resumeack(false);
    send_debug_request(Resume());
  };
}

// Handle reset signal transitions, returns true if a transition occurred
function handle_reset_transitions(d : Dmcontrol, x : Dmcontrol, hart_exists : bool) -> bool = {
  match (d[ndmreset], x[ndmreset], d[hartreset], x[hartreset]) {
    // NDM reset deassert - applies even if hart doesn't exist
    (0b1, 0b0, _, _) => {
      send_debug_request(Reset(x[haltreq] == 0b1 | haltonreset));
      true
    },
    // NDM reset assert
    (0b0, 0b1, _, _) => {
      set_hart_state(UNAVAILABLE);
      true
    },
    // Hart reset deassert
    (_, _, 0b1, 0b0) if hart_exists => {
      send_debug_request(Reset(x[haltreq] == 0b1 | haltonreset));
      true
    },
    // Hart reset assert
    (_, _, 0b0, 0b1) if hart_exists => {
      set_hart_state(UNAVAILABLE);
      true
    },
    _ => false
  }
}

// Build the return value with legalized fields
function build_dmcontrol_result(d : Dmcontrol, x : Dmcontrol, busy : bool) -> Dmcontrol = {
  [d with
    haltreq   = if busy then d[haltreq] else x[haltreq],
    hartreset = x[hartreset],
    hasel     = 0b0,      // Minimal implementation: single hart only
    hartsello = zeros(),
    hartselhi = zeros(),
    ndmreset  = x[ndmreset],
    dmactive  = x[dmactive]
  ]
}

function legalize_active_dmcontrol(d : Dmcontrol, x : Dmcontrol) -> Dmcontrol = {
  let busy = is_abstractcs_busy();
  let x = if busy then mask_dmcontrol_when_busy(x) else x;

  // Validate hart selection (only hart 0 exists in minimal implementation)
  let hartsel = x[hartselhi] @ x[hartsello];
  let hart_exists = hartsel == zeros();
  set_hart_exists(hart_exists);

  // Process acknowledgments for existing harts
  if hart_exists then process_acks(x);

  // Handle reset transitions first (they take priority)
  let reset_occurred = handle_reset_transitions(d, x, hart_exists);

  // Handle normal halt/resume only if no reset transition and hart exists
  if not(reset_occurred) & hart_exists then
    handle_halt_resume_requests(x);

  build_dmcontrol_result(d, x, busy)
}

function legalize_dmcontrol(d : Dmcontrol, x : bits(32)) -> Dmcontrol = {
  let x = Mk_Dmcontrol(x);
  match (d[dmactive], x[dmactive]) {
    // Debug Module inactive, can only write dmactive
    (0b0, _) => [d with dmactive = x[dmactive]],
    // Reset Debug Module
    (0b1, 0b0) => {
      reset_debug_module();
      Mk_Dmcontrol(zeros())
    },
    // Debug Module active
    (0b1, 0b1) => legalize_active_dmcontrol(d, x),
  }
}

// Hart Status Callback

// Called by hart to signal the completion of an abstract command
function complete_abstract_command(status : AbstractCommandError) -> unit = {
  set_cmderr_if_none(status);
  set_abstractcs_busy(false);

  // NOTE: if abstractauto/commands/abstractcs was written while busy,
  // cmderr becomes CMDERR_BUSY once the command completes (if no other error)
  if pending_cmderr_busy then set_cmderr_if_none(CMDERR_BUSY);
  pending_cmderr_busy = false;
}

// Called by hart to report its current state to the Debug Module
function send_hart_status(status : debug_module_hart_status) -> unit = {
  assert((status.halted & not(status.running)) | (not(status.halted) & status.running),
         "Hart must be either halted or running, not both");

  let prev_state = get_hart_state();

  if status.running then set_hart_state(RUNNING)
  else if status.halted then set_hart_state(HALTED);

  // Sticky bit: only set, never clear
  if status.havereset then
    set_havereset(true);

  // Signal successful resume transition
  if prev_state != RUNNING & status.running then
    set_resumeack(true);
}

mapping clause debug_module_reg_name_map = 0x04 <-> "data0"
mapping clause debug_module_reg_name_map = 0x05 <-> "data1"
mapping clause debug_module_reg_name_map = 0x06 <-> "data2"
mapping clause debug_module_reg_name_map = 0x07 <-> "data3"
mapping clause debug_module_reg_name_map = 0x08 <-> "data4"
mapping clause debug_module_reg_name_map = 0x09 <-> "data5"
mapping clause debug_module_reg_name_map = 0x0a <-> "data6"
mapping clause debug_module_reg_name_map = 0x0b <-> "data7"
mapping clause debug_module_reg_name_map = 0x0c <-> "data8"
mapping clause debug_module_reg_name_map = 0x0d <-> "data9"
mapping clause debug_module_reg_name_map = 0x0e <-> "data10"
mapping clause debug_module_reg_name_map = 0x0f <-> "data11"

mapping clause debug_module_reg_name_map = 0x10 <-> "dmcontrol"
mapping clause debug_module_reg_name_map = 0x11 <-> "dmstatus"
mapping clause debug_module_reg_name_map = 0x12 <-> "hartinfo"
mapping clause debug_module_reg_name_map = 0x13 <-> "haltsum1"
mapping clause debug_module_reg_name_map = 0x14 <-> "hawindowsel"
mapping clause debug_module_reg_name_map = 0x15 <-> "hawindow"
mapping clause debug_module_reg_name_map = 0x16 <-> "abstractcs"
mapping clause debug_module_reg_name_map = 0x17 <-> "command"
mapping clause debug_module_reg_name_map = 0x18 <-> "abstractauto"
mapping clause debug_module_reg_name_map = 0x19 <-> "confstrptr0"
mapping clause debug_module_reg_name_map = 0x1a <-> "confstrptr1"
mapping clause debug_module_reg_name_map = 0x1b <-> "confstrptr2"
mapping clause debug_module_reg_name_map = 0x1c <-> "confstrptr3"
mapping clause debug_module_reg_name_map = 0x1d <-> "nextdm"

mapping clause debug_module_reg_name_map = 0x20 <-> "progbuf0"
mapping clause debug_module_reg_name_map = 0x21 <-> "progbuf1"
mapping clause debug_module_reg_name_map = 0x22 <-> "progbuf2"
mapping clause debug_module_reg_name_map = 0x23 <-> "progbuf3"
mapping clause debug_module_reg_name_map = 0x24 <-> "progbuf4"
mapping clause debug_module_reg_name_map = 0x25 <-> "progbuf5"
mapping clause debug_module_reg_name_map = 0x26 <-> "progbuf6"
mapping clause debug_module_reg_name_map = 0x27 <-> "progbuf7"
mapping clause debug_module_reg_name_map = 0x28 <-> "progbuf8"
mapping clause debug_module_reg_name_map = 0x29 <-> "progbuf9"
mapping clause debug_module_reg_name_map = 0x2a <-> "progbuf10"
mapping clause debug_module_reg_name_map = 0x2b <-> "progbuf11"
mapping clause debug_module_reg_name_map = 0x2c <-> "progbuf12"
mapping clause debug_module_reg_name_map = 0x2d <-> "progbuf13"
mapping clause debug_module_reg_name_map = 0x2e <-> "progbuf14"
mapping clause debug_module_reg_name_map = 0x2f <-> "progbuf15"

mapping clause debug_module_reg_name_map = 0x30 <-> "authdata"
mapping clause debug_module_reg_name_map = 0x32 <-> "dmcs2"
mapping clause debug_module_reg_name_map = 0x34 <-> "haltsum2"
mapping clause debug_module_reg_name_map = 0x35 <-> "haltsum3"
mapping clause debug_module_reg_name_map = 0x37 <-> "sbaddress3"
mapping clause debug_module_reg_name_map = 0x38 <-> "sbcs"
mapping clause debug_module_reg_name_map = 0x39 <-> "sbaddress0"
mapping clause debug_module_reg_name_map = 0x3a <-> "sbaddress1"
mapping clause debug_module_reg_name_map = 0x3b <-> "sbaddress2"
mapping clause debug_module_reg_name_map = 0x3c <-> "sbdata0"
mapping clause debug_module_reg_name_map = 0x3d <-> "sbdata1"
mapping clause debug_module_reg_name_map = 0x3e <-> "sbdata2"
mapping clause debug_module_reg_name_map = 0x3f <-> "sbdata3"
mapping clause debug_module_reg_name_map = 0x40 <-> "haltsum0"

// Data registers
function clause is_debug_module_reg_defined((addr) if DATA_REG_BASE <=_u addr & addr <=_u DATA_REG_END) = {
  unsigned(abstractcs[datacount]) > unsigned(addr - DATA_REG_BASE)
}

// Control/Status registers
function clause is_debug_module_reg_defined(0x10) = true  // dmcontrol
function clause is_debug_module_reg_defined(0x11) = true  // dmstatus
function clause is_debug_module_reg_defined(0x12) = true  // hartinfo
function clause is_debug_module_reg_defined(0x13) = false // haltsum1 (not implemented)
function clause is_debug_module_reg_defined(0x14) = false // hawindowsel (not implemented)
function clause is_debug_module_reg_defined(0x15) = true  // hawindow
function clause is_debug_module_reg_defined(0x16) = true  // abstractcs
function clause is_debug_module_reg_defined(0x17) = true  // command
function clause is_debug_module_reg_defined(0x18) = true  // abstractauto
function clause is_debug_module_reg_defined(0x19) = true  // confstrptr0
function clause is_debug_module_reg_defined(0x1a) = true  // confstrptr1
function clause is_debug_module_reg_defined(0x1b) = true  // confstrptr2
function clause is_debug_module_reg_defined(0x1c) = true  // confstrptr3
function clause is_debug_module_reg_defined(0x1d) = true  // nextdm

// Program buffer
function clause is_debug_module_reg_defined((addr) if 0x20 <=_u addr & addr <=_u 0x2f) = {
  unsigned(abstractcs[progbufsize]) > unsigned(addr - 0x20)
}

// Authentication and misc
function clause is_debug_module_reg_defined(0x30) = true  // authdata
function clause is_debug_module_reg_defined(0x32) = true  // dmcs2
function clause is_debug_module_reg_defined(0x34) = false // haltsum2 (not implemented)
function clause is_debug_module_reg_defined(0x35) = false // haltsum3 (not implemented)

// System bus access
function clause is_debug_module_reg_defined(0x37) = unsigned(sbcs[sbasize]) >= 97   // sbaddress3
function clause is_debug_module_reg_defined(0x38) = true                            // sbcs
function clause is_debug_module_reg_defined(0x39) = sbcs[sbasize] != zeros()        // sbaddress0
function clause is_debug_module_reg_defined(0x3a) = unsigned(sbcs[sbasize]) >= 33   // sbaddress1
function clause is_debug_module_reg_defined(0x3b) = unsigned(sbcs[sbasize]) >= 65   // sbaddress2
function clause is_debug_module_reg_defined(0x3c) = sbcs[sbaccess] != zeros()       // sbdata0
function clause is_debug_module_reg_defined(0x3d) = sbcs[sbaccess64] == 0b1 | sbcs[sbaccess128] == 0b1  // sbdata1
function clause is_debug_module_reg_defined(0x3e) = sbcs[sbaccess128] == 0b1        // sbdata2
function clause is_debug_module_reg_defined(0x3f) = sbcs[sbaccess128] == 0b1        // sbdata3

function clause is_debug_module_reg_defined(0x40) = true  // haltsum0

// Data registers
function clause write_debug_module_reg((addr, value) if DATA_REG_BASE <=_u addr & addr <=_u DATA_REG_END) = {
  let idx = unsigned(addr - DATA_REG_BASE);
  assert(idx <= 11);
  data_regs[idx] = handle_debug_module_register_access(data_regs[idx], value, true);
  trigger_abstractauto_if_enabled(abstractauto[autoexecdata][idx]);
}

// Control/Status registers
function clause write_debug_module_reg(0x10, value) = { dmcontrol = legalize_dmcontrol(dmcontrol, value); }
function clause write_debug_module_reg(0x11, value) = ()  // dmstatus is read-only
function clause write_debug_module_reg(0x12, value) = ()  // hartinfo is read-only
function clause write_debug_module_reg(0x13, value) = ()  // haltsum1
function clause write_debug_module_reg(0x14, value) = ()  // hawindowsel
function clause write_debug_module_reg(0x15, value) = { hawindow = legalize_hawindow(hawindow, value); }
function clause write_debug_module_reg(0x16, value) = { abstractcs = legalize_abstractcs(abstractcs, value); }
function clause write_debug_module_reg(0x17, value) = { command = legalize_command(command, value); }
function clause write_debug_module_reg(0x18, value) = { abstractauto = legalize_abstractauto(abstractauto, value); }
function clause write_debug_module_reg(0x19, value) = ()  // confstrptr0 is read-only
function clause write_debug_module_reg(0x1a, value) = ()  // confstrptr1 is read-only
function clause write_debug_module_reg(0x1b, value) = ()  // confstrptr2 is read-only
function clause write_debug_module_reg(0x1c, value) = ()  // confstrptr3 is read-only
function clause write_debug_module_reg(0x1d, value) = ()  // nextdm is read-only

// Program buffer
function clause write_debug_module_reg((addr, value) if 0x20 <=_u addr & addr <=_u 0x2f) = {
  let idx = unsigned(addr - 0x20);
  assert(idx <= 15);
  progbuf_regs[idx] = handle_debug_module_register_access(progbuf_regs[idx], value, true);
  trigger_abstractauto_if_enabled(abstractauto[autoexecprogbuf][idx]);
}

// Authentication and misc
function clause write_debug_module_reg(0x30, value) = { authdata = legalize_authdata(authdata, value); }
function clause write_debug_module_reg(0x32, value) = { dmcs2 = legalize_dmcs2(dmcs2, value); }
function clause write_debug_module_reg(0x34, value) = ()  // haltsum2
function clause write_debug_module_reg(0x35, value) = ()  // haltsum3

// System bus access
function clause write_debug_module_reg(0x37, value) = { sbaddress3 = legalize_sbaddress3(sbaddress3, value); }
function clause write_debug_module_reg(0x38, value) = { sbcs = legalize_sbcs(sbcs, value); }
function clause write_debug_module_reg(0x39, value) = { sbaddress0 = legalize_sbaddress0(sbaddress0, value); }
function clause write_debug_module_reg(0x3a, value) = { sbaddress1 = legalize_sbaddress1(sbaddress1, value); }
function clause write_debug_module_reg(0x3b, value) = { sbaddress2 = legalize_sbaddress2(sbaddress2, value); }
function clause write_debug_module_reg(0x3c, value) = { sbdata0 = legalize_sbdata0(sbdata0, value); }
function clause write_debug_module_reg(0x3d, value) = { sbdata1 = legalize_sbdata1(sbdata1, value); }
function clause write_debug_module_reg(0x3e, value) = { sbdata2 = legalize_sbdata2(sbdata2, value); }
function clause write_debug_module_reg(0x3f, value) = { sbdata3 = legalize_sbdata3(sbdata3, value); }

function clause write_debug_module_reg(0x40, value) = ()  // haltsum0 is read-only

// Data registers
function clause read_debug_module_reg((addr) if DATA_REG_BASE <=_u addr & addr <=_u DATA_REG_END) = {
  let idx = unsigned(addr - DATA_REG_BASE);
  assert(idx <= 11);
  let _ = handle_debug_module_register_access(data_regs[idx], zeros(), false);
  trigger_abstractauto_if_enabled(abstractauto[autoexecdata][idx]);
  data_regs[idx]
}

// Control/Status registers
function clause read_debug_module_reg(0x10) = dmcontrol.bits
function clause read_debug_module_reg(0x11) = dmstatus.bits
function clause read_debug_module_reg(0x12) = hartinfo.bits
function clause read_debug_module_reg(0x13) = haltsum1.bits
function clause read_debug_module_reg(0x14) = hawindowsel.bits
function clause read_debug_module_reg(0x15) = hawindow.bits
function clause read_debug_module_reg(0x16) = abstractcs.bits
function clause read_debug_module_reg(0x17) = zeros()  // command is write-only (WARZ)
function clause read_debug_module_reg(0x18) = abstractauto.bits
function clause read_debug_module_reg(0x19) = confstrptr0.bits
function clause read_debug_module_reg(0x1a) = confstrptr1.bits
function clause read_debug_module_reg(0x1b) = confstrptr2.bits
function clause read_debug_module_reg(0x1c) = confstrptr3.bits
function clause read_debug_module_reg(0x1d) = nextdm.bits

// Program buffer
function clause read_debug_module_reg((addr) if 0x20 <=_u addr & addr <=_u 0x2f) = {
  let idx = unsigned(addr - 0x20);
  assert(idx <= 15);
  let _ = handle_debug_module_register_access(progbuf_regs[idx], zeros(), false);
  trigger_abstractauto_if_enabled(abstractauto[autoexecprogbuf][idx]);
  progbuf_regs[idx]
}

// Authentication and misc
function clause read_debug_module_reg(0x30) = authdata.bits
function clause read_debug_module_reg(0x32) = dmcs2.bits
function clause read_debug_module_reg(0x34) = haltsum2.bits
function clause read_debug_module_reg(0x35) = haltsum3.bits

// System bus access
function clause read_debug_module_reg(0x37) = sbaddress3.bits
function clause read_debug_module_reg(0x38) = sbcs.bits
function clause read_debug_module_reg(0x39) = sbaddress0.bits
function clause read_debug_module_reg(0x3a) = sbaddress1.bits
function clause read_debug_module_reg(0x3b) = sbaddress2.bits
function clause read_debug_module_reg(0x3c) = sbdata0.bits
function clause read_debug_module_reg(0x3d) = sbdata1.bits
function clause read_debug_module_reg(0x3e) = sbdata2.bits
function clause read_debug_module_reg(0x3f) = sbdata3.bits

// haltsum0: single hart implementation returns bit 0 = allhalted
function clause read_debug_module_reg(0x40) = zeros(31) @ dmstatus[allhalted]

// Terminate Scattered Definitions
mapping clause debug_module_reg_name_map = reg <-> hex_bits_8(reg)
end debug_module_reg_name_map

function clause is_debug_module_reg_defined(_) = false
end is_debug_module_reg_defined

function clause read_debug_module_reg(addr) = {
  internal_error(__FILE__, __LINE__, "Read from undefined Debug Module Register: " ^ bits_str(addr));
}
end read_debug_module_reg

function clause write_debug_module_reg(addr, _) = {
  internal_error(__FILE__, __LINE__, "Write to undefined Debug Module Register: " ^ bits_str(addr));
}
end write_debug_module_reg

// Reset all Debug Module state to initial values.
function reset_debug_module() = {
  // Per spec: behavior is undefined if hart is halted during DM reset.
  // We choose to resume the hart since dmstatus resets to running state.
  if get_hart_state() == HALTED then
    send_debug_request(Resume());

  // Program buffer: fill with EBREAK for safe exit from debug mode
  progbuf_regs = vector_init(EBREAK_INSTRUCTION);

  haltonreset = false;

  // dmstatus: initialize to default state
  dmstatus = initialize_dmstatus();

  dmcontrol.bits = zeros();
  hawindowsel.bits = zeros();

  abstractcs = initialize_abstractcs();

  command.bits = zeros();

  abstractauto = [Mk_Abstractauto(zeros()) with
    autoexecprogbuf = zeros(),
    autoexecdata    = zeros(),
  ];

  dmcs2 = [Mk_Dmcs2(zeros()) with
    grouptype    = zeros(),
    dmexttrigger = zeros(),
    group        = zeros(),
    hgselect     = zeros(),
  ];

  sbcs = initialize_Sbcs();

  sbaddress0.bits = zeros();
  sbaddress1.bits = zeros();
  sbaddress2.bits = zeros();
  sbaddress3.bits = zeros();

  sbdata0.bits = zeros();
  sbdata1.bits = zeros();
  sbdata2.bits = zeros();
  sbdata3.bits = zeros();
}
