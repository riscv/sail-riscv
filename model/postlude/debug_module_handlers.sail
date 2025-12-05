// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Debug Module Interface

function update_debug_module_status(request : DebugRequest) -> unit = {
  match request {
    Halt()               => send_hart_status(struct { halted = true,  running = false, havereset = false }),
    Resume()             => send_hart_status(struct { halted = false, running = true,  havereset = false }),
    Reset(halt_on_reset) => send_hart_status(struct { halted = halt_on_reset, running = not(halt_on_reset), havereset = true }),
    _                    => (),
  }
}

// Basic Debug Operations

function handle_debug_resume() -> unit = {
  exit_debug_mode();
  update_debug_module_status(Resume());
}

function handle_debug_halt(cause : debug_entry_cause) -> unit = {
  enter_debug_mode(cause, zeros(), get_arch_pc());
  update_debug_module_status(Halt());
}

function handle_debug_reset(halt_on_reset : bool) -> unit = {
  reset();
  if halt_on_reset then enter_debug_mode(DBGEntry_ResetHaltReq, zeros(), get_arch_pc());
  update_debug_module_status(Reset(halt_on_reset));
}

function handle_debug_single_step() -> unit = {
  if in_single_step() & not(in_debug_mode()) then handle_debug_halt(DBGEntry_Step)
}

function execute_program_buffer() -> unit = {
  // TODO: Uncomment once Debug Module is available
  // assert(in_debug_abstract_command(), "Need to be in debug mode in order to execute program buffer");
  // PC = trunc(plat_program_buffer_base);
  // nextPC = PC;
  ()
}

// Abstract Command Handlers

function debug_access_csr(write : bool, regno : bits(12)) -> AbstractCommandError = {
  let access_type = if write then CSRWrite else CSRRead;
  if is_CSR_accessible(regno, Machine, access_type) & check_CSR_access(regno, access_type) then {
    if write then {
      match write_CSR(regno, read_arg(ARG0, dxlen)[dxlen - 1 .. 0]) {
        Ok(_)  => CMDERR_NONE,
        Err(_) => CMDERR_EXCEPTION,
      }
    } else {
      write_arg(ARG0, dxlen, read_CSR(regno));
      CMDERR_NONE
    }
  } else CMDERR_EXCEPTION
}

function debug_access_gpr(write : bool, regno : bits(5), width : range(2, 3)) -> AbstractCommandError = {
  if base_E_enabled & unsigned(regno) > 15 then return CMDERR_EXCEPTION;

  let regidx = encdec_reg(regno);
  if write then {
    let effective_width = if width == 2 & dxlen == 64 then 32 else dxlen;
    X(regidx) = zero_extend(read_arg(ARG0, effective_width))
  } else {
    write_arg(ARG0, dxlen, X(regidx))
  };
  CMDERR_NONE
}

function debug_access_fpr(write : bool, regno : bits(5), width : range(2, 3)) -> AbstractCommandError = {
  if mstatus[FS] == 0b00 then return CMDERR_EXCEPTION;

  let fregidx = encdec_freg(regno);
  if write then {
    let effective_width = if width == 2 & flen == 64 then 32 else flen;
    F(fregidx) = zero_extend(read_arg(ARG0, effective_width))
  } else {
    write_arg(ARG0, flen, F(fregidx))
  };
  CMDERR_NONE
}

function handle_abstract_register_access(acmd : AbstractCommand, write : bool, regno : bits(16), aarsize : bits(3), postexec : bool, transfer : bool) -> unit = {
  start_debug_abstract_command(acmd);

  let status : AbstractCommandError =
    if transfer then {
      let width = unsigned(aarsize);
      assert(width == 2 | width == 3);
      match regno {
        regno if regno <=_u REGNO_CSR_MAX                             => debug_access_csr(write, regno[11 .. 0]),
        regno if REGNO_GPR_BASE <=_u regno & regno <=_u REGNO_GPR_MAX => debug_access_gpr(write, regno[4 .. 0], width),
        regno if REGNO_FPR_BASE <=_u regno & regno <=_u REGNO_FPR_MAX => debug_access_fpr(write, regno[4 .. 0], width),
        _                                                             => CMDERR_EXCEPTION,
      }
    } else CMDERR_NONE;

  if postexec & status == CMDERR_NONE
  then execute_program_buffer()
  else end_debug_abstract_command(status);
}

function handle_abstract_quick_access(acmd : AbstractCommand) -> unit = {
  handle_debug_halt(DBGEntry_HaltReq);
  start_debug_abstract_command(acmd);
  execute_program_buffer();
}

function handle_abstract_memory_access(acmd : AbstractCommand, virtual : bool, write : bool, width : word_width, addr : xlenbits) -> unit = {
  start_debug_abstract_command(acmd);
  assert(width <= dxlen_bytes);

  let vaddr : virtaddr = Virtaddr(addr[dxlen - 1 .. 0]);
  let status : AbstractCommandError =
    if write then {
      let data = read_arg(ARG0, dxlen)[width * 8 - 1 .. 0];
      match vmem_write_addr(vaddr, width, data, Store(Data), false, false, false) {
        Ok(_)  => CMDERR_NONE,
        Err(_) => CMDERR_EXCEPTION,
      }
    } else {
      match vmem_read_addr(vaddr, zeros(), width, Load(Data), false, false, false) {
        Ok(data) => { write_arg(ARG0, dxlen, zero_extend(data)); CMDERR_NONE },
        Err(_)   => CMDERR_EXCEPTION,
      }
    };

  end_debug_abstract_command(status);
}

// Debug Request Dispatcher
function process_external_debug_request() -> option(DebugRequest) = {
  match pending_debug_request {
    Some(request) if hartSupports(Ext_Sdext) => {
      match request {
        Halt()                => handle_debug_halt(DBGEntry_HaltReq),
        Resume()              => handle_debug_resume(),
        Reset(halt_on_reset)  => handle_debug_reset(halt_on_reset),
        AbstractCommand(acmd) => match acmd {
          AccessRegister(write, regno, width, postexec, transfer) => handle_abstract_register_access(acmd, write, regno, width, postexec, transfer),
          QuickAccess()                                           => handle_abstract_quick_access(acmd),
          MemoryAccess(virtual, write, size, addr)                => handle_abstract_memory_access(acmd, virtual, write, size, addr),
        },
      };
      pending_debug_request = None();
      Some(request)
    },
    _ => None(),
  }
}
