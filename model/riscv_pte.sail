/* PTE attributes, permission checks and updates */

type pteAttribs = bits(8)

/* Reserved PTE bits could be used by extensions on RV64.  There are
 * no such available bits on RV32, so these bits will be zeros on RV32.
 */
type extPte = bits(10)

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

function isPTEPtr(p : pteAttribs, ext : extPte) -> bool = {
  let a = Mk_PTE_Bits(p);
  a.R() == false & a.W() == false & a.X() == false
}

function isInvalidPTE(p : pteAttribs, ext : extPte) -> bool = {
  let a = Mk_PTE_Bits(p);
  a.V() == false | (a.W() == true & a.R() == false)
}

function checkPTEPermission(ac : AccessType(ext_access_type), priv : Privilege, mxr : bool, do_sum : bool, p : PTE_Bits, ext : extPte) -> bool = {
  match (ac, priv) {
    (Read(Data),      User)       => p.U() == true & (p.R() == true | (p.X() == true & mxr)),
    (Write(Data),     User)       => p.U() == true & p.W() == true,
    (ReadWrite(Data), User)       => p.U() == true & p.W() == true & (p.R() == true | (p.X() == true & mxr)),
    (Execute(),       User)       => p.U() == true & p.X() == true,

    (Read(Data),      Supervisor) => (p.U() == false | do_sum) & (p.R() == true | (p.X() == true & mxr)),
    (Write(Data),     Supervisor) => (p.U() == false | do_sum) & p.W() == true,
    (ReadWrite(Data), Supervisor) => (p.U() == false | do_sum) & p.W() == true & (p.R() == true | (p.X() == true & mxr)),
    (Execute(),       Supervisor) => p.U() == false & p.X() == true,

    (_,               Machine)    => internal_error("m-mode mem perm check")
  }
}

function update_PTE_Bits(p : PTE_Bits, a : AccessType(ext_access_type), ext : extPte) -> option((PTE_Bits, extPte)) = {
  let update_d = (a == Write(Data) | a == ReadWrite(Data)) & p.D() == false; // dirty-bit
  let update_a = p.A() == false;                                             // accessed-bit
  if update_d | update_a then {
    let np = update_A(p, true);
    let np = if update_d then update_D(np, true) else np;
    Some(np, ext)
  } else None()
}
