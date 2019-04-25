/* default fetch address checks */

type ext_fetch_addr_error = unit

/* Since fetch is done in granules, the check function gets two arguments:
 * start_pc: the PC at the start of the current fetch sequence
 * pc:       the PC for the current granule
 *
 * returns:  the *virtual* memory address to use for the fetch.
 *           any address translation errors are reported for pc, not the returned value.
 */
function ext_fetch_check_pc(start_pc : xlenbits, pc : xlenbits) -> Ext_FetchAddr_Check(ext_fetch_addr_error) =
  Ext_FetchAddr_OK(pc)

function ext_handle_fetch_check_error(err : ext_fetch_addr_error) -> unit =
  ()

/* default control address checks */

type ext_control_addr_error = unit

/* these functions return the address to use as the target for
 * the control transfer.  any address translation or other errors
 * are reported for the original value, not the returned value.
 *
 * NOTE: the input value does *not* have bit[0] set to 0, to enable
 * more accurate bounds checking.  There is no constraint on the output
 * value, which will have bit[0] cleared by the caller if needed.
 */

/* the control address is derived from a non-PC register, e.g. in JALR */
function ext_control_check_addr(pc : xlenbits) -> Ext_ControlAddr_Check(ext_control_addr_error) =
  Ext_ControlAddr_OK(pc)

/* the control address is derived from the PC register, e.g. in JAL */
function ext_control_check_pc(pc : xlenbits) -> Ext_ControlAddr_Check(ext_control_addr_error) =
  Ext_ControlAddr_OK(pc)

function ext_handle_control_check_error(err : ext_control_addr_error) -> unit =
  ()

/* default data address checks */
type ext_data_addr_error = unit

function ext_data_check_addr(addr : xlenbits, acc : AccessType, rt : ReadType, width : word_width)
         -> Ext_DataAddr_Check(ext_data_addr_error) =
  Ext_DataAddr_OK(addr)

function ext_handle_data_check_error(err : ext_data_addr_error) -> unit =
  ()

/* accessors for default architectural addresses, for use from within instructions */
/* FIXME: these don't really belong in this file. */
/* FIXME: see note in cheri_addr_checks.sail */

val get_next_pc : unit -> xlenbits effect {rreg}
function get_next_pc() = nextPC

val set_next_pc : xlenbits -> unit effect {wreg}
function set_next_pc(pc) = {
  nextPC = pc
}

val tick_pc : unit -> unit effect {rreg, wreg}
function tick_pc() = {
  PC = nextPC
}
