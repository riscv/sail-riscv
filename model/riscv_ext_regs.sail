/* This file contains register handling functions that can be
 * overridden by extensions.
 */

val ext_init_regs : unit -> unit effect {wreg}
function ext_init_regs () = ()
