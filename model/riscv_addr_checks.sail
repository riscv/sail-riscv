/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* default fetch address checks */

type ext_fetch_addr_error = unit

/* Since fetch is done in granules, the check function gets two arguments:
 * start_pc: the PC at the start of the current fetch sequence
 * pc:       the PC for the current granule
 *
 * returns:  an optional fetch error.
 */
function ext_fetch_check_pc(start_pc : xlenbits, pc : xlenbits) -> option(ext_fetch_addr_error) =
  None()

function ext_handle_fetch_check_error(err : ext_fetch_addr_error) -> unit =
  ()

/* default control address checks */

type ext_control_addr_error = unit

/* This function returns an optional exception for the address to use
 * as the target for the control transfer. The control address is
 * derived from the PC register, e.g. in JAL.
 *
 * NOTE: the input value does *not* have bit[0] set to 0, to enable
 * more accurate bounds checking.
 */

function ext_control_check_pc(pc : xlenbits) -> option(ext_control_addr_error) =
  None()

function ext_handle_control_check_error(err : ext_control_addr_error) -> unit =
  ()


/* The default data address function does not perform any checks so
   just uses unit for error type. */
type ext_data_addr_error = unit

/* Default data addr is just base register + immediate offset (may be zero).
   Extensions might override and add additional checks. */
function ext_data_get_addr(base : regidx, offset : xlenbits, acc : AccessType(ext_access_type), width : mem_access_width)
         -> Ext_DataAddr_Check(ext_data_addr_error) =
  let addr = Virtaddr(X(base) + offset) in
  Ext_DataAddr_OK(addr)

function ext_handle_data_check_error(err : ext_data_addr_error) -> unit =
  ()
