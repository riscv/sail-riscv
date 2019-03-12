/* *****************************************************************/
/* This file specifies the instruction added by the 'N' extension. */

union clause ast = URET : unit

mapping clause encdec = URET()
  <-> 0b0000000 @ 0b00010 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute URET() = {
  if   (~ (haveUsrMode()))
  then handle_illegal()
  else nextPC = handle_exception(cur_privilege, CTL_URET(), PC);
  false
}

mapping clause assembly = URET() <-> "uret"
