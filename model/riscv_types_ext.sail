/* No extensions for PTE checks */
type ext_pte_error = unit

/* No extensions for page-table-walk errors */

type ext_ptw_error = unit

/* No exception extensions */

type ext_exc_type = unit

/* Default translation of PTE checks into PTW errors */
function ext_ptw_error_of_pte_error (e : ext_pte_error) -> ext_ptw_error =
  ()

/* Default translation of PTW errors into exception annotations */
function ext_translate_exception(e : ext_ptw_error) -> ext_exc_type =
  e
