/* Shared definitions for supervisor-mode page-table-entries and permission checks.
 *
 * These definitions are independent of xlen and do not involve
 * accessing physical memory.
 */

/* PageSize */

let PAGESIZE_BITS = 12

/* PTE attributes, permission checks and updates */

type pteAttribs = bits(8)

bitfield PTE_Bits : pteAttribs = {
  D : 7,
  A : 6,
  G : 5,
  U : 4,
  X : 3,
  W : 2,
  R : 1,
  V : 0
}

function isPTEPtr(p : pteAttribs) -> bool = {
  let a = Mk_PTE_Bits(p);
  a.R() == false & a.W() == false & a.X() == false
}

function isInvalidPTE(p : pteAttribs) -> bool = {
  let a = Mk_PTE_Bits(p);
  a.V() == false | (a.W() == true & a.R() == false)
}

function checkPTEPermission(ac : AccessType, priv : Privilege, mxr : bool, do_sum : bool, p : PTE_Bits) -> bool = {
  match (ac, priv) {
    (Read,      User)       => p.U() == true & (p.R() == true | (p.X() == true & mxr)),
    (Write,     User)       => p.U() == true & p.W() == true,
    (ReadWrite, User)       => p.U() == true & p.W() == true & (p.R() == true | (p.X() == true & mxr)),
    (Execute,   User)       => p.U() == true & p.X() == true,

    (Read,      Supervisor) => (p.U() == false | do_sum) & (p.R() == true | (p.X() == true & mxr)),
    (Write,     Supervisor) => (p.U() == false | do_sum) & p.W() == true,
    (ReadWrite, Supervisor) => (p.U() == false | do_sum) & p.W() == true & (p.R() == true | (p.X() == true & mxr)),
    (Execute,   Supervisor) => p.U() == false & p.X() == true,

    (_,         Machine)    => internal_error("m-mode mem perm check")
  }
}

function update_PTE_Bits(p : PTE_Bits, a : AccessType) -> option(PTE_Bits) = {
  let update_d = (a == Write | a == ReadWrite) & p.D() == false; // dirty-bit
  let update_a = p.A() == false;                                 // accessed-bit
  if update_d | update_a then {
    let np = update_A(p, true);
    let np = if update_d then update_D(np, true) else np;
    Some(np)
  } else None()
}

/* failure modes for address-translation/page-table-walks */
enum PTW_Error = {
  PTW_Access,       /* physical memory access error for a PTE */
  PTW_Invalid_PTE,
  PTW_No_Permission,
  PTW_Misaligned,   /* misaligned superpage */
  PTW_PTE_Update    /* PTE update needed but not enabled */
}
val cast ptw_error_to_str : PTW_Error -> string
function ptw_error_to_str(e) =
  match (e) {
    PTW_Access        => "mem-access-error",
    PTW_Invalid_PTE   => "invalid-pte",
    PTW_No_Permission => "no-permission",
    PTW_Misaligned    => "misaligned-superpage",
    PTW_PTE_Update    => "pte-update-needed"
  }

/* conversion of these translation/PTW failures into architectural exceptions */
function translationException(a : AccessType, f : PTW_Error) -> ExceptionType = {
  let e : ExceptionType =
  match (a, f) {
    (ReadWrite, PTW_Access) => E_SAMO_Access_Fault,
    (ReadWrite, _)          => E_SAMO_Page_Fault,
    (Read, PTW_Access)      => E_Load_Access_Fault,
    (Read, _)               => E_Load_Page_Fault,
    (Write, PTW_Access)     => E_SAMO_Access_Fault,
    (Write, _)              => E_SAMO_Page_Fault,
    (Fetch, PTW_Access)     => E_Fetch_Access_Fault,
    (Fetch, _)              => E_Fetch_Page_Fault
  } in {
/*  print("translationException(" ^ a ^ ", " ^ f ^ ") -> " ^ e); */
    e
  }
}

/*
 * Definitions for RV32, which has a single address translation mode: Sv32.
 */

type vaddr32 = bits(32)
type paddr32 = bits(34)
type pte32   = bits(32)

/* result of address translation */
union TR32_Result = {
  TR32_Address : paddr32,
  TR32_Failure : PTW_Error
}

/* asid */
type asid32 = bits(9)

function curAsid32(satp : bits(32)) -> asid32 = {
  let s = Mk_Satp32(satp);
  s.Asid()
}

/* page table base from satp */
function curPTB32(satp : bits(32)) -> paddr32 = {
  let s : Satp32 = Mk_Satp32(satp);
  shiftl(EXTZ(s.PPN()), PAGESIZE_BITS)
}

/* Sv32 parameters and bitfield layouts */

let SV32_LEVEL_BITS = 9
let SV32_LEVELS     = 2
let PTE32_LOG_SIZE  = 2
let PTE32_SIZE      = 4

bitfield SV32_Vaddr : vaddr32 = {
  VPNi  : 31 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV32_Paddr : paddr32 = {
  PPNi  : 33 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV32_PTE : pte32 = {
  PPNi  : 31 .. 10,
  RSW   : 9  .. 8,
  BITS  : 7  .. 0
}

/*
 * Definitions for RV64, which has two defined address translation modes: Sv39 and Sv48.
 */

/* Sv48 and Sv64 are reserved but not defined.  The size of the VPN
 * increases by 9 bits through Sv39, Sv48 and Sv57, but not for Sv64.
 * Also, the 45-bit size of the VPN for Sv57 exceeds the 44-bit size
 * of the PPN in satp64.  Due to these corner cases, it is unlikely
 * that definitions can be shared across all four schemes, so separate
 * definitions might eventually be needed for each translation mode.
 *
 * But to keep things simple for now, since Sv39 and Sv48 have the
 * same PPN size, we share some definitions.
 */

type paddr64 = bits(56)
type pte64   = bits(64)

/* result of address translation */
union TR64_Result = {
  TR64_Address : paddr64,
  TR64_Failure : PTW_Error
}

/* asid */

type asid64 = bits(16)

function curAsid64(satp : bits(64)) -> asid64 = {
  let s = Mk_Satp64(satp);
  s.Asid()
}

/* page table base from satp */
function curPTB64(satp : bits(64)) -> paddr64 = {
  let s = Mk_Satp64(satp);
  shiftl(EXTZ(s.PPN()), PAGESIZE_BITS)
}

/* Sv39 parameters and bitfield layouts */

let SV39_LEVEL_BITS = 9
let SV39_LEVELS     = 3
let PTE39_LOG_SIZE  = 3
let PTE39_SIZE      = 8

type vaddr39 = bits(39)

bitfield SV39_Vaddr : vaddr39 = {
  VPNi  : 38 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV39_Paddr : paddr64 = {
  PPNi  : 55 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV39_PTE : pte64 = {
  PPNi  : 53 .. 10,
  RSW   : 9  .. 8,
  BITS  : 7  .. 0
}

/* Sv48 parameters and bitfield layouts */

let SV48_LEVEL_BITS = 9
let SV48_LEVELS     = 4
let PTE48_LOG_SIZE  = 3
let PTE48_SIZE      = 8

type vaddr48 = bits(48)
type pte48   = bits(64)

bitfield SV48_Vaddr : vaddr48 = {
  VPNi  : 38 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV48_Paddr : paddr64 = {
  PPNi  : 55 .. 12,
  PgOfs : 11 .. 0
}

bitfield SV48_PTE : pte48 = {
  PPNi  : 53 .. 10,
  RSW   : 9  .. 8,
  BITS  : 7  .. 0
}

/* Result of a page-table walk. */

union PTW_Result = {
  PTW_Success: (paddr64, SV39_PTE, paddr64, nat, bool),
  PTW_Failure: PTW_Error
}

/* idealized TLB to model fence.vm and also speed up simulation. */

struct TLB39_Entry = {
  asid : asid64,
  global : bool,
  vAddr : vaddr39,      /* VPN */
  pAddr : paddr64,      /* PPN */
  vMatchMask : vaddr39, /* matching mask for superpages */
  vAddrMask : vaddr39,  /* selection mask for superpages */
  pte : SV39_PTE,       /* permissions */
  pteAddr : paddr64,    /* for dirty writeback */
  age : xlenbits
}

/* the rreg effect is an artifact of using the cycle counter to provide the age */
val make_TLB39_Entry : (asid64, bool, vaddr39, paddr64, SV39_PTE, nat, paddr64) -> TLB39_Entry effect {rreg}

function make_TLB39_Entry(asid, global, vAddr, pAddr, pte, level, pteAddr) = {
  let shift : nat = PAGESIZE_BITS + (level * SV39_LEVEL_BITS);
  /* fixme hack: use a better idiom for masks */
  let vAddrMask : vaddr39 = shiftl(vAddr ^ vAddr ^ EXTZ(0b1), shift) - 1;
  let vMatchMask : vaddr39 = ~ (vAddrMask);
  struct {
    asid = asid,
    global = global,
    pte = pte,
    pteAddr = pteAddr,
    vAddrMask = vAddrMask,
    vMatchMask = vMatchMask,
    vAddr = vAddr & vMatchMask,
    pAddr = shiftl(shiftr(pAddr, shift), shift),
    age = mcycle
  }
}

/* TODO: make this a vector or array of entries */
register tlb39 : option(TLB39_Entry)

val lookupTLB39 : (asid64, vaddr39) -> option((int, TLB39_Entry)) effect {rreg}
function lookupTLB39(asid, vaddr) = {
  match tlb39 {
    None()  => None(),
    Some(e) => if  (e.global | (e.asid == asid))
                 & (e.vAddr == (e.vMatchMask & vaddr))
               then Some((0, e))
               else None()
  }
}

val addToTLB39 : (asid64, vaddr39, paddr64, SV39_PTE, paddr64, nat, bool) -> unit effect {wreg, rreg}
function addToTLB39(asid, vAddr, pAddr, pte, pteAddr, level, global) = {
  let ent = make_TLB39_Entry(asid, global, vAddr, pAddr, pte, level, pteAddr);
  tlb39   = Some(ent)
}

function writeTLB39(idx : int, ent : TLB39_Entry) -> unit =
  tlb39 = Some(ent)

val flushTLB : (option(asid64), option(vaddr39)) -> unit effect {rreg, wreg}
function flushTLB(asid, addr) = {
  let ent : option(TLB39_Entry) =
    match (tlb39, asid, addr) {
      (None(),       _,      _)   => None(),
      (Some(e), None(), None())   => None(),
      (Some(e), None(), Some(a))  => if e.vAddr == (e.vMatchMask & a)
                                     then None() else Some(e),
      (Some(e), Some(i), None())  => if (e.asid == i) & (~ (e.global))
                                     then None() else Some(e),
      (Some(e), Some(i), Some(a)) => if (e.asid == i) & (e.vAddr == (a & e.vMatchMask))
                                        & (~ (e.global))
                                     then None() else Some(e)
    };
  tlb39 = ent
}

