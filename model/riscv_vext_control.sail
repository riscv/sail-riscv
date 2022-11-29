function clause ext_is_CSR_defined (0x008, _) = true
function clause ext_is_CSR_defined (0xC20, _) = true
function clause ext_is_CSR_defined (0xC21, _) = true
function clause ext_is_CSR_defined (0xC22, _) = true

function clause ext_is_CSR_defined (0x009, _) = true
function clause ext_is_CSR_defined (0x00A, _) = true
function clause ext_is_CSR_defined (0x00F, _) = true

function clause ext_read_CSR (0x009) = Some (EXTZ (vcsr.vxsat()))
function clause ext_read_CSR (0x00A) = Some (EXTZ (vcsr.vxrm()))
function clause ext_read_CSR (0x00F) = Some (EXTZ (vcsr.bits()))

function clause ext_read_CSR (0x009) = Some (EXTZ (vcsr.vxsat()))
function clause ext_read_CSR (0x00A) = Some (EXTZ (vcsr.vxrm()))
function clause ext_read_CSR (0x00F) = Some (EXTZ (vcsr.bits()))

function clause ext_write_CSR (0x009, value) = { ext_write_vcsr (vcsr.vxrm(), value[0 .. 0]); Some(EXTZ(vcsr.vxsat())) }
function clause ext_write_CSR (0x00A, value) = { ext_write_vcsr (value[1 .. 0], vcsr.vxsat()); Some(EXTZ(vcsr.vxrm())) }
function clause ext_write_CSR (0x00F, value) = { ext_write_vcsr (value [2 .. 1], value [0 .. 0]); Some(EXTZ(vcsr.bits())) }
