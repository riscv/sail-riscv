/* Define the XLEN value for the architecture. */

// type-level definitions
type xlen       : Int = 32
type xlen_bytes : Int = 4
type xlenbits         = bits(xlen)

// value-level definitions
let xlen : int(xlen) = 32
let xlen_bytes       = 4     // byte-width of xlen bits
