// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

let sys_smwid_nworlds : int = config extensions.Smwid.nworlds
let sys_smwid_pmwid : xlenbits = trunc(config extensions.Smwid.pmwid : bits(64))
let sys_smwid_pmwidlist : xlenbits = trunc(config extensions.Smwid.pmwidlist : bits(64))
let sys_smwid_locked_on_reset : bool = config extensions.Smwid.mwid_locked_on_reset : bool

enum SmwidUnauthorizedBehavior = {
  Smwid_Access_Fault,
  Smwid_Fatal,
}

struct SmwidWorldRegion = {
  base         : bits(64),
  size         : bits(64),
  read_wids    : bits(64),
  write_wids   : bits(64),
  execute_wids : bits(64),
  ptw_wids     : bits(64),
}

let smwid_worlds_enabled : bool = config platform.worlds.enabled : bool
let smwid_unauthorized_behavior : SmwidUnauthorizedBehavior = config platform.worlds.unauthorized_behavior
let smwid_world_regions : list(SmwidWorldRegion) = config platform.worlds.regions

function smwid_lock_mask() -> xlenbits = zero_extend(0b1) << (xlen - 1)

// The Smwid CSR uses ceil(log2(NWorlds)) bits for the WID field.
// For NWorlds == 1 the hart is fixed to a single world, so the field is empty.
function smwid_wid_width_for_nworlds(nworlds : int) -> int = {
  assert(nworlds >= 1, "Smwid requires at least one world");

  match nworlds {
    n if n <= 1  => 0,
    n if n <= 2  => 1,
    n if n <= 4  => 2,
    n if n <= 8  => 3,
    n if n <= 16 => 4,
    n if n <= 32 => 5,
    n if n <= 64 => 6,
    _            => 7,
  }
}

let sys_smwid_wid_width : int = smwid_wid_width_for_nworlds(sys_smwid_nworlds)

function smwid_wid_mask_for_width(width : int) -> xlenbits = {
  if width == 0
  then zeros()
  else if width >= xlen
  then ones()
  else (zero_extend(0b1) << width) - 1
}

function smwid_wid_mask() -> xlenbits =
  smwid_wid_mask_for_width(sys_smwid_wid_width)

function smwid_extract_wid(value : xlenbits) -> xlenbits =
  value & smwid_wid_mask()

function smwid_extract_locked(value : xlenbits) -> bool =
  value[xlen - 1] == bitone

function smwid_compose_value(wid : xlenbits, locked : bool) -> xlenbits = {
  let base = wid & smwid_wid_mask();
  if locked
  then base | smwid_lock_mask()
  else base & ~(smwid_lock_mask())
}

function smwid_authorized(wid : xlenbits) -> bool = {
  let idx = unsigned(wid);
  idx < sys_smwid_nworlds & (sys_smwid_pmwidlist >> idx)[0] == bitone
}

function smwid_wid_in_mask(mask : bits(64), wid : xlenbits) -> bool = {
  let idx = unsigned(wid);
  idx < 64 & (mask >> idx)[0] == bitone
}

function matching_smwid_world_region_bits_range(regions : list(SmwidWorldRegion), base : bits(64), size : bits(64)) -> option(SmwidWorldRegion) = {
  match regions {
    [||] => None(),
    region :: rest => {
      if range_subset(base, size, region.base, region.size)
      then Some(region)
      else matching_smwid_world_region_bits_range(rest, base, size)
    }
  }
}

function matching_smwid_world_region forall 'n, 0 < 'n <= max_mem_access . (addr : physaddr, width : int('n)) -> option(SmwidWorldRegion) =
  matching_smwid_world_region_bits_range(smwid_world_regions, zero_extend(bits_of(addr)), to_bits(width))

function smwid_region_allows_access(region : SmwidWorldRegion, access : MemoryAccessType(mem_payload), wid : xlenbits) -> bool =
  match access {
    InstructionFetch()          => smwid_wid_in_mask(region.execute_wids, wid),
    Load(Data)                  => smwid_wid_in_mask(region.read_wids, wid),
    Load(Vector)                => smwid_wid_in_mask(region.read_wids, wid),
    Store(Data)                 => smwid_wid_in_mask(region.write_wids, wid),
    Store(Vector)               => smwid_wid_in_mask(region.write_wids, wid),
    LoadReserved(Data)          => smwid_wid_in_mask(region.read_wids, wid) & smwid_wid_in_mask(region.write_wids, wid),
    StoreConditional(Data)      => smwid_wid_in_mask(region.read_wids, wid) & smwid_wid_in_mask(region.write_wids, wid),
    Atomic(_, Data, Data)       => smwid_wid_in_mask(region.read_wids, wid) & smwid_wid_in_mask(region.write_wids, wid),
    Load(ShadowStack)           => smwid_wid_in_mask(region.read_wids, wid),
    Store(ShadowStack)          => smwid_wid_in_mask(region.write_wids, wid),
    Atomic(AMOSWAP, ShadowStack, ShadowStack) => smwid_wid_in_mask(region.read_wids, wid) & smwid_wid_in_mask(region.write_wids, wid),
    Load(PageTableEntry)        => smwid_wid_in_mask(region.ptw_wids, wid),
    Store(PageTableEntry)       => smwid_wid_in_mask(region.ptw_wids, wid),
    CacheAccess(CB_zero())      => smwid_wid_in_mask(region.write_wids, wid),
    CacheAccess(CB_manage(_))   => smwid_wid_in_mask(region.read_wids, wid) | smwid_wid_in_mask(region.write_wids, wid),
    CacheAccess(CB_prefetch(p)) => match p {
      PREFETCH_R => smwid_wid_in_mask(region.read_wids, wid),
      PREFETCH_W => smwid_wid_in_mask(region.write_wids, wid),
      PREFETCH_I => smwid_wid_in_mask(region.execute_wids, wid),
    },
    LoadReserved(p) => internal_error(__FILE__, __LINE__, "Invalid payload (" ^ mem_payload_name(p) ^ ") for LoadReserved."),
    StoreConditional(p) => internal_error(__FILE__, __LINE__, "Invalid payload (" ^ mem_payload_name(p) ^ ") for StoreConditional."),
    Atomic(AMOSWAP, rp, wp) => internal_error(__FILE__, __LINE__, "Invalid payloads (" ^ mem_payload_name(rp) ^ ", " ^ mem_payload_name(wp) ^ ") for Atomic."),
    Atomic(op, ShadowStack, ShadowStack) => internal_error(__FILE__, __LINE__, "Invalid op (" ^ amo_mnemonic(op) ^ ") for ShadowStack Atomic."),
    Atomic(_, rp, wp) => internal_error(__FILE__, __LINE__, "Invalid payloads (" ^ mem_payload_name(rp) ^ ", " ^ mem_payload_name(wp) ^ ") for Atomic."),
  }

function smwid_unauthorized_access_result(access : MemoryAccessType(mem_payload), wid : xlenbits, paddr : physaddr) -> option(ExceptionType) =
  match smwid_unauthorized_behavior {
    Smwid_Access_Fault => Some(accessFaultFromAccessType(access)),
    Smwid_Fatal => internal_error(__FILE__, __LINE__,
                                  "Smwid blocked " ^ to_str(access)
                                  ^ " for WID " ^ dec_str(unsigned(wid))
                                  ^ " at physical address " ^ hex_bits_str(bits_of(paddr))),
  }

register mwid : xlenbits = zeros()

function legalize_mwid(old : xlenbits, written : xlenbits) -> xlenbits = {
  if smwid_extract_locked(old)
  then old
  else {
    let new_wid = smwid_extract_wid(written);
    let new_locked = smwid_extract_locked(written);
    smwid_compose_value(new_wid, new_locked)
  }
}

function reset_smwid() -> unit = {
  mwid = smwid_compose_value(sys_smwid_pmwid, sys_smwid_locked_on_reset);
  csr_write_callback("mwid", mwid);
}

function get_mwid_wid() -> xlenbits = smwid_extract_wid(mwid)

// Without Smwid, transactions still carry the platform-defined default WID.
// Once Smwid is enabled, the active WID comes from the mwid CSR instead.
function current_world_id_for_access(_access : MemoryAccessType(mem_payload), _priv : Privilege) -> xlenbits =
  if currentlyEnabled(Ext_Smwid)
  then get_mwid_wid()
  else smwid_extract_wid(sys_smwid_pmwid)

function smwid_access_controls_enabled(smwid_enabled : bool, worlds_enabled : bool) -> bool =
  smwid_enabled | worlds_enabled

function smwid_access_check(access : MemoryAccessType(mem_payload), wid : xlenbits, paddr : physaddr, width : mem_access_width) -> option(ExceptionType) = {
  let smwid_enabled = currentlyEnabled(Ext_Smwid);
  if not(smwid_access_controls_enabled(smwid_enabled, smwid_worlds_enabled))
  then return None();

  if smwid_enabled & not(smwid_authorized(wid))
  then return smwid_unauthorized_access_result(access, wid, paddr);

  if not(smwid_worlds_enabled)
  then return None();

  match matching_smwid_world_region(paddr, width) {
    None() => smwid_unauthorized_access_result(access, wid, paddr),
    Some(region) =>
      if smwid_region_allows_access(region, access, wid)
      then None()
      else smwid_unauthorized_access_result(access, wid, paddr),
  }
}

// The Worlds draft has not assigned a final CSR address for mwid yet.
// Use 0x7C0 as a branch-local provisional address until the draft is finalized.
mapping clause csr_name_map = 0x7C0 <-> "mwid"

function clause is_CSR_accessible(0x7C0, priv, _) = currentlyEnabled(Ext_Smwid) & priv == Machine

function clause read_CSR(0x7C0) = mwid

function clause write_CSR(0x7C0, value) = {
  mwid = legalize_mwid(mwid, value);
  csr_write_callback("mwid", mwid);
  Ok(mwid)
}
