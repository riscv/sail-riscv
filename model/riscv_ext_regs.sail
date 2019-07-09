/* This file contains register handling functions that can be
 * overridden by extensions.
 */

val ext_init_regs : unit -> unit effect {wreg}
function ext_init_regs () = ()

/*!
This function is called after above when running rvfi and allows the model
to be initialised differently (e.g. CHERI cap regs are initialised
to omnipotent instead of null).
 */
val ext_rvfi_init : unit -> unit effect {wreg}
function ext_rvfi_init () = ()
