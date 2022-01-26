/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation*/

/* *****************************************************************/

/* where is subextension Zpsfoperand configured? */
/* vxsat register */

bitfield Vxsat : xlenbits = {
  OV    : 0
}

register vxsat : Vxsat


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
function pext_read_OV() =
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

/*
union clause ast = PEXT_OV : (regidx, p_ov_op)

mapping encdec_p_ov_op : p_ov_op <-> bits(8) = {
  CLROV <-> 0b00001111,
  RDOV  <-> 0b00000010
}

mapping clause encdec = PEXT_OV(rd, op)  <-> 0b000000001001 @ encdec_p_ov_op(op) @ rd @ 0b1110011

function clause execute PEXT_OV(rd, op) = {
  let isWrite : bool = match op {
    CLROV  => true,
    RDOV   => false
  };

  let csr_val = pext_read_OV(); 
  if isWrite then {
    pext_write_OV (0b0)
  };
  
  X(rd) = csr_val;
  RETIRE_SUCCESS
}


mapping p_ov_mnemonic : p_ov_op <-> string = {
  CLROV <-> "clrov",
  RDOV <->  "rdov"
}

mapping clause assembly = PEXT_OV(rd, op)
  <-> p_ov_mnemonic(op) ^ reg_name(rd)
  */
