/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* PTE attributes, permission checks and updates */


/* Extension hooks can request standard PTE validity checks by returning Ext_PTE_Std
 */
union Ext_isInvalPTE_Check = {
  Ext_PTE_Invalid : unit,
  Ext_PTE_Valid   : unit,
  Ext_PTE_Std    : unit
}

type pteAttribs = bits(8)

/* Reserved PTE bits could be used by standard extensions on RV64.  There are
 * no such available bits on RV32, so these bits will be zeros on RV32.
 */
type pteStdExtAttribs = bits(10)

bitfield PTE_StdExt_Bits : pteStdExtAttribs = {
  N    : 9,
  PBMT : 8 .. 7,
  RSVD : 6 .. 0
}

/*
 * On SV32, there are no reserved bits available to extensions.  Therefore, by
 * default, we initialize the PTE extension field with all zeros.  However,
 * extensions may wish, on SV39/48/56, to put flags in the reserved region of
 * those PTEs.  To avoid the need for "inhibit" bits in extensions (i.e., so
 * that extensions can use the more common and more RISC-V flavored "enable"
 * disposition), we allow extensions to use any constant value by overriding
 * this default_sv32_pte_std_ext_attribs value.
 */
let default_sv32_pte_std_ext_attribs : pteStdExtAttribs = zeros()

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

function ext_isInvalidPTE (p : pteAttribs, std_ext : pteStdExtAttribs) -> Ext_isInvalPTE_Check =
  Ext_PTE_Std()

function isPTEPtr(p : pteAttribs, std_ext : pteStdExtAttribs) -> bool = {
  let a = Mk_PTE_Bits(p);
  a[R] == 0b0 & a[W] == 0b0 & a[X] == 0b0
}

function isInvalidPTE(p : pteAttribs, std_ext : pteStdExtAttribs) -> bool = {
  let a = Mk_PTE_Bits(p);
  let e = Mk_PTE_StdExt_Bits(std_ext);
  match ext_isInvalidPTE (p , std_ext) {
    Ext_PTE_Invalid() => true,
    Ext_PTE_Valid()   => false,
    Ext_PTE_Std()    => {
      a[V] == 0b0 |
      (a[W] == 0b1 & a[R] == 0b0) |
      (e[RSVD] != 0b0000000 | e[PBMT] == 0b11) |
      (not(isPTEPtr(p, std_ext)) & (e[N] != 0b0 ) & (not(haveSvnapot()))) |
      (not(isPTEPtr(p, std_ext)) & (e[PBMT] != 0b00) & (not(haveSvpbmt()) | menvcfg[PBMTE] == 0b0)) |
      (isPTEPtr(p, std_ext) & (a[D] == 0b1 | a[A] == 0b1 | a[U] == 0b1 | e[N] != 0b0 | e[PBMT] != 0b00))
    }
  }
}

union PTE_Check = {
  PTE_Check_Success : ext_ptw,
  PTE_Check_Failure : (ext_ptw, ext_ptw_fail)
}

function to_pte_check(b : bool) -> PTE_Check =
  if b then PTE_Check_Success(()) else PTE_Check_Failure((), ())

/* For extensions: this function gets the extension-available bits of the PTE in std_ext,
 * and the accumulated information of the page-table-walk in ext_ptw.  It should return
 * the updated ext_ptw in both the success and failure cases.
 */
function checkPTEPermission(ac : AccessType(ext_access_type), priv : Privilege, mxr : bool, do_sum : bool, p : PTE_Bits, std_ext : pteStdExtAttribs, ext_ptw : ext_ptw) -> PTE_Check = {
  match (ac, priv) {
    (Read(_),         User)       => to_pte_check(p[U] == 0b1 & (p[R] == 0b1 | (p[X] == 0b1 & mxr))),
    (Write(_),        User)       => to_pte_check(p[U] == 0b1 & p[W] == 0b1),
    (ReadWrite(_, _), User)       => to_pte_check(p[U] == 0b1 & p[W] == 0b1 & (p[R] == 0b1 | (p[X] == 0b1 & mxr))),
    (Execute(),       User)       => to_pte_check(p[U] == 0b1 & p[X] == 0b1),

    (Read(_),         Supervisor) => to_pte_check((p[U] == 0b0 | do_sum) & (p[R] == 0b1 | (p[X] == 0b1 & mxr))),
    (Write(_),        Supervisor) => to_pte_check((p[U] == 0b0 | do_sum) & p[W] == 0b1),
    (ReadWrite(_, _), Supervisor) => to_pte_check((p[U] == 0b0 | do_sum) & p[W] == 0b1 & (p[R] == 0b1 | (p[X] == 0b1 & mxr))),
    (Execute(),       Supervisor) => to_pte_check(p[U] == 0b0 & p[X] == 0b1),

    (_,               Machine)    => internal_error(__FILE__, __LINE__, "m-mode mem perm check")
  }
}

function update_PTE_Bits(p : PTE_Bits, a : AccessType(ext_access_type), std_ext : pteStdExtAttribs) -> option((PTE_Bits, pteStdExtAttribs)) = {
  let update_d = p[D] == 0b0 & (match a {                                       // dirty-bit
                                  Execute() => false,
                                  Read() => false,
                                  Write(_) => true,
                                  ReadWrite(_,_) => true
                                });

  let update_a = p[A] == 0b0;                                                   // accessed-bit
  if update_d | update_a then {
    let np = update_A(p, 0b1);
    let np = if update_d then update_D(np, 0b1) else np;
    Some(np, std_ext)
  } else None()
}
