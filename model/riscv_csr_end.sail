/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

mapping clause csr_name_map = reg <-> hex_bits_12(reg)
end csr_name_map

function clause is_CSR_defined(_) = false
end is_CSR_defined

function clause read_CSR(csr) = {
   // This should be impossible because is_CSR_defined() should have returned false.
   internal_error(__FILE__, __LINE__, "Read from CSR that does not exist: " ^ bits_str(csr));
}
end read_CSR

function clause write_CSR(csr, _) = {
   // This should be impossible because is_CSR_defined() should have returned false.
   internal_error(__FILE__, __LINE__, "Write to CSR that does not exist: " ^ bits_str(csr));
}
end write_CSR
