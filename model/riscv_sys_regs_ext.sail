/* System register handling that can be overridden by extensions. */

/* the default definition when there are no extensions */
function ext_veto_disable_C () = false

/* The xepc legalization zeroes xepc[1:0] when misa.C is hardwired to 0.
 * When misa.C is writable, it zeroes only xepc[0].
 */
function legalize_xepc(v : xlenbits) -> xlenbits =
  /* allow writing xepc[1] only if misa.C is enabled or could be enabled */
  if   (sys_enable_writable_misa() & sys_enable_rvc()) | misa.C() == 0b1
  then [v with 0 = bitzero]
  else v & EXTS(0b100)

