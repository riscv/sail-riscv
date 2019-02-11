/* Define the XLEN value for the architecture. */

// type-level definitions
type xlen : Int = 64
type xlenbits   = bits(xlen)

// value-level definitions
let xlen_val       = 64
let xlen_val_bytes = 8      // byte-width of xlen bits
