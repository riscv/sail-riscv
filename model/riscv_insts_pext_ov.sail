/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation, Taiwan*/

/* *****************************************************************/

/* where is subextension Zpsfoperand configured? */
/* vxsat register */

bitfield Vxsat : xlenbits = {
  OV    : 0
}

register vxsat : Vxsat

function havePExt()    -> bool = misa.P() == 0b1
function haveVExt()    -> bool = misa.V() == 0b1

/* TODO: P sub-extensions */
function haveZpsfoperand() -> bool = true
function haveZprvsfextra() -> bool = true
function haveZpn()         -> bool = true

val pext_write_OV : bits(1) -> unit effect {rreg, wreg}
function pext_write_OV (b) =
  if haveVExt () then
    /* TODO: use vxsat from RVV */
    vxsat->OV() = b
  else
    vxsat->OV() = b

val pext_read_OV : unit -> xlenbits effect {rreg}
function pext_read_OV () =
  if haveVExt () then
    /* TODO: use vxsat from RVV */
    EXTZ (vxsat.OV ())
  else
    EXTZ (vxsat.OV())

mapping clause csr_name_map = 0x009 <-> "vxsat"

function clause ext_is_CSR_defined(0x009, _) = havePExt()

function clause ext_read_CSR(0x009) = Some(pext_read_OV ())

function clause ext_write_CSR(0x009, value) = {
  pext_write_OV (0b0); Some(vxsat.bits())
}
