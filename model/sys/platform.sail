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
  // To avoid overflow issues when physical memory extends to the end
  // of the addressable range, we need to perform address bound checks
  // on unsigned unbounded integers.
  let addr_int       = unsigned(addr);
  let clint_base_int = unsigned(plat_clint_base);
  let clint_size_int = unsigned(plat_clint_size);
    clint_base_int <= addr_int
  & (addr_int + sizeof('n)) <= (clint_base_int + clint_size_int)
}

private function within_plic forall 'n, 0 < 'n <= max_mem_access .
  (Physaddr(addr) : physaddr, width : int('n)) -> bool = {
  let addr_int = unsigned(addr);
  let plic_base_int = unsigned(plat_plic_base);
  let plic_size_int = unsigned(plat_plic_size);
    plic_base_int <= addr_int
  & (addr_int + sizeof('n)) <= (plic_base_int + plic_size_int)
}

private function within_htif_writable forall 'n, 0 < 'n <= max_mem_access . (Physaddr(addr) : physaddr, width : int('n)) -> bool =
  match htif_tohost_base {
    None() => false,
    Some(base) => (addr <_u base + htif_tohost_size) & (addr + width >_u base)
  }

private function within_htif_readable forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> bool =
  within_htif_writable(addr, width)

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

// Type-level maxima (can be used in bits()/vector())
type plic_nsrc = 64        // IDs 0..63, ID0 reserved
type plic_nctx = 2         // ctx0 = hart0/M, ctx1 = hart0/S

// Term-level maxima derived from the type-level sizes
let PLIC_NSRC_MAX = sizeof(plic_nsrc)
let PLIC_NCTX_MAX = sizeof(plic_nctx)

// Runtime active (from JSON, clamped to MAX)
register plic_nsrc_active : int = PLIC_NSRC_MAX
register plic_nctx_active : int = PLIC_NCTX_MAX

private function clamp_int(x:int, lo:int, hi:int) -> int =
  if x < lo then lo else if x > hi then hi else x

register plic_priority : vector(plic_nsrc, bits(32)) = vector_init(PLIC_NSRC_MAX, (zeros() : bits(32)))
register plic_pending  : bits(plic_nsrc)
register plic_claimed  : bits(plic_nsrc)

register plic_enable_m  : bits(plic_nsrc)
register plic_enable_s  : bits(plic_nsrc)

register plic_threshold_m : bits(32)
register plic_threshold_s : bits(32)
// PLIC MMIO offsets (as int)
let PLIC_OFF_PRIORITY_END : int = unsigned(0x1000)
let PLIC_OFF_PENDING_BASE : int = unsigned(0x1000)
let PLIC_OFF_PENDING_END  : int = unsigned(0x2000)

let PLIC_OFF_ENABLE_BASE  : int = unsigned(0x2000)
let PLIC_OFF_ENABLE_END   : int = unsigned(0x3000)
let PLIC_ENABLE_STRIDE    : int = unsigned(0x80)    // per-context enable stride

let PLIC_OFF_CTX_BASE     : int = unsigned(0x200000)
let PLIC_CTX_STRIDE       : int = unsigned(0x1000)  // per-context page
let PLIC_OFF_THRESHOLD    : int = 0
let PLIC_OFF_CLAIM        : int = 4

// -------------------------
// priority helpers (packed array: bits(32 * plic_nsrc))
// -------------------------

private function plic_prio_lo(id:int) -> int = id * 32
private function plic_prio_hi(id:int) -> int = (id * 32) + 31

private function plic_priority_get(id:int) -> bits(32) = {
  // valid IDs are 1..(PLIC_NSRC_MAX-1) and also must be < active
  if id > 0 & id < plic_nsrc_active & id < PLIC_NSRC_MAX then
    plain_vector_access(plic_priority, id)
  else
    zeros()
}

private function plic_priority_set(id:int, v:bits(32)) -> unit = {
  if id > 0 & id < plic_nsrc_active & id < PLIC_NSRC_MAX then
    plic_priority = plain_vector_update(plic_priority, id, v)
  else
    ()
}

// keep as-is for now (we'll make it nctx_active-aware later)
private function plic_enable_of_ctx(ctx:int) -> bits(plic_nsrc) = {
  if ctx == 0 then plic_enable_m else plic_enable_s
}

private val clint_load : forall 'n, 'n > 0. (MemoryAccessType(mem_payload), physaddr, int('n)) -> MemoryOpResult(bits(8 * 'n))
function clint_load(access, Physaddr(addr), width) = {
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
    Err(accessFaultFromAccessType(access))
  }
}

// -------------------------
// PLIC helpers: avoid b[i] style indexing (which causes quantifier issues)
// -------------------------
private function plic_threshold_of_ctx(ctx:int) -> bits(32) = {
  if ctx == 0 then plic_threshold_m else plic_threshold_s
}

private function plic_mask32(idx:int) -> bits(32) = {
  if idx < 0 | idx >= 32 then zeros()
  else (zero_extend(32, 0b1) << idx)
}

private function plic_bit_get64(b: bits(plic_nsrc), idx:int) -> bool = {
  if idx < 0 then false
  else if idx < 32 then {
    let lo : bits(32) = b[31..0];
    (lo & plic_mask32(idx)) != zeros()
  } else if idx < 64 then {
    let hi : bits(32) = b[63..32];
    (hi & plic_mask32(idx - 32)) != zeros()
  } else false
}

private function plic_bit_set64(b: bits(plic_nsrc), idx:int) -> bits(plic_nsrc) = {
  if idx < 0 then b
  else if idx < 32 then {
    let lo : bits(32) = b[31..0];
    let hi : bits(32) = b[63..32];
    hi @ (lo | plic_mask32(idx))
  } else if idx < 64 then {
    let lo : bits(32) = b[31..0];
    let hi : bits(32) = b[63..32];
    (hi | plic_mask32(idx - 32)) @ lo
  } else b
}

private function plic_bit_clear64(b: bits(plic_nsrc), idx:int) -> bits(plic_nsrc) = {
  if idx < 0 then b
  else if idx < 32 then {
    let lo : bits(32) = b[31..0];
    let hi : bits(32) = b[63..32];
    hi @ (lo & ~(plic_mask32(idx)))
  } else if idx < 64 then {
    let lo : bits(32) = b[31..0];
    let hi : bits(32) = b[63..32];
    (hi & ~(plic_mask32(idx - 32))) @ lo
  } else b
}

// -------------------------
// PLIC arbitration (Lean-friendly termination):
// scan IDs 1..(plic_nsrc_active-1) using nat fuel + repeat loop
// -------------------------
private function plic_best_id_from(ctx:int, i:int, fuel:nat, best_id:int, best_pr:int) -> int = {
  var idx : int = i;
  var k   : int = fuel;
  var bid : int = best_id;
  var bpr : int = best_pr;

  repeat {
    if k > 0 then {
      // stop scanning once we reach configured active sources
      if idx >= plic_nsrc_active then {
        k = 0;
      } else {
        let en = plic_enable_of_ctx(ctx);
        let th = unsigned(plic_threshold_of_ctx(ctx));
        let pr = unsigned(plic_priority_get(idx));

        let cand =
          plic_bit_get64(en, idx) &
          plic_bit_get64(plic_pending, idx) &
          (not(plic_bit_get64(plic_claimed, idx))) &
          (pr > th);

        if cand then {
          let better =
            (pr > bpr) |
            ((pr == bpr) & ((bid == 0) | (idx < bid)));
          if better then {
            bid = idx;
            bpr = pr;
          } else {
            ()
          }
        } else {
          ()
        };

        idx = idx + 1;
        k = k - 1;
      }
    } else {
      ()
    }
  } until k == 0;

  bid
}
termination_measure plic_best_id_from repeat fuel

private function plic_best_id(ctx:int) -> int = {
  // use type-level max fuel, avoid int_to_nat visibility issues in Lean backend
  plic_best_id_from(ctx, 1, (PLIC_NSRC_MAX - 1), 0, 0)
}


private function plic_update_mip() -> unit = {
  let bid_m = plic_best_id(0);
  let bid_s = plic_best_id(1);

  mip[MEI] = bool_to_bit(bid_m != 0);
  if currentlyEnabled(Ext_S) then
    mip[SEI] = bool_to_bit(bid_s != 0)
  else
    ();

  print("PLIC: update_mip best(M)=" ^ dec_str(bid_m) ^
            " MEI=" ^ bits_str(mip[MEI]) ^
            (if currentlyEnabled(Ext_S) then " best(S)=" ^ dec_str(bid_s) ^ " SEI=" ^ bits_str(mip[SEI]) else ""));
}


private val plic_load : forall 'n, 'n > 0.
  (MemoryAccessType(mem_payload), physaddr, int('n)) -> MemoryOpResult(bits(8 * 'n))
function plic_load(_, Physaddr(addr), width) = {
  let off = unsigned(addr - plat_plic_base);

  // MVP: only 32-bit accesses
  if 'n != 4 then Ok(zeros())
  else {
    // priority: 0x000000 + 4*id
    if off < PLIC_OFF_PRIORITY_END then {
      let id = off / 4;
      Ok(plic_priority_get(id))
    }

    // pending bitmap: only support two words for 64 sources
    else if off == PLIC_OFF_PENDING_BASE then
      Ok(zero_extend(32, plic_pending[31..0]))
    else if off == (PLIC_OFF_PENDING_BASE + 4) then
      Ok(zero_extend(32, plic_pending[63..32]))

    // enable bitmap (MVP: ctx0 and ctx1 only, two words each)
    else if off == PLIC_OFF_ENABLE_BASE then
      Ok(zero_extend(32, plic_enable_m[31..0]))
    else if off == (PLIC_OFF_ENABLE_BASE + 4) then
      Ok(zero_extend(32, plic_enable_m[63..32]))
    else if off == (PLIC_OFF_ENABLE_BASE + PLIC_ENABLE_STRIDE) then
      Ok(zero_extend(32, plic_enable_s[31..0]))
    else if off == (PLIC_OFF_ENABLE_BASE + PLIC_ENABLE_STRIDE + 4) then
      Ok(zero_extend(32, plic_enable_s[63..32]))

    // per-context threshold/claim (MVP: ctx0 and ctx1 only)
    else if off == PLIC_OFF_CTX_BASE then
      Ok(plic_threshold_m)
    else if off == (PLIC_OFF_CTX_BASE + 4) then {
      // claim ctx0 (M)
      let id = plic_best_id(0);
      if id != 0 then {
        plic_pending = plic_bit_clear64(plic_pending, id);
        plic_claimed = plic_bit_set64(plic_claimed, id);
        plic_pending = plic_bit_clear64(plic_pending, 0);
        plic_claimed = plic_bit_clear64(plic_claimed, 0);

        plic_update_mip();
        Ok(to_bits_checked(id : int) : bits(32))
      } else {
        plic_update_mip();
        Ok(zeros())
      }
    }
    else if off == (PLIC_OFF_CTX_BASE + PLIC_CTX_STRIDE) then
      Ok(plic_threshold_s)
    else if off == (PLIC_OFF_CTX_BASE + PLIC_CTX_STRIDE + 4) then {
      // claim ctx1 (S)
      let id = plic_best_id(1);
      if id != 0 then {
        plic_pending = plic_bit_clear64(plic_pending, id);
        plic_claimed = plic_bit_set64(plic_claimed, id);
        plic_pending = plic_bit_clear64(plic_pending, 0);
        plic_claimed = plic_bit_clear64(plic_claimed, 0);
        plic_update_mip();
        Ok(to_bits_checked(id : int) : bits(32))
      } else {
        plic_update_mip();
        Ok(zeros())
      }
    }

    else Ok(zeros())
  }
}

private val plic_store : forall 'n, 'n > 0.
  (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
function plic_store(Physaddr(addr), width, data) = {
  let off = unsigned(addr - plat_plic_base);

  // MVP: only 32-bit stores
  if 'n != 4 then Ok(true)
  else {
    let wdata : bits(32) = data;

    // priority: 0x000000 + 4*id
    if off < PLIC_OFF_PRIORITY_END then {
      let id = off / 4;
      if id < plic_nsrc_active & id != 0 then {
        plic_priority_set(id, wdata);
        plic_update_mip()
      } else ();
      Ok(true)
    }

    // pending bitmap injection (non-standard, for bring-up)
    else if off == PLIC_OFF_PENDING_BASE then {
      plic_pending[31..0] = plic_pending[31..0] | wdata;
      plic_pending = plic_bit_clear64(plic_pending, 0);
      plic_update_mip();
      Ok(true)
    } else if off == (PLIC_OFF_PENDING_BASE + 4) then {
      plic_pending[63..32] = plic_pending[63..32] | wdata;
      plic_pending = plic_bit_clear64(plic_pending, 0);
      plic_update_mip();
      Ok(true)
    }

    // enable bitmap (ctx0=M, ctx1=S)
    else if off == PLIC_OFF_ENABLE_BASE then {
      plic_enable_m[31..0] = wdata;
      plic_enable_m = plic_bit_clear64(plic_enable_m, 0);
      plic_update_mip();
      Ok(true)
    } else if off == (PLIC_OFF_ENABLE_BASE + 4) then {
      plic_enable_m[63..32] = wdata;
      plic_enable_m = plic_bit_clear64(plic_enable_m, 0);
      plic_update_mip();
      Ok(true)
    } else if off == (PLIC_OFF_ENABLE_BASE + PLIC_ENABLE_STRIDE) then {
      plic_enable_s[31..0] = wdata;
      plic_enable_s = plic_bit_clear64(plic_enable_s, 0);
      plic_update_mip();
      Ok(true)
    } else if off == (PLIC_OFF_ENABLE_BASE + PLIC_ENABLE_STRIDE + 4) then {
      plic_enable_s[63..32] = wdata;
      plic_enable_s = plic_bit_clear64(plic_enable_s, 0);
      plic_update_mip();
      Ok(true)
    }

    // per-context threshold/complete (ctx0, ctx1)
    else if off == PLIC_OFF_CTX_BASE then {
      plic_threshold_m = wdata;
      plic_update_mip();
      Ok(true)
    } else if off == (PLIC_OFF_CTX_BASE + 4) then {
      let id = unsigned(wdata);
      if id < plic_nsrc_active & id != 0 then {
        plic_claimed = plic_bit_clear64(plic_claimed, id);
        plic_claimed = plic_bit_clear64(plic_claimed, 0);
        plic_update_mip()
      } else ();
      Ok(true)
    } else if off == (PLIC_OFF_CTX_BASE + PLIC_CTX_STRIDE) then {
      plic_threshold_s = wdata;
      plic_update_mip();
      Ok(true)
    } else if off == (PLIC_OFF_CTX_BASE + PLIC_CTX_STRIDE + 4) then {
      let id = unsigned(wdata);
      if id < plic_nsrc_active & id != 0 then {
        plic_claimed = plic_bit_clear64(plic_claimed, id);
        plic_claimed = plic_bit_clear64(plic_claimed, 0);
        plic_update_mip()
      } else ();
      Ok(true)
    }

    else Ok(true)
  }
}

private function clint_dispatch() -> unit = {
  mip[MTI] = bool_to_bit(mtimecmp <=_u mtime);
  if currentlyEnabled(Ext_Sstc) & menvcfg[STCE] == 0b1 then {
    mip[STI] = bool_to_bit(stimecmp <=_u mtime);
  };
  if get_config_print_clint()
  then print_log("clint mtime " ^ bits_str(mtime) ^ " (mip.MTI <- " ^ bits_str(mip[MTI]) ^
    (if currentlyEnabled(Ext_Sstc) then ", mip.STI <- " ^ bits_str(mip[STI]) else "") ^ ")");
}

private val clint_store: forall 'n, 'n > 0. (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
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

register htif_cmd_write : bits(1)
register htif_payload_writes : bits(4)

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
function htif_load(access, Physaddr(paddr), width) = {
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
  else    Err(accessFaultFromAccessType(access))
}

private val htif_store : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n)) -> MemoryOpResult(bool)
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
  else return Err(E_SAMO_Access_Fault());

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
  else within_clint(addr, width) | within_plic(addr, width) | (within_htif_readable(addr, width) & 1 <= 'n)

function within_mmio_writable forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> bool =
  if get_config_rvfi()
  then false
  else within_clint(addr, width) | within_plic(addr, width) | (within_htif_writable(addr, width) & 'n <= 8)

function mmio_read forall 'n, 0 < 'n <= max_mem_access .
  (access : MemoryAccessType(mem_payload), paddr : physaddr, width : int('n)) -> MemoryOpResult(bits(8 * 'n)) =
  if   within_plic(paddr, width)
  then plic_load(access, paddr, width)
  else if within_clint(paddr, width)
  then clint_load(access, paddr, width)
  else if within_htif_readable(paddr, width)
  then htif_load(access, paddr, width)
  else Err(accessFaultFromAccessType(access))

function mmio_write forall 'n, 0 < 'n <= max_mem_access .
  (paddr : physaddr, width : int('n), data: bits(8 * 'n)) -> MemoryOpResult(bool) =
  if   within_plic(paddr, width)
  then plic_store(paddr, width, data)
  else if within_clint(paddr, width)
  then clint_store(paddr, width, data)
  else if within_htif_writable(paddr, width)
  then htif_store(paddr, width, data)
  else Err(E_SAMO_Access_Fault())

// Platform initialization and ticking.

function init_platform() -> unit = {
  htif_tohost = zeros();
  htif_done   = false;
  htif_exit_code = zeros();
  htif_cmd_write = 0b0;
  htif_payload_writes = zeros();

  // --- PLIC runtime config (from Sail JSON config) ---
  let nsrc_cfg : int = unsigned(plat_plic_nsrc);
  let nctx_cfg : int = unsigned(plat_plic_nctx);

  plic_nsrc_active = clamp_int(nsrc_cfg, 1, PLIC_NSRC_MAX);
  plic_nctx_active = clamp_int(nctx_cfg, 1, PLIC_NCTX_MAX);

  // reset PLIC state
  plic_pending = zeros();
  plic_claimed = zeros();
  plic_enable_m = zeros();
  plic_enable_s = zeros();
  plic_threshold_m = zeros();
  plic_threshold_s = zeros();

  mtimecmp = zeros();
  stimecmp = zeros();
}

// Platform-specific wait-for-interrupt
function platform_wfi() -> unit = ()
