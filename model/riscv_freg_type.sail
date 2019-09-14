/* Definitions for floating point registers (F and D extensions) */

/* default register type */
type fregtype = flenbits

/* default zero register */
let zero_freg : fregtype = EXTZ(0x0)

/* default register printer */
val FRegStr : fregtype -> string
function FRegStr(r) = BitStr(r)

/* conversions */

val fregval_from_freg : fregtype -> flenbits
function fregval_from_freg(r) = r

val fregval_into_freg : flenbits -> fregtype
function fregval_into_freg(v) = v
