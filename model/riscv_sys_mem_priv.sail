/*
 * Compute the effective memory access privilege as a pure function of...
 *
 *  - The memory access type being made, including any extension's annotation
 *
 *  - The value of Mstatus
 *
 *  - The current privilege level
 *
 */
function ext_effectiveMemoryPrivilege(t : AccessType(ext_access_type), m : Mstatus, priv : Privilege) -> Privilege =
  if   t != Execute() & m.MPRV() == 0b1
  then privLevel_of_bits(m.MPP())
  else priv
