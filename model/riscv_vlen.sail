/* Define the VLEN value for the architecture. */

type vlen       : Int = 128 /*256 OR 512 bits*/
type vlen_bytes : Int = 16 /*32 or 64 bytes*/
type vstart_int     : Int = 8 /*2**8=256(vlen bits) 0~255*/      
type vstartbits = bits(vstart_int)

type elen       : Int = 64
