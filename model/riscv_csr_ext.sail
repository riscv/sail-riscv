/* Extensions may want to add additional CSR registers to the CSR address map.
 * These functions support access to such registers.
 *
 * The default implementation provides access to the CSRs added by the 'N'
 * extension.
 */

/* returns whether a CSR is defined and accessible at a given address
 * and privilege
 */
function ext_is_CSR_defined(csr : csreg, p : Privilege) -> bool =
  is_NExt_CSR_defined(csr, p)   // 'N' extension

/* returns the value of the CSR if it is defined */
function ext_read_CSR(csr : csreg) -> option(xlenbits) =
  read_NExt_CSR(csr)

/* returns false if the CSR is not defined or if the write is unsuccessful */
function ext_write_CSR(csr : csreg, value : xlenbits) -> bool =
  write_NExt_CSR(csr, value)
