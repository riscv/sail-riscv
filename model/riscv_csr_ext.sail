
/* numeric fallback XXX apparent sail bug prevents this from compiling for C  */
//mapping clause csr_name_map = reg <-> "UNKNOWN CSR: " ^ hex_bits_12(reg)
end csr_name_map

function clause ext_is_CSR_defined(_, _) = false
end ext_is_CSR_defined

function clause ext_read_CSR _ = None()
end ext_read_CSR

function clause ext_write_CSR (_, _) = None()
end ext_write_CSR
