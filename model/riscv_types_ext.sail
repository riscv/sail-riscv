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

/* Default conversion of extension exceptions to bits */
val ext_exc_type_to_bits : ext_exc_type -> exc_code
function ext_exc_type_to_bits(e) = 0x18 /* First code for a custom extension */

/* Default conversion of extension exceptions to integers */
val num_of_ext_exc_type : ext_exc_type -> {'n, (0 <= 'n < xlen). int('n)}
function num_of_ext_exc_type(e) = 24 /* First code for a custom extension */

/* Default conversion of extension exceptions to strings */
val ext_exc_type_to_str : ext_exc_type -> string
function ext_exc_type_to_str(e) = "extension-exception"
