// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

mapping clause csr_name_map = reg <-> hex_bits_12(reg)
end csr_name_map

function clause is_CSR_accessible(_) = false
end is_CSR_accessible

function clause read_CSR(csr) = {
   // This should be impossible because is_CSR_accessible() should have returned false.
   internal_error(__FILE__, __LINE__, "Read from CSR that does not exist: " ^ bits_str(csr));
}
end read_CSR

function clause write_CSR(csr, _) = {
   // This should be impossible because is_CSR_accessible() should have returned false.
   internal_error(__FILE__, __LINE__, "Write to CSR that does not exist: " ^ bits_str(csr));
}
end write_CSR

// Implements the general HS-qualified rule from the H extension spec.
// If an access fails in VS/VU mode but would succeed in HS mode, raise a
// virtual instruction exception instead of an illegal instruction exception.
// CSRs that deviate from this rule have explicit clauses defined.
function clause is_CSR_exception_virtual(csr, _, access_type) = check_CSR(csr, Supervisor, access_type) == CSR_Check_OK()
end is_CSR_exception_virtual

termination_measure is_CSR_exception_virtual(_, _, _) = 1
