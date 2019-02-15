/* Define the XLEN value for the architecture. */

// type-level definitions
type xlen       : Int = 64
type xlen_bytes : Int = 8
type xlenbits         = bits(xlen)

// value-level definitions
let xlen : int(xlen)  = 64
let xlen_bytes        = 8    // byte-width of xlen bits
