// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Platform-specific definitions, and basic MMIO devices.

// Current constraints on this implementation are:
// - it cannot access memory directly, but instead provides definitions for the physical memory model
// - it can access system register state, needed to manipulate interrupt bits
// - it relies on externs to get platform address information and doesn't hardcode them

// Location of HTIF (Host Target InterFace) tohost port. None if not enabled.
// This is used for console output and signalling the end of tests.
register htif_tohost_base : option(physaddrbits) = None()
let htif_tohost_size = 8
// This is called externally. bits(64) is used because it's easier to deal with from C.
function enable_htif(tohost_addr : bits(64)) -> unit = htif_tohost_base = Some(trunc(tohost_addr))

function within_clint forall 'n, 0 < 'n <= max_mem_access . (Physaddr(addr) : physaddr, width : int('n)) -> bool = {
  // To avoid overflow issues when physical memory extends to the end
  // of the addressable range, we need to perform address bound checks
  // on unsigned unbounded integers.
  let addr_int       = unsigned(addr);
  let clint_base_int = unsigned(plat_clint_base);
  let clint_size_int = unsigned(plat_clint_size);
    clint_base_int <= addr_int
  & (addr_int + sizeof('n)) <= (clint_base_int + clint_size_int)
}

function within_htif_writable forall 'n, 0 < 'n <= max_mem_access . (Physaddr(addr) : physaddr, width : int('n)) -> bool =
  match htif_tohost_base {
    None() => false,
    Some(base) => (addr <_u base + htif_tohost_size) & (addr + width >_u base)
  }

function within_htif_readable forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> bool =
  within_htif_writable(addr, width)

// Program Buffer start addr and size
register plat_program_buffer_base : physaddrbits = to_bits_checked(config platform.debug_module.program_buffer.base : int)
register plat_program_buffer_size : physaddrbits = to_bits_checked(config platform.debug_module.program_buffer.size : int)

// Program Buffer
function within_program_buffer forall 'n, 0 < 'n <= max_mem_access . (Physaddr(addr) : physaddr, width : int('n)) -> bool = {
  let addr_int = unsigned(addr);
  let program_buffer_base_int = unsigned(plat_program_buffer_base);
  let program_buffer_size_int = unsigned(plat_program_buffer_size);
  // NOTE/TODO: Handling implicit EBREAK is tricky. For example, if the ROM is placed
  // immediately after the Program Buffer, the implicit break instruction could
  // overlap into the ROM. Currently, I handle this by checking whether execution
  // is still within an abstract command (Program Buffer). This approach works,
  // but it requires more testing.
  (program_buffer_size_int <= addr_int & (addr_int + sizeof('n)) <= (program_buffer_base_int + program_buffer_size_int)) | (((config platform.debug_module.num_prog_reg : int == 1) | config platform.debug_module.impebreak : bool) & (program_buffer_base_int + program_buffer_size_int) == addr_int)
}

// CLINT (Core Local Interruptor), based on Spike.

// Each hart has a memory-mapped mtimecmp register. Typically these are
// exposed as an array in CLINT. The CLINT implementation here is currently
// hard-coded to use the mtimecmp for hart 0.
register mtimecmp : bits(64)

// Unlike mtimecmp, stimecmp is a real CSR; not memory mapped.
register stimecmp : bits(64)

// CLINT memory-mapped IO

// relative address map:
//
// 0000 msip hart 0         -- memory-mapped software interrupt
// 0004 msip hart 1
// 4000 mtimecmp hart 0 lo  -- memory-mapped timer thresholds
// 4004 mtimecmp hart 0 hi
// 4008 mtimecmp hart 1 lo
// 400c mtimecmp hart 1 hi
// bff8 mtime lo            -- memory-mapped clocktimer value
// bffc mtime hi

let MSIP_BASE        : physaddrbits = zero_extend(0x00000)
let MTIMECMP_BASE    : physaddrbits = zero_extend(0x04000)
let MTIMECMP_BASE_HI : physaddrbits = zero_extend(0x04004)
let MTIME_BASE       : physaddrbits = zero_extend(0x0bff8)
let MTIME_BASE_HI    : physaddrbits = zero_extend(0x0bffc)

val clint_load : forall 'n, 'n > 0. (MemoryAccessType(ext_access_type), physaddr, int('n)) -> MemoryOpResult(bits(8 * 'n))
function clint_load(t, Physaddr(addr), width) = {
  let addr = addr - plat_clint_base;
  // FIXME: For now, only allow exact aligned access.
  if addr == MSIP_BASE & ('n == 8 | 'n == 4)
  then {
    if   get_config_print_clint()
    then print_log("clint[" ^ bits_str(addr) ^ "] -> " ^ bits_str(mip[MSI]));
    Ok(zero_extend(sizeof(8 * 'n), mip[MSI]))
  }
  else if addr == MTIMECMP_BASE & ('n == 4)
  then {
    if   get_config_print_clint()
    then print_log("clint<4>[" ^ bits_str(addr) ^ "] -> " ^ bits_str(mtimecmp[31..0]));
    // FIXME: Redundant zero_extend currently required by Lem backend
    Ok(zero_extend(32, mtimecmp[31..0]))
  }
  else if addr == MTIMECMP_BASE & ('n == 8)
  then {
    if   get_config_print_clint()
    then print_log("clint<8>[" ^ bits_str(addr) ^ "] -> " ^ bits_str(mtimecmp));
    // FIXME: Redundant zero_extend currently required by Lem backend
    Ok(zero_extend(64, mtimecmp))
  }
  else if addr == MTIMECMP_BASE_HI & ('n == 4)
  then {
    if   get_config_print_clint()
    then print_log("clint-hi<4>[" ^ bits_str(addr) ^ "] -> " ^ bits_str(mtimecmp[63..32]));
    // FIXME: Redundant zero_extend currently required by Lem backend
    Ok(zero_extend(32, mtimecmp[63..32]))
  }
  else if addr == MTIME_BASE & ('n == 4)
  then {
    if   get_config_print_clint()
    then print_log("clint[" ^ bits_str(addr) ^ "] -> " ^ bits_str(mtime));
    Ok(zero_extend(32, mtime[31..0]))
  }
  else if addr == MTIME_BASE & ('n == 8)
  then {
    if   get_config_print_clint()
    then print_log("clint[" ^ bits_str(addr) ^ "] -> " ^ bits_str(mtime));
    Ok(zero_extend(64, mtime))
  }
  else if addr == MTIME_BASE_HI & ('n == 4)
  then {
    if   get_config_print_clint()
    then print_log("clint[" ^ bits_str(addr) ^ "] -> " ^ bits_str(mtime));
    Ok(zero_extend(32, mtime[63..32]))
  }
  else {
    if   get_config_print_clint()
    then print_log("clint[" ^ bits_str(addr) ^ "] -> <not-mapped>");
    match t {
      InstructionFetch() => Err(E_Fetch_Access_Fault()),
      Load(_)            => Err(E_Load_Access_Fault()),
      _                  => Err(E_SAMO_Access_Fault())
    }
  }
}

function clint_dispatch() -> unit = {
  mip[MTI] = bool_to_bits(mtimecmp <=_u mtime);
  if currentlyEnabled(Ext_Sstc) & menvcfg[STCE] == 0b1 then {
    mip[STI] = bool_to_bits(stimecmp <=_u mtime);
  };
  if get_config_print_clint()
  then print_log("clint mtime " ^ bits_str(mtime) ^ " (mip.MTI <- " ^ bits_str(mip[MTI]) ^
    (if currentlyEnabled(Ext_Sstc) then ", mip.STI <- " ^ bits_str(mip[STI]) else "") ^ ")");
}

val clint_store: forall 'n, 'n > 0. (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
function clint_store(Physaddr(addr), width, data) = {
  let addr = addr - plat_clint_base;
  if addr == MSIP_BASE & ('n == 8 | 'n == 4) then {
    if   get_config_print_clint()
    then print_log("clint[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mip.MSI <- " ^ bits_str(data[0..0]) ^ ")");
    mip[MSI] = [data[0]];
    clint_dispatch();
    Ok(true)
  } else if addr == MTIMECMP_BASE & 'n == 8 then {
    if   get_config_print_clint()
    then print_log("clint<8>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtimecmp)");
    mtimecmp = zero_extend(64, data); // FIXME: Redundant zero_extend currently required by Lem backend
    clint_dispatch();
    Ok(true)
  } else if addr == MTIMECMP_BASE & 'n == 4 then {
    if   get_config_print_clint()
    then print_log("clint<4>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtimecmp)");
    mtimecmp = vector_update_subrange(mtimecmp, 31, 0, zero_extend(32, data));  // FIXME: Redundant zero_extend currently required by Lem backend
    clint_dispatch();
    Ok(true)
  } else if addr == MTIMECMP_BASE_HI & 'n == 4 then {
    if   get_config_print_clint()
    then print_log("clint<4>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtimecmp)");
    mtimecmp = vector_update_subrange(mtimecmp, 63, 32, zero_extend(32, data)); // FIXME: Redundant zero_extend currently required by Lem backend
    clint_dispatch();
    Ok(true)
  } else if addr == MTIME_BASE & 'n == 8 then {
    if   get_config_print_clint()
    then print_log("clint<8>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtime)");
    mtime = data;
    clint_dispatch();
    Ok(true)
  } else if addr == MTIME_BASE & 'n == 4 then {
    if   get_config_print_clint()
    then print_log("clint<4>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtime)");
    mtime[31 .. 0] = data;
    clint_dispatch();
    Ok(true)
  } else if addr == MTIME_BASE_HI & 'n == 4 then {
    if   get_config_print_clint()
    then print_log("clint<4>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtime)");
    mtime[63 .. 32] = data;
    clint_dispatch();
    Ok(true)
  } else {
    if   get_config_print_clint()
    then print_log("clint[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (<unmapped>)");
    Err(E_SAMO_Access_Fault())
  }
}

// Counters and timers are affected by Smcntrpmf (and the forthcoming Sdext extension).

function should_inc_mcycle(priv : Privilege) -> bool =
  mcountinhibit[CY] == 0b0 & counter_priv_filter_bit(mcyclecfg, priv) == 0b0

function should_inc_minstret(priv : Privilege) -> bool =
  mcountinhibit[IR] == 0b0 & counter_priv_filter_bit(minstretcfg, priv) == 0b0

function tick_clock() -> unit = {
  if   should_inc_mcycle(cur_privilege)
  then mcycle = mcycle + 1;

  mtime  = mtime  + 1;
  clint_dispatch()
}

// Basic terminal character I/O.

val plat_term_write = impure {cpp: "plat_term_write", lem: "plat_term_write"} : bits(8) -> unit
val plat_term_read  = impure {cpp: "plat_term_read", lem: "plat_term_read"}  : unit -> bits(8)

// Spike's HTIF device interface, which multiplexes the above MMIO devices.

bitfield htif_cmd : bits(64) = {
  device  : 63 .. 56,
  cmd     : 55 .. 48,
  payload : 47 .. 0
}

// Current value of the HTIF tohost register.
register htif_tohost : bits(64)
register htif_done   : bool
register htif_exit_code : bits(64)

// Applications sometimes write the lower 32-bit payload bytes without
// writing the control bytes; this is seen in the riscv-tests suite.
// However, processing the payload bytes too early could miss a
// subsequent write to the control bytes.  As a workaround, if the
// payload is written a few times with the same value, without an
// intervening write to the control bytes, we process the whole htif
// command anyway.

register htif_cmd_write : bit
register htif_payload_writes : bits(4)

// Once a htif command has been processed, the port is reset.
function reset_htif () -> unit = {
  htif_cmd_write = bitzero;
  htif_payload_writes = 0x0;
  htif_tohost = zeros();
}

// Since the htif tohost port is only available at a single address,
// we'll assume here that physical memory model has correctly
// dispatched the address.

val htif_load : forall 'n, 0 < 'n <= max_mem_access . (MemoryAccessType(ext_access_type), physaddr, int('n)) -> MemoryOpResult(bits(8 * 'n))
function htif_load(acc, Physaddr(paddr), width) = {
  if   get_config_print_htif()
  then print_log("htif[" ^ hex_bits_str(paddr) ^ "] -> " ^ bits_str(htif_tohost));

  let base : physaddrbits = match htif_tohost_base {
    Some(base) => base,
    None() => internal_error(__FILE__, __LINE__, "HTIF load while HTIF isn't enabled"),
  };

  // Only aligned 4-byte and 8-byte accesses are supported.
  if      width == 8 & paddr == base
  then    Ok(zero_extend(64, htif_tohost))         // FIXME: Redundant zero_extend currently required by Lem backend
  else if width == 4 & paddr == base
  then    Ok(zero_extend(32, htif_tohost[31..0]))  // FIXME: Redundant zero_extend currently required by Lem backend
  else if width == 4 & paddr == base + 4
  then    Ok(zero_extend(32, htif_tohost[63..32])) // FIXME: Redundant zero_extend currently required by Lem backend
  else match acc {
    InstructionFetch() => Err(E_Fetch_Access_Fault()),
    Load(_)            => Err(E_Load_Access_Fault()),
    _                  => Err(E_SAMO_Access_Fault())
  }
}

val htif_store : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
function htif_store(Physaddr(paddr), width, data) = {
  if   get_config_print_htif()
  then print_log("htif[" ^ hex_bits_str(paddr) ^ "] <- " ^ bits_str(data));

  let base : physaddrbits = match htif_tohost_base {
    Some(base) => base,
    None() => internal_error(__FILE__, __LINE__, "HTIF store while HTIF isn't enabled"),
  };

  // Store the written value so that we can ack it later.
  // Only aligned 4-byte and 8-byte accesses are supported.
  if      width == 8 & paddr == base
  then    { htif_cmd_write = bitone;
            htif_payload_writes = htif_payload_writes + 1;
            htif_tohost = zero_extend(data) }
  else if width == 4 & paddr == base
  then    { if   data == htif_tohost[31 .. 0]
            then htif_payload_writes = htif_payload_writes + 1
            else htif_payload_writes = 0x1;
            htif_tohost = vector_update_subrange(htif_tohost, 31, 0, data) }
  else if width == 4 & paddr == base + 4
  then    { if   data[15 .. 0] == htif_tohost[47 .. 32]
            then htif_payload_writes = htif_payload_writes + 1
            else htif_payload_writes = 0x1;
            htif_cmd_write = bitone;
            htif_tohost = vector_update_subrange(htif_tohost, 63, 32, data) }
  else return Err(E_SAMO_Access_Fault());

  // Execute if there were repeated writes of the same payload without
  // a cmd (e.g. in riscv-tests), or we have a complete htif command.
  if   (((htif_cmd_write == bitone) & (unsigned(htif_payload_writes) > 0))
        | (unsigned(htif_payload_writes) > 2))
  then {
    let cmd = Mk_htif_cmd(htif_tohost);
    match cmd[device] {
      0x00 => { // syscall-proxy
        if   get_config_print_htif()
        then print_log("htif-syscall-proxy cmd: " ^ bits_str(cmd[payload]));
        if   cmd[payload][0] == bitone
        then {
             htif_done = true;
             htif_exit_code = (zero_extend(64, cmd[payload]) >> 1)
        }
        else ()
      },
      0x01 => { // terminal
        if   get_config_print_htif()
        then print_log("htif-term cmd: " ^ bits_str(cmd[payload]));
        match cmd[cmd] {
          0x00 => /* TODO: terminal input handling */ (),
          0x01 => plat_term_write(cmd[payload][7..0]),
          c    => print("Unknown term cmd: " ^ bits_str(c))
        };
        // reset to ack
        reset_htif()
      },
      _ => print("htif-???? cmd: " ^ bits_str(data))
    }
  };
  Ok(true)
}

// Top-level MMIO dispatch
function within_mmio_readable forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> bool =
  if get_config_rvfi()
  then false
  else within_clint(addr, width) | (within_htif_readable(addr, width) & 1 <= 'n)

function within_mmio_writable forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> bool =
  if get_config_rvfi()
  then false
  else within_clint(addr, width) | (within_htif_writable(addr, width) & 'n <= 8)

function mmio_read forall 'n, 0 < 'n <= max_mem_access . (t : MemoryAccessType(ext_access_type), paddr : physaddr, width : int('n)) -> MemoryOpResult(bits(8 * 'n)) =
  if   within_clint(paddr, width)
  then clint_load(t, paddr, width)
  else if within_htif_readable(paddr, width)
  then htif_load(t, paddr, width)
  else match t {
    InstructionFetch() => Err(E_Fetch_Access_Fault()),
    Load(_)            => Err(E_Load_Access_Fault()),
    _                  => Err(E_SAMO_Access_Fault())
  }

function mmio_write forall 'n, 0 < 'n <= max_mem_access . (paddr : physaddr, width : int('n), data: bits(8 * 'n)) -> MemoryOpResult(bool) =
  if   within_clint(paddr, width)
  then clint_store(paddr, width, data)
  else if within_htif_writable(paddr, width)
  then htif_store(paddr, width, data)
  else Err(E_SAMO_Access_Fault())

// Platform initialization and ticking.

function init_platform() -> unit = {
  htif_tohost = zeros();
  htif_done   = false;
  htif_exit_code = zeros();
  htif_cmd_write = bitzero;
  htif_payload_writes = zeros();
}

// Platform-specific wait-for-interrupt
function platform_wfi() -> unit = ()

// NOTE: According to the debug specification, any control transfer
// instruction that jumps into or out of the Program Buffer may trigger
// an illegal instruction exception. However, our implementation currently
// permits jumps in both directions without enforcing this restriction.
function program_buffer_read forall 'n, 0 < 'n <= max_mem_access . (access_type : MemoryAccessType(ext_access_type), paddr : physaddr, width : int('n)) -> MemoryOpResult(bits(8 * 'n)) = {
  match access_type {
    InstructionFetch() => {
      let Physaddr(addr) = paddr;

      // Calculate relative address within the program buffer
      let relative_addr = addr - plat_program_buffer_base;
      let program_buffer_size = unsigned(plat_program_buffer_size);
      // Which progbuf register (0-15)
      let word_addr = unsigned(relative_addr) / 4;

      // Check if we are beyond the program buffer and need implicit ebreak
      if addr == (plat_program_buffer_base + plat_program_buffer_size) & (config platform.debug_module.num_prog_reg : int == 1 | config platform.debug_module.impebreak : bool) then {
        if width == 4 then Ok(EBREAK_INSTRUCTION)
        else if width == 2 then Ok(C_EBREAK_INSTRUCTION)
        else Err(E_Fetch_Access_Fault())
      }
      else {
        // Offset within that register
        let byte_offset = unsigned(relative_addr) % 4;

        // Get the appropriate progbuf register
        let progbuf_data : bits(32) =
          if word_addr < 16
          then progbuf_regs[word_addr]
          // Out of Range
          else return Err(E_Fetch_Access_Fault());

        if width == 4 then {
          if byte_offset == 0 then Ok(progbuf_data)
          else Err(E_Fetch_Addr_Align())
        }
        else if width == 2 then {
          if byte_offset == 0 then Ok(progbuf_data[15..0])
          else if byte_offset == 2 then Ok(progbuf_data[31..16])
          else Err(E_Fetch_Addr_Align())
        }
        else Err(E_Fetch_Access_Fault())
      };
    },
  Load(Data) => Err(E_Load_Access_Fault()),
  _          => Err(E_SAMO_Access_Fault())
  }
}
