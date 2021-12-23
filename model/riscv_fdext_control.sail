/* **************************************************************** */
/* Floating point register file and accessors for F, D extensions   */
/* Floating point CSR and accessors                                 */
/* **************************************************************** */

/* Original version written by Rishiyur S. Nikhil, Sept-Oct 2019    */

/* **************************************************************** */

/* val clause ext_is_CSR_defined : (csreg, Privilege) -> bool effect {rreg} */

function clause ext_is_CSR_defined (0x001, _) = haveFExt() | haveDExt()
function clause ext_is_CSR_defined (0x002, _) = haveFExt() | haveDExt()
function clause ext_is_CSR_defined (0x003, _) = haveFExt() | haveDExt()

function clause ext_read_CSR (0x001) = Some (EXTZ (fcsr.FFLAGS()))
function clause ext_read_CSR (0x002) = Some (EXTZ (fcsr.FRM()))
function clause ext_read_CSR (0x003) = Some (EXTZ (fcsr.bits()))

function clause ext_write_CSR (0x001, value) = { ext_write_fcsr (fcsr.FRM(), value [4..0]); Some(EXTZ(fcsr.FFLAGS())) }
function clause ext_write_CSR (0x002, value) = { ext_write_fcsr (value [2..0], fcsr.FFLAGS()); Some(EXTZ(fcsr.FRM())) }
function clause ext_write_CSR (0x003, value) = { ext_write_fcsr (value [7..5], value [4..0]); Some(EXTZ(fcsr.bits())) }

/* **************************************************************** */
