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

private function within_clint forall 'n, 0 < 'n <= max_mem_access . (Physaddr(addr) : physaddr, width : int('n)) -> bool = {
  if not(plat_have_clint) then return false;
  // The CLINT only serves 4095 harts, numbered 0 through 4094, identified by their `mhartid`.
  if unsigned(mhartid) >= 4095 then return false;

  // To avoid overflow issues when physical memory extends to the end
  // of the addressable range, we need to perform address bound checks
  // on unsigned unbounded integers.
  let addr_int       = unsigned(addr);
  let clint_base_int = unsigned(plat_clint_base);
  let clint_size_int = unsigned(plat_clint_size);
    clint_base_int <= addr_int
  & (addr_int + sizeof('n)) <= (clint_base_int + clint_size_int)
}

private function within_sig forall 'n, 0 < 'n <= max_mem_access . (Physaddr(addr) : physaddr, width : int('n)) -> bool = {
  if not(plat_have_sig) then return false;

  let addr_int = unsigned(addr);
  let sig_base_int = unsigned(plat_sig_base);
  let sig_size_int = unsigned(plat_sig_size);
    sig_base_int <= addr_int
  & (addr_int + sizeof('n)) <= (sig_base_int + sig_size_int)
}

private function within_htif_writable forall 'n, 0 < 'n <= max_mem_access . (Physaddr(addr) : physaddr, width : int('n)) -> bool =
  match htif_tohost_base {
    None() => false,
    Some(base) => (addr <_u base + htif_tohost_size) & (addr + width >_u base)
  }

private function within_htif_readable forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> bool =
  within_htif_writable(addr, width)

// CLINT (Core Local Interruptor), based on Spike.

// This implements the interrupt controller interface for a platform
// containing a single hart only. Typically the `msip` and `mtimecmp`
// registers below are exposed as an array in a CLINT. The CLINT
// implementation here is currently hard-coded to use the `msip` and
// `mtimecmp` for the hart identified by `mhartid`.  The CLINT
// serves 4095 harts, so the register arrays have 4095 entries and are
// indexed by their `mhartid`.  Harts with out-of-range `mhartid` values
// cannot be served by the CLINT.

// Each `msip` register is a 32-bit wide register where the upper 31
// bits are tied to 0. The least significant bit is reflected in the
// `MSIP` bit of the `mip` CSR. Other bits in the `msip` registers are
// hardwired to zero. On reset, each `msip` register is cleared to zero.
private register msip : bits(32) = zeros()

// Each hart has a memory-mapped `mtimecmp` register.
private register mtimecmp : bits(64)

// This is a platform-wide memory-mapped register that counts the
// number of cycles from the system clock.
private register mtime : bits(64)

function clint_get_mtime() -> bits(64) = mtime

function clint_get_hart_mtimecmp() -> bits(64) = mtimecmp

function clint_machine_software_interrupt_pending() -> bits(1) = msip[0]

// CLINT memory-mapped IO

// relative address map:
//
// 0000 msip hart 0         -- memory-mapped software interrupt
// 0004 msip hart 1
// ...
// 3ff8 msip hart 4094
// 3ffc --- reserved
// 4000 mtimecmp hart 0 lo  -- memory-mapped timer thresholds
// 4004 mtimecmp hart 0 hi
// 4008 mtimecmp hart 1 lo
// 400c mtimecmp hart 1 hi
// ...
// bff0 mtimecmp hart 4094 lo
// bff4 mtimecmp hart 4094 hi
// bff8 mtime lo            -- memory-mapped clocktimer value
// bffc mtime hi

let MSIP_BASE        : physaddrbits = zero_extend(0x00000)
let MTIMECMP_BASE    : physaddrbits = zero_extend(0x04000)
let MTIMECMP_BASE_HI : physaddrbits = zero_extend(0x04004)
let MTIME_BASE       : physaddrbits = zero_extend(0x0bff8)
let MTIME_BASE_HI    : physaddrbits = zero_extend(0x0bffc)

private val clint_load : forall 'n, 'n > 0. (MemoryAccessType(mem_payload), physaddr, int('n)) -> MemoryOpResult(bits(8 * 'n))
function clint_load(access, paddr, width) = {
  let hart_msip_addr        = MSIP_BASE        + zero_extend(mhartid << 2);
  let hart_mtimecmp_addr    = MTIMECMP_BASE    + zero_extend(mhartid << 3);
  let hart_mtimecmp_hi_addr = MTIMECMP_BASE_HI + zero_extend(mhartid << 3);

  let Physaddr(addr) = paddr;
  let addr = addr - plat_clint_base;
  // FIXME: For now, only allow exact aligned access.
  if addr == hart_msip_addr & ('n == 8 | 'n == 4)
  then {
    if   get_config_print_clint()
    then print_log("clint[" ^ bits_str(addr) ^ "] -> " ^ bits_str(msip));
    Ok(zero_extend(sizeof(8 * 'n), msip))
  }
  else if addr == hart_mtimecmp_addr & ('n == 4)
  then {
    if   get_config_print_clint()
    then print_log("clint<4>[" ^ bits_str(addr) ^ "] -> " ^ bits_str(mtimecmp[31..0]));
    // FIXME: Redundant zero_extend currently required by Lem backend
    Ok(zero_extend(32, mtimecmp[31..0]))
  }
  else if addr == hart_mtimecmp_addr & ('n == 8)
  then {
    if   get_config_print_clint()
    then print_log("clint<8>[" ^ bits_str(addr) ^ "] -> " ^ bits_str(mtimecmp));
    // FIXME: Redundant zero_extend currently required by Lem backend
    Ok(zero_extend(64, mtimecmp))
  }
  else if addr == hart_mtimecmp_hi_addr & ('n == 4)
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
    Err(paddr, accessFaultFromAccessType(access))
  }
}

private val clint_store: forall 'n, 'n > 0. (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
function clint_store(paddr, width, data) = {
  let hart_msip_addr        = MSIP_BASE        + zero_extend(mhartid << 2);
  let hart_mtimecmp_addr    = MTIMECMP_BASE    + zero_extend(mhartid << 3);
  let hart_mtimecmp_hi_addr = MTIMECMP_BASE_HI + zero_extend(mhartid << 3);

  let Physaddr(addr) = paddr;
  let addr = addr - plat_clint_base;
  if addr == hart_msip_addr & ('n == 8 | 'n == 4) then {
    if   get_config_print_clint()
    then print_log("clint[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (msip <- " ^ bits_str(data) ^ ")");
    msip[0] = data[0];
    Ok(true)
  } else if addr == hart_mtimecmp_addr & 'n == 8 then {
    if   get_config_print_clint()
    then print_log("clint<8>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtimecmp)");
    mtimecmp = zero_extend(64, data); // FIXME: Redundant zero_extend currently required by Lem backend
    Ok(true)
  } else if addr == hart_mtimecmp_addr & 'n == 4 then {
    if   get_config_print_clint()
    then print_log("clint<4>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtimecmp)");
    mtimecmp = vector_update_subrange(mtimecmp, 31, 0, zero_extend(32, data));  // FIXME: Redundant zero_extend currently required by Lem backend
    Ok(true)
  } else if addr == hart_mtimecmp_hi_addr & 'n == 4 then {
    if   get_config_print_clint()
    then print_log("clint<4>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtimecmp)");
    mtimecmp = vector_update_subrange(mtimecmp, 63, 32, zero_extend(32, data)); // FIXME: Redundant zero_extend currently required by Lem backend
    Ok(true)
  } else if addr == MTIME_BASE & 'n == 8 then {
    if   get_config_print_clint()
    then print_log("clint<8>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtime)");
    mtime = data;
    Ok(true)
  } else if addr == MTIME_BASE & 'n == 4 then {
    if   get_config_print_clint()
    then print_log("clint<4>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtime)");
    mtime[31 .. 0] = data;
    Ok(true)
  } else if addr == MTIME_BASE_HI & 'n == 4 then {
    if   get_config_print_clint()
    then print_log("clint<4>[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (mtime)");
    mtime[63 .. 32] = data;
    Ok(true)
  } else {
    if   get_config_print_clint()
    then print_log("clint[" ^ bits_str(addr) ^ "] <- " ^ bits_str(data) ^ " (<unmapped>)");
    Err(paddr, E_SAMO_Access_Fault())
  }
}

// Counters and timers are affected by Smcntrpmf (and the forthcoming Sdext extension).

function should_inc_mcycle(priv : Privilege) -> bool =
  mcountinhibit[CY] == 0b0 & counter_priv_filter_bit(mcyclecfg, priv) == 0b0

function should_inc_minstret(priv : Privilege) -> bool =
  mcountinhibit[IR] == 0b0 & counter_priv_filter_bit(minstretcfg, priv) == 0b0

function clint_tick_clock() -> unit = {
  if   should_inc_mcycle(cur_privilege)
  then mcycle = mcycle + 1;

  mtime  = mtime  + 1;
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
register htif_tohost : bits(64) = zeros()
register htif_done : bool = false
register htif_exit_code : bits(64) = zeros()

// Applications sometimes write the lower 32-bit payload bytes without
// writing the control bytes; this is seen in the riscv-tests suite.
// However, processing the payload bytes too early could miss a
// subsequent write to the control bytes.  As a workaround, if the
// payload is written a few times with the same value, without an
// intervening write to the control bytes, we process the whole htif
// command anyway.

register htif_cmd_write : bits(1) = zeros()
register htif_payload_writes : bits(4) = zeros()

// Once a htif command has been processed, the port is reset.
private function reset_htif () -> unit = {
  htif_cmd_write = 0b0;
  htif_payload_writes = 0x0;
  htif_tohost = zeros();
}

// Since the htif tohost port is only available at a single address,
// we'll assume here that physical memory model has correctly
// dispatched the address.

private val htif_load : forall 'n, 0 < 'n <= max_mem_access . (MemoryAccessType(mem_payload), physaddr, int('n)) -> MemoryOpResult(bits(8 * 'n))
function htif_load(access, addr, width) = {
  let Physaddr(paddr) = addr;
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
  else    Err(addr, accessFaultFromAccessType(access))
}

private val htif_store : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
function htif_store(addr, width, data) = {
  let Physaddr(paddr) = addr;
  if   get_config_print_htif()
  then print_log("htif[" ^ hex_bits_str(paddr) ^ "] <- " ^ bits_str(data));

  let base : physaddrbits = match htif_tohost_base {
    Some(base) => base,
    None() => internal_error(__FILE__, __LINE__, "HTIF store while HTIF isn't enabled"),
  };

  // Store the written value so that we can ack it later.
  // Only aligned 4-byte and 8-byte accesses are supported.
  if      width == 8 & paddr == base
  then    { htif_cmd_write = 0b1;
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
            htif_cmd_write = 0b1;
            htif_tohost = vector_update_subrange(htif_tohost, 63, 32, data) }
  else return Err(addr, E_SAMO_Access_Fault());

  // Execute if there were repeated writes of the same payload without
  // a cmd (e.g. in riscv-tests), or we have a complete htif command.
  if   (((htif_cmd_write == 0b1) & (unsigned(htif_payload_writes) > 0))
        | (unsigned(htif_payload_writes) > 2))
  then {
    let cmd = Mk_htif_cmd(htif_tohost);
    match cmd[device] {
      0x00 => { // syscall-proxy
        if   get_config_print_htif()
        then print_log("htif-syscall-proxy cmd: " ^ bits_str(cmd[payload]));
        if   cmd[payload][0] == 0b1
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
  else within_clint(addr, width) | within_sig(addr, width) | (within_htif_readable(addr, width) & 1 <= 'n)

function within_mmio_writable forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> bool =
  if get_config_rvfi()
  then false
  else within_clint(addr, width) | within_sig(addr, width) | (within_htif_writable(addr, width) & 'n <= 8)

function mmio_read forall 'n, 0 < 'n <= max_mem_access . (access : MemoryAccessType(mem_payload), paddr : physaddr, width : int('n)) -> MemoryOpResult(bits(8 * 'n)) =
  if   within_clint(paddr, width)
  then clint_load(access, paddr, width)
  else if within_sig(paddr, width)
  then sig_load(access, paddr, width)
  else if within_htif_readable(paddr, width)
  then htif_load(access, paddr, width)
  else Err(paddr, accessFaultFromAccessType(access))

function mmio_write forall 'n, 0 < 'n <= max_mem_access . (paddr : physaddr, width : int('n), data: bits(8 * 'n)) -> MemoryOpResult(bool) =
  if   within_clint(paddr, width)
  then clint_store(paddr, width, data)
  else if within_sig(paddr, width)
  then sig_store(paddr, width, data)
  else if within_htif_writable(paddr, width)
  then htif_store(paddr, width, data)
  else Err(paddr, E_SAMO_Access_Fault())
