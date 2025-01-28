/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Platform-specific definitions, and basic MMIO devices. */

/* Current constraints on this implementation are:
   - it cannot access memory directly, but instead provides definitions for the physical memory model
   - it can access system register state, needed to manipulate interrupt bits
   - it relies on externs to get platform address information and doesn't hardcode them
*/

val elf_tohost = pure {
  interpreter: "Elf_loader.elf_tohost",
  c: "elf_tohost"
} :  unit -> int

val elf_entry = pure {
  interpreter: "Elf_loader.elf_entry",
  c: "elf_entry"
} : unit -> int

// Cache block size is 2^cache_block_size_exp. Max is `max_mem_access` (4096)
// because this model performs `cbo.zero` with a single write, and the behaviour
// with cache blocks larger than a page is not clearly defined.
val plat_cache_block_size_exp = pure {c: "plat_cache_block_size_exp", interpreter: "Platform.cache_block_size_exp", lem: "plat_cache_block_size_exp"} : unit -> range(0, 12)

/* Main memory */
val plat_ram_base = pure {c: "plat_ram_base", interpreter: "Platform.dram_base", lem: "plat_ram_base"} : unit -> physaddrbits
val plat_ram_size = pure {c: "plat_ram_size", interpreter: "Platform.dram_size", lem: "plat_ram_size"} : unit -> physaddrbits

/* whether the MMU should update dirty bits in PTEs */
val plat_enable_dirty_update = pure {interpreter: "Platform.enable_dirty_update",
                                     c: "plat_enable_dirty_update",
                                     lem: "plat_enable_dirty_update"} : unit -> bool

/* whether the platform supports misaligned accesses without trapping to M-mode. if false,
 * misaligned loads/stores are trapped to Machine mode.
 */
val plat_enable_misaligned_access = pure {interpreter: "Platform.enable_misaligned_access",
                                          c: "plat_enable_misaligned_access",
                                          lem: "plat_enable_misaligned_access"} : unit -> bool

/* whether mtval stores the bits of a faulting instruction on illegal instruction exceptions */
val plat_mtval_has_illegal_inst_bits = pure {interpreter: "Platform.mtval_has_illegal_inst_bits",
                                             c: "plat_mtval_has_illegal_inst_bits",
                                             lem: "plat_mtval_has_illegal_inst_bits"} : unit -> bool

/* ROM holding reset vector and device-tree DTB */
val plat_rom_base   = pure {interpreter: "Platform.rom_base", c: "plat_rom_base", lem: "plat_rom_base"} : unit -> physaddrbits
val plat_rom_size   = pure {interpreter: "Platform.rom_size", c: "plat_rom_size", lem: "plat_rom_size"} : unit -> physaddrbits

/* Location of clock-interface, which should match with the spec in the DTB */
val plat_clint_base = pure {interpreter: "Platform.clint_base", c: "plat_clint_base", lem: "plat_clint_base"} : unit -> physaddrbits
val plat_clint_size = pure {interpreter: "Platform.clint_size", c: "plat_clint_size", lem: "plat_clint_size"} : unit -> physaddrbits

/* Location of HTIF ports */
val plat_htif_tohost = pure {c: "plat_htif_tohost", lem: "plat_htif_tohost"} : unit -> physaddrbits
function plat_htif_tohost () = to_bits(physaddrbits_len, elf_tohost ())
// todo: fromhost

/* Physical memory map predicates */

function within_phys_mem forall 'n, 'n <= max_mem_access. (physaddr(addr) : physaddr, width : int('n)) -> bool = {
  /* To avoid overflow issues when physical memory extends to the end
   * of the addressable range, we need to perform address bound checks
   * on unsigned unbounded integers.
   */
  let addr_int     = unsigned(addr);
  let ram_base_int = unsigned(plat_ram_base ());
  let rom_base_int = unsigned(plat_rom_base ());
  let ram_size_int = unsigned(plat_ram_size ());
  let rom_size_int = unsigned(plat_rom_size ());

  /* todo: iterate over segment list */
  if      (  ram_base_int <= addr_int
           & (addr_int + sizeof('n)) <= (ram_base_int + ram_size_int))
  then    true
  else if (  rom_base_int <= addr_int
           & (addr_int + sizeof('n)) <= (rom_base_int + rom_size_int))
  then    true
  else {
    print_platform("within_phys_mem: " ^ BitStr(addr) ^ " not within phys-mem:");
    print_platform("  plat_rom_base: " ^ BitStr(plat_rom_base ()));
    print_platform("  plat_rom_size: " ^ BitStr(plat_rom_size ()));
    print_platform("  plat_ram_base: " ^ BitStr(plat_ram_base ()));
    print_platform("  plat_ram_size: " ^ BitStr(plat_ram_size ()));
    false
  }
}

function within_clint forall 'n, 0 < 'n <= max_mem_access . (physaddr(addr) : physaddr, width : int('n)) -> bool = {
  /* To avoid overflow issues when physical memory extends to the end
   * of the addressable range, we need to perform address bound checks
   * on unsigned unbounded integers.
   */
  let addr_int       = unsigned(addr);
  let clint_base_int = unsigned(plat_clint_base ());
  let clint_size_int = unsigned(plat_clint_size ());
    clint_base_int <= addr_int
  & (addr_int + sizeof('n)) <= (clint_base_int + clint_size_int)
}

function within_htif_writable forall 'n, 0 < 'n <= max_mem_access . (physaddr(addr) : physaddr, width : int('n)) -> bool =
    plat_htif_tohost() == addr | (plat_htif_tohost() + 4 == addr & width == 4)

function within_htif_readable forall 'n, 0 < 'n <= max_mem_access . (physaddr(addr) : physaddr, width : int('n)) -> bool =
    plat_htif_tohost() == addr | (plat_htif_tohost() + 4 == addr & width == 4)

/* CLINT (Core Local Interruptor), based on Spike. */

val plat_insns_per_tick = pure {interpreter: "Platform.insns_per_tick", c: "plat_insns_per_tick", lem: "plat_insns_per_tick"} : unit -> int

// Each hart has a memory-mapped mtimecmp register. Typically these are
// exposed as an array in CLINT. The CLINT implementation here is currently
// hard-coded to use the mtimecmp for hart 0.
register mtimecmp : bits(64)

// Unlike mtimecmp, stimecmp is a real CSR; not memory mapped.
register stimecmp : bits(64)

/* CLINT memory-mapped IO */

/* relative address map:
 *
 * 0000 msip hart 0         -- memory-mapped software interrupt
 * 0004 msip hart 1
 * 4000 mtimecmp hart 0 lo  -- memory-mapped timer thresholds
 * 4004 mtimecmp hart 0 hi
 * 4008 mtimecmp hart 1 lo
 * 400c mtimecmp hart 1 hi
 * bff8 mtime lo            -- memory-mapped clocktimer value
 * bffc mtime hi
 */

let MSIP_BASE        : physaddrbits = zero_extend(0x00000)
let MTIMECMP_BASE    : physaddrbits = zero_extend(0x04000)
let MTIMECMP_BASE_HI : physaddrbits = zero_extend(0x04004)
let MTIME_BASE       : physaddrbits = zero_extend(0x0bff8)
let MTIME_BASE_HI    : physaddrbits = zero_extend(0x0bffc)

val clint_load : forall 'n, 'n > 0. (AccessType(ext_access_type), physaddr, int('n)) -> MemoryOpResult(bits(8 * 'n))
function clint_load(t, physaddr(addr), width) = {
  let addr = addr - plat_clint_base ();
  /* FIXME: For now, only allow exact aligned access. */
  if addr == MSIP_BASE & ('n == 8 | 'n == 4)
  then {
    if   get_config_print_platform()
    then print_platform("clint[" ^ BitStr(addr) ^ "] -> " ^ BitStr(mip[MSI]));
    Ok(zero_extend(sizeof(8 * 'n), mip[MSI]))
  }
  else if addr == MTIMECMP_BASE & ('n == 4)
  then {
    if   get_config_print_platform()
    then print_platform("clint<4>[" ^ BitStr(addr) ^ "] -> " ^ BitStr(mtimecmp[31..0]));
    /* FIXME: Redundant zero_extend currently required by Lem backend */
    Ok(zero_extend(32, mtimecmp[31..0]))
  }
  else if addr == MTIMECMP_BASE & ('n == 8)
  then {
    if   get_config_print_platform()
    then print_platform("clint<8>[" ^ BitStr(addr) ^ "] -> " ^ BitStr(mtimecmp));
    /* FIXME: Redundant zero_extend currently required by Lem backend */
    Ok(zero_extend(64, mtimecmp))
  }
  else if addr == MTIMECMP_BASE_HI & ('n == 4)
  then {
    if   get_config_print_platform()
    then print_platform("clint-hi<4>[" ^ BitStr(addr) ^ "] -> " ^ BitStr(mtimecmp[63..32]));
    /* FIXME: Redundant zero_extend currently required by Lem backend */
    Ok(zero_extend(32, mtimecmp[63..32]))
  }
  else if addr == MTIME_BASE & ('n == 4)
  then {
    if   get_config_print_platform()
    then print_platform("clint[" ^ BitStr(addr) ^ "] -> " ^ BitStr(mtime));
    Ok(zero_extend(32, mtime[31..0]))
  }
  else if addr == MTIME_BASE & ('n == 8)
  then {
    if   get_config_print_platform()
    then print_platform("clint[" ^ BitStr(addr) ^ "] -> " ^ BitStr(mtime));
    Ok(zero_extend(64, mtime))
  }
  else if addr == MTIME_BASE_HI & ('n == 4)
  then {
    if   get_config_print_platform()
    then print_platform("clint[" ^ BitStr(addr) ^ "] -> " ^ BitStr(mtime));
    Ok(zero_extend(32, mtime[63..32]))
  }
  else {
    if   get_config_print_platform()
    then print_platform("clint[" ^ BitStr(addr) ^ "] -> <not-mapped>");
    match t {
      Execute()  => Err(E_Fetch_Access_Fault()),
      Read(Data) => Err(E_Load_Access_Fault()),
      _          => Err(E_SAMO_Access_Fault())
    }
  }
}

function clint_dispatch() -> unit = {
  mip[MTI] = bool_to_bits(mtimecmp <=_u mtime);
  if extensionEnabled(Ext_Sstc) then {
    mip[STI] = bool_to_bits(stimecmp <=_u mtime);
  };
  if get_config_print_platform()
  then print_platform("clint mtime " ^ BitStr(mtime) ^ " (mip.MTI <- " ^ BitStr(mip[MTI]) ^
    (if extensionEnabled(Ext_Sstc) then ", mip.STI <- " ^ BitStr(mip[STI]) else "") ^ ")");
}

/* The rreg effect is due to checking mtime. */
val clint_store: forall 'n, 'n > 0. (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
function clint_store(physaddr(addr), width, data) = {
  let addr = addr - plat_clint_base ();
  if addr == MSIP_BASE & ('n == 8 | 'n == 4) then {
    if   get_config_print_platform()
    then print_platform("clint[" ^ BitStr(addr) ^ "] <- " ^ BitStr(data) ^ " (mip.MSI <- " ^ BitStr(data[0]) ^ ")");
    mip[MSI] = [data[0]];
    clint_dispatch();
    Ok(true)
  } else if addr == MTIMECMP_BASE & 'n == 8 then {
    if   get_config_print_platform()
    then print_platform("clint<8>[" ^ BitStr(addr) ^ "] <- " ^ BitStr(data) ^ " (mtimecmp)");
    mtimecmp = zero_extend(64, data); /* FIXME: Redundant zero_extend currently required by Lem backend */
    clint_dispatch();
    Ok(true)
  } else if addr == MTIMECMP_BASE & 'n == 4 then {
    if   get_config_print_platform()
    then print_platform("clint<4>[" ^ BitStr(addr) ^ "] <- " ^ BitStr(data) ^ " (mtimecmp)");
    mtimecmp = vector_update_subrange(mtimecmp, 31, 0, zero_extend(32, data));  /* FIXME: Redundant zero_extend currently required by Lem backend */
    clint_dispatch();
    Ok(true)
  } else if addr == MTIMECMP_BASE_HI & 'n == 4 then {
    if   get_config_print_platform()
    then print_platform("clint<4>[" ^ BitStr(addr) ^ "] <- " ^ BitStr(data) ^ " (mtimecmp)");
    mtimecmp = vector_update_subrange(mtimecmp, 63, 32, zero_extend(32, data)); /* FIXME: Redundant zero_extend currently required by Lem backend */
    clint_dispatch();
    Ok(true)
  } else if addr == MTIME_BASE & 'n == 8 then {
    if   get_config_print_platform()
    then print_platform("clint<8>[" ^ BitStr(addr) ^ "] <- " ^ BitStr(data) ^ " (mtime)");
    mtime = data;
    clint_dispatch();
    Ok(true)
  } else if addr == MTIME_BASE & 'n == 4 then {
    if   get_config_print_platform()
    then print_platform("clint<4>[" ^ BitStr(addr) ^ "] <- " ^ BitStr(data) ^ " (mtime)");
    mtime[31 .. 0] = data;
    clint_dispatch();
    Ok(true)
  } else if addr == MTIME_BASE_HI & 'n == 4 then {
    if   get_config_print_platform()
    then print_platform("clint<4>[" ^ BitStr(addr) ^ "] <- " ^ BitStr(data) ^ " (mtime)");
    mtime[63 .. 32] = data;
    clint_dispatch();
    Ok(true)
  } else {
    if   get_config_print_platform()
    then print_platform("clint[" ^ BitStr(addr) ^ "] <- " ^ BitStr(data) ^ " (<unmapped>)");
    Err(E_SAMO_Access_Fault())
  }
}

val tick_clock : unit -> unit
function tick_clock() = {
  if   mcountinhibit[CY] == 0b0
  then mcycle = mcycle + 1;

  mtime  = mtime  + 1;
  clint_dispatch()
}

/* Basic terminal character I/O. */

val plat_term_write = impure {c: "plat_term_write", lem: "plat_term_write"} : bits(8) -> unit
val plat_term_read  = impure {c: "plat_term_read", lem: "plat_term_read"}  : unit -> bits(8)

/* Spike's HTIF device interface, which multiplexes the above MMIO devices. */

bitfield htif_cmd : bits(64) = {
  device  : 63 .. 56,
  cmd     : 55 .. 48,
  payload : 47 .. 0
}

register htif_tohost : bits(64)
register htif_done   : bool
register htif_exit_code : bits(64)

/* Applications sometimes write the lower 32-bit payload bytes without
   writing the control bytes; this is seen in the riscv-tests suite.
   However, processing the payload bytes too early could miss a
   subsequent write to the control bytes.  As a workaround, if the
   payload is written a few times with the same value, without an
   intervening write to the control bytes, we process the whole htif
   command anyway.  */

register htif_cmd_write : bit
register htif_payload_writes : bits(4)

/* Once a htif command has been processed, the port is reset. */
function reset_htif () -> unit = {
  htif_cmd_write = bitzero;
  htif_payload_writes = 0x0;
  htif_tohost = zeros();
}

/* Since the htif tohost port is only available at a single address,
 * we'll assume here that physical memory model has correctly
 * dispatched the address.
 */

val htif_load : forall 'n, 'n > 0. (AccessType(ext_access_type), physaddr, int('n)) -> MemoryOpResult(bits(8 * 'n))
function htif_load(t, physaddr(paddr), width) = {
  if   get_config_print_platform()
  then print_platform("htif[" ^ BitStr(paddr) ^ "] -> " ^ BitStr(htif_tohost));
  /* FIXME: For now, only allow the expected access widths. */
  if      width == 8 & (paddr == plat_htif_tohost())
  then    Ok(zero_extend(64, htif_tohost))         /* FIXME: Redundant zero_extend currently required by Lem backend */
  else if width == 4 & paddr == plat_htif_tohost()
  then    Ok(zero_extend(32, htif_tohost[31..0]))  /* FIXME: Redundant zero_extend currently required by Lem backend */
  else if width == 4 & paddr == plat_htif_tohost() + 4
  then    Ok(zero_extend(32, htif_tohost[63..32])) /* FIXME: Redundant zero_extend currently required by Lem backend */
  else match t {
    Execute()  => Err(E_Fetch_Access_Fault()),
    Read(Data) => Err(E_Load_Access_Fault()),
    _          => Err(E_SAMO_Access_Fault())
  }
}

/* The rreg,wreg effects are an artifact of using 'register' to implement device state. */
val htif_store: forall 'n, 0 < 'n <= 8. (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
function htif_store(physaddr(paddr), width, data) = {
  if   get_config_print_platform()
  then print_platform("htif[" ^ BitStr(paddr) ^ "] <- " ^ BitStr(data));
  /* Store the written value so that we can ack it later. */
  if      width == 8
  then    { htif_cmd_write = bitone;
            htif_payload_writes = htif_payload_writes + 1;
            htif_tohost = zero_extend(data) }
  else if width == 4 & paddr == plat_htif_tohost()
  then    { if   data == htif_tohost[31 .. 0]
            then htif_payload_writes = htif_payload_writes + 1
            else htif_payload_writes = 0x1;
            htif_tohost = vector_update_subrange(htif_tohost, 31, 0, data) }
  else if width == 4 & paddr == plat_htif_tohost() + 4
  then    { if   data[15 .. 0] == htif_tohost[47 .. 32]
            then htif_payload_writes = htif_payload_writes + 1
            else htif_payload_writes = 0x1;
            htif_cmd_write = bitone;
            htif_tohost = vector_update_subrange(htif_tohost, 63, 32, data) }
  /* unaligned command writes are not supported and will not be detected */
  else    { htif_tohost = zero_extend(data) };

  /* Execute if there were repeated writes of the same payload without
   * a cmd (e.g. in riscv-tests), or we have a complete htif command.
   */
  if   (((htif_cmd_write == bitone) & (unsigned(htif_payload_writes) > 0))
        | (unsigned(htif_payload_writes) > 2))
  then {
    let cmd = Mk_htif_cmd(htif_tohost);
    match cmd[device] {
      0x00 => { /* syscall-proxy */
        if   get_config_print_platform()
        then print_platform("htif-syscall-proxy cmd: " ^ BitStr(cmd[payload]));
        if   cmd[payload][0] == bitone
        then {
             htif_done = true;
             htif_exit_code = (zero_extend(64, cmd[payload]) >> 1)
        }
        else ()
      },
      0x01 => { /* terminal */
        if   get_config_print_platform()
        then print_platform("htif-term cmd: " ^ BitStr(cmd[payload]));
        match cmd[cmd] {
          0x00 => /* TODO: terminal input handling */ (),
          0x01 => plat_term_write(cmd[payload][7..0]),
          c    => print("Unknown term cmd: " ^ BitStr(c))
        };
        /* reset to ack */
        reset_htif()
      },
      d => print("htif-???? cmd: " ^ BitStr(data))
    }
  };
  Ok(true)
}

val htif_tick : unit -> unit
function htif_tick() = {
  if   get_config_print_platform()
  then print_platform("htif::tick " ^ BitStr(htif_tohost));
  htif_tohost = htif_tohost /* prevent this function being optimized out */
}

/* Top-level MMIO dispatch */
$ifndef RVFI_DII
function within_mmio_readable forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> bool =
  within_clint(addr, width) | (within_htif_readable(addr, width) & 1 <= 'n)
$else
function within_mmio_readable forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> bool = false
$endif

$ifndef RVFI_DII
function within_mmio_writable forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> bool =
  within_clint(addr, width) | (within_htif_writable(addr, width) & 'n <= 8)
$else
function within_mmio_writable forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> bool = false
$endif

function mmio_read forall 'n, 0 < 'n <= max_mem_access . (t : AccessType(ext_access_type), paddr : physaddr, width : int('n)) -> MemoryOpResult(bits(8 * 'n)) =
  if   within_clint(paddr, width)
  then clint_load(t, paddr, width)
  else if within_htif_readable(paddr, width) & (1 <= 'n)
  then htif_load(t, paddr, width)
  else match t {
    Execute()  => Err(E_Fetch_Access_Fault()),
    Read(Data) => Err(E_Load_Access_Fault()),
    _          => Err(E_SAMO_Access_Fault())
  }

function mmio_write forall 'n, 0 <'n <= max_mem_access . (paddr : physaddr, width : int('n), data: bits(8 * 'n)) -> MemoryOpResult(bool) =
  if   within_clint(paddr, width)
  then clint_store(paddr, width, data)
  else if within_htif_writable(paddr, width) & 'n <= 8
  then htif_store(paddr, width, data)
  else Err(E_SAMO_Access_Fault())

/* Platform initialization and ticking. */

function init_platform() -> unit = {
  htif_tohost = zeros();
  htif_done   = false;
  htif_exit_code = zeros();
  htif_cmd_write = bitzero;
  htif_payload_writes = zeros();
}

function tick_platform() -> unit = {
  htif_tick();
}

/* Platform-specific handling of instruction faults */

function handle_illegal() -> unit = {
  let info = if plat_mtval_has_illegal_inst_bits ()
             then Some(instbits)
             else None();
  let t : sync_exception = struct { trap    = E_Illegal_Instr(),
                                    excinfo = info,
                                    ext     = None() };
  set_next_pc(exception_handler(cur_privilege, CTL_TRAP(t), PC))
}

/* Platform-specific wait-for-interrupt */
function platform_wfi() -> unit = ()
