// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// RISC-V Worlds: the World-ID extensions Smwid, Smlwid, Smlwidlist,
// Smwiddeleg and Sswid (https://github.com/riscv/riscv-worlds).
//
// Every memory access initiated by the hart is tagged with a World
// Identifier (WID).  The WID is determined by the effective privilege
// mode of the access:
//
//   M-mode:               mwid (Smwid), otherwise the platform-defined pmwid
//   S-mode:               mlwid (Smlwid), otherwise the WID of M-mode
//   modes lower than S:   slwid (Sswid, enabled when mwiddeleg != 0),
//                         otherwise as for S-mode
//
// The platform constrains the WIDs that can be used: pmwidlist for mwid,
// pmlwidlist for mlwid (further restricted by mlwidlist with Smlwidlist),
// and mwiddeleg for slwid.  An access with an unauthorized WID raises a
// software-check exception with xtval set to the illegal world fault code.
//
// The model does not model WID-based permission checks on physical
// addresses, which are performed outside the hart in the bus fabric.

// Platform parameters

// NWorlds, the number of WIDs.  All Worlds extensions support at most XLEN worlds.
let worlds_nworlds : range(1, 64) = config platform.worlds.nworlds

// The platform-defined WID of M-mode (pmwid) and the reset value of mwid.
let worlds_pmwid : range(0, 63) = config platform.worlds.pmwid

// Bit vector of the WIDs that may be used with mwid (pmwidlist).
let worlds_pmwidlist : xlenbits = trunc(config platform.worlds.pmwidlist : bits(64))

// Bit vector of the WIDs that may be used with mlwid (pmlwidlist).
let worlds_pmlwidlist : xlenbits = trunc(config platform.worlds.pmlwidlist : bits(64))

// Bit vector of the WIDs that may be delegated to S-mode via mwiddeleg.
let worlds_delegatable_wids : xlenbits = trunc(config platform.worlds.delegatable_wids : bits(64))

// Whether mwid is locked out of reset.
let worlds_mwid_locked_on_reset : bool = config extensions.Smwid.mwid_locked_on_reset

// The reset value of mlwid (unspecified by the specification).
let worlds_mlwid_reset_value : range(0, 63) = config extensions.Smlwid.mlwid_reset_value

// The WID field of the mwid, mlwid and slwid CSRs occupies the least
// significant ceil(log2(NWorlds)) bits.
function worlds_wid_width() -> range(0, 6) =
  if worlds_nworlds <= 1 then 0
  else if worlds_nworlds <= 2 then 1
  else if worlds_nworlds <= 4 then 2
  else if worlds_nworlds <= 8 then 3
  else if worlds_nworlds <= 16 then 4
  else if worlds_nworlds <= 32 then 5
  else 6

// Mask of the WID field.
function worlds_wid_mask() -> xlenbits = (zero_extend(0b1) << worlds_wid_width()) - 1

// Mask of the bits of a WID bit vector (mlwidlist, mwiddeleg) that
// correspond to the NWorlds WIDs; higher bits are read-only zero.
function worlds_list_mask() -> xlenbits =
  if worlds_nworlds >= xlen then ones() else (zero_extend(0b1) << worlds_nworlds) - 1

// Whether WID `wid` is present in the WID bit vector `list`.
function worlds_wid_in_list(list : xlenbits, wid : xlenbits) -> bool = {
  let i = unsigned(wid);
  i < worlds_nworlds & (list >> i)[0] == bitone
}

// Extension enables

function clause currentlyEnabled(Ext_Smwid) = hartSupports(Ext_Smwid) & currentlyEnabled(Ext_Zicsr)
function clause currentlyEnabled(Ext_Smlwid) = hartSupports(Ext_Smlwid) & currentlyEnabled(Ext_Zicsr)
function clause currentlyEnabled(Ext_Smlwidlist) = hartSupports(Ext_Smlwidlist) & currentlyEnabled(Ext_Smwid) & currentlyEnabled(Ext_Smlwid)
function clause currentlyEnabled(Ext_Smwiddeleg) = hartSupports(Ext_Smwiddeleg) & currentlyEnabled(Ext_Smlwid) & currentlyEnabled(Ext_S)

// CSRs

// mwid: WID of M-mode (WARL, in the WID field) and a sticky lock bit L at
// MXLEN-1.  The remaining bits are reserved and read-only zero.
register mwid : xlenbits

// mlwid: WID of the privilege modes lower than M (WARL, in the WID field).
register mlwid : xlenbits

// mlwidlist: bit vector of the WIDs that may be used with mlwid, a WARL
// subset of pmlwidlist.  Read-only whenever mwid is locked.
register mlwidlist : xlenbits

// mwiddeleg: bit vector of the WIDs delegated to S-mode, a WARL subset of
// the delegatable WIDs, of pmlwidlist and of mlwidlist (if implemented).
register mwiddeleg : xlenbits

// slwid: WID of the privilege modes lower than S (WARL, in the WID field).
register slwid : xlenbits

// "If mwiddeleg is zero ..., the Sswid extension is disabled, in which case
// any accesses to the slwid CSR raise an illegal instruction exception.
// Otherwise, if mwiddeleg is non-zero, the Sswid extension is enabled."
function clause currentlyEnabled(Ext_Sswid) = currentlyEnabled(Ext_Smwiddeleg) & mwiddeleg != zeros()

function mwid_lock_mask() -> xlenbits = zero_extend(0b1) << (xlen - 1)

function mwid_is_locked() -> bool = currentlyEnabled(Ext_Smwid) & (mwid & mwid_lock_mask()) != zeros()

// "Once the mwid CSR is locked (by setting L to 1), any attempt to write to
// the CSR is ignored."
function legalize_mwid(o : xlenbits, v : xlenbits) -> xlenbits =
  if mwid_is_locked() then o else v & (worlds_wid_mask() | mwid_lock_mask())

function legalize_lower_wid(v : xlenbits) -> xlenbits = v & worlds_wid_mask()

// "The mlwidlist mask is WARL such that any attempts to enable a WID in the
// mask that is not enabled in the platform's pmlwidlist will be overriden."
// "The mlwidlist CSR is locked (read-only) whenever mwid is locked."
function legalize_mlwidlist(o : xlenbits, v : xlenbits) -> xlenbits =
  if mwid_is_locked() then o else v & worlds_pmlwidlist & worlds_list_mask()

// "mwiddeleg is always a subset of mlwidlist (if Smlwidlist is enabled) and
// pmlwidlist (if implemented by the platform)."  The set of worlds that can
// be delegated to S-mode is also platform-specific.
function legalize_mwiddeleg(v : xlenbits) -> xlenbits =
  v & worlds_delegatable_wids & worlds_pmlwidlist & worlds_list_mask()
    & (if currentlyEnabled(Ext_Smlwidlist) then mlwidlist else ones())

mapping clause csr_name_map = 0x749  <-> "mwid"
mapping clause csr_name_map = 0x390  <-> "mlwid"
mapping clause csr_name_map = 0x74A  <-> "mlwidlist"
mapping clause csr_name_map = 0x748  <-> "mwiddeleg"
mapping clause csr_name_map = 0x190  <-> "slwid"

function clause is_CSR_accessible(0x749, _, _) = currentlyEnabled(Ext_Smwid)
function clause is_CSR_accessible(0x390, _, _) = currentlyEnabled(Ext_Smlwid)
function clause is_CSR_accessible(0x74A, _, _) = currentlyEnabled(Ext_Smlwidlist)
function clause is_CSR_accessible(0x748, _, _) = currentlyEnabled(Ext_Smwiddeleg)
// "The Sswid extension is not available to a guest OS."
function clause is_CSR_accessible(0x190, p, _) = currentlyEnabled(Ext_Sswid) & p != VirtualSupervisor & p != VirtualUser

function clause read_CSR(0x749) = mwid
function clause read_CSR(0x390) = mlwid
function clause read_CSR(0x74A) = mlwidlist
function clause read_CSR(0x748) = mwiddeleg
function clause read_CSR(0x190) = slwid

function clause write_CSR(0x749, value) = { mwid = legalize_mwid(mwid, value); Ok(mwid) }
function clause write_CSR(0x390, value) = { mlwid = legalize_lower_wid(value); Ok(mlwid) }
function clause write_CSR(0x74A, value) = {
  mlwidlist = legalize_mlwidlist(mlwidlist, value);
  // "if mlwidlist is updated, any WIDs that are de-authorized (set to zero)
  // will be implicitly de-authorized in mwiddeleg also."
  if currentlyEnabled(Ext_Smwiddeleg) then {
    mwiddeleg = mwiddeleg & mlwidlist;
    csr_write_callback("mwiddeleg", mwiddeleg);
  };
  Ok(mlwidlist)
}
function clause write_CSR(0x748, value) = { mwiddeleg = legalize_mwiddeleg(value); Ok(mwiddeleg) }
function clause write_CSR(0x190, value) = { slwid = legalize_lower_wid(value); Ok(slwid) }

function reset_worlds() -> unit = {
  // "On-reset, the mwid CSR is expected to show the platform-defined pmwid
  // value. The mwid CSR may already be locked immediately out of reset"
  mwid = to_bits(worlds_pmwid) | (if worlds_mwid_locked_on_reset then mwid_lock_mask() else zeros());
  mlwid = to_bits(worlds_mlwid_reset_value);
  // "On-reset, the mlwidlist CSR is required to show the platform-defined
  // pmlwidlist value."
  mlwidlist = worlds_pmlwidlist & worlds_list_mask();
  // "On reset, mwiddeleg is zero and hence Sswid is disabled."
  mwiddeleg = zeros();
  slwid = zeros();
  if hartSupports(Ext_Smwid) then csr_write_callback("mwid", mwid);
  if hartSupports(Ext_Smlwid) then csr_write_callback("mlwid", mlwid);
  if hartSupports(Ext_Smlwidlist) then csr_write_callback("mlwidlist", mlwidlist);
  if hartSupports(Ext_Smwiddeleg) then {
    csr_write_callback("mwiddeleg", mwiddeleg);
    csr_write_callback("slwid", slwid);
  };
}

// WID of accesses

// The WID of M-mode accesses.
function worlds_machine_wid() -> xlenbits =
  if currentlyEnabled(Ext_Smwid) then mwid & worlds_wid_mask() else to_bits(worlds_pmwid)

// The WID associated with memory accesses made at the given effective
// privilege mode.  VS and VU modes are treated as modes lower than S.
function worlds_wid_of_privilege(p : Privilege) -> xlenbits =
  match p {
    Machine    => worlds_machine_wid(),
    Supervisor => if currentlyEnabled(Ext_Smlwid) then mlwid else worlds_machine_wid(),
    _          => if currentlyEnabled(Ext_Sswid) then slwid
                  else if currentlyEnabled(Ext_Smlwid) then mlwid
                  else worlds_machine_wid(),
  }

// Whether the WID of M-mode accesses is authorized by the platform.
// "Assigning a WID value to mwid that is not enabled by that pmwidlist mask
// will result in the hart raising an exception."
function worlds_machine_wid_authorized() -> bool =
  worlds_wid_in_list(worlds_pmwidlist, worlds_machine_wid())

// Whether the WID in mlwid is authorized by the platform (pmlwidlist) and
// by M-mode (mlwidlist, if Smlwidlist is enabled).
function worlds_mlwid_authorized() -> bool = {
  let list = worlds_pmlwidlist & (if currentlyEnabled(Ext_Smlwidlist) then mlwidlist else ones());
  worlds_wid_in_list(list, mlwid)
}

// Whether the WID associated with memory accesses made at the given
// effective privilege mode is authorized.
function worlds_wid_authorized(p : Privilege) -> bool =
  match p {
    Machine    => worlds_machine_wid_authorized(),
    Supervisor => if currentlyEnabled(Ext_Smlwid) then worlds_mlwid_authorized() else worlds_machine_wid_authorized(),
    _          => if currentlyEnabled(Ext_Sswid) then worlds_wid_in_list(mwiddeleg, slwid)
                  else if currentlyEnabled(Ext_Smlwid) then worlds_mlwid_authorized()
                  else worlds_machine_wid_authorized(),
  }

// Check that a memory access made at the given effective privilege mode is
// tagged with an authorized WID.  If it is not, a software-check exception
// is raised: "When this exception is raised, the mtval register is set to
// "illegal world fault (code=4)". The software-check exception caused by
// Smlwid has higher priority than any access-fault exception".
function worlds_access_check(p : Privilege) -> option(ExceptionContext) =
  if not(currentlyEnabled(Ext_Smwid) | currentlyEnabled(Ext_Smlwid)) | worlds_wid_authorized(p)
  then None()
  else Some(make_instr_exception_context(E_Software_Check(), sw_check_code_to_bits(ILLEGAL_WORLD_FAULT)))
