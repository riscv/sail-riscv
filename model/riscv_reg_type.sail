/* default register type */
type regtype = xlenbits

/* default zero register */
let zero_reg : regtype = EXTZ(0x0)

/* default register printer */
val RegStr : regtype -> string
function RegStr(r) = BitStr(r)

/* conversions */

val regval_from_reg : regtype -> xlenbits
function regval_from_reg(r) = r

val regval_into_reg : xlenbits -> regtype
function regval_into_reg(v) = v
