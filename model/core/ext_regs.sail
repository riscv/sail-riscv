// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================


// This file contains register handling functions that can be
// overridden by extensions.

/*!
THIS(csrno, priv, isWrite) allows an extension to block access to csrno,
at Privilege level priv. It should return true if the access is allowed.
*/
function ext_check_CSR(_csrno : csreg, _p : Privilege, _access_type : CSRAccessType) -> bool = true

/*!
THIS is called if ext_check_CSR returns false. It should
cause an appropriate RISCV exception.
 */
function ext_check_CSR_fail() -> unit = ()
