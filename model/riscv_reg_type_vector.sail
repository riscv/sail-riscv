type vreglen             : Int=vlen /*type vlen       : Int = 128 256 OR 512 bits*/
type vreglenbits         = bits(vreglen)/*Each vector register has a fixed VLEN bits of state*/

type vregtype            = vreglenbits

val VRegStr : vregtype -> string
function VRegStr(r) = BitStr(r)