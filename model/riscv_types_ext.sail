/* accumulator for information collected during PTW */

/* This type is an accumulator; it is carried through the page-table
 * walk, and folds in information along the walk, currently from the
 * PTE checks from each PTE that is processed along the way.
 */
type ext_ptw = unit  /* No extensions for page-table-walks */

let init_ext_ptw : ext_ptw = () /* initial value of the accumulator */

/* This type can be used for custom errors for page-table-walks,
 * and values in this type are typically generated from the final
 * result of the ext_ptw at the end of the walk.
 */
type ext_ptw_error = unit /* No extensions for page-table-walk errors */

/* This type supports extensions to the exceptions defined in the ISA. */
type ext_exc_type = unit /* No exception extensions */

/* Default translation of PTW errors into exception annotations */
function ext_translate_exception(e : ext_ptw_error) -> ext_exc_type =
  e
