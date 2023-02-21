register elen : bits(1)

val get_elen : unit -> {|32, 64|} effect {rreg}

function get_elen() = match elen {
    0b0 => 32,
    0b1 => 64
}

register vlen : bits(4)

val get_vlen_pow : unit -> {|5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16|} effect {rreg}

function get_vlen_pow() = match vlen {
    0b0000 => 5,
    0b0001 => 6,
    0b0010 => 7,
    0b0011 => 8,
    0b0100 => 9,
    0b0101 => 10,
    0b0110 => 11,
    0b0111 => 12,
    0b1000 => 13,
    0b1001 => 14,
    0b1010 => 15,
    _      => 16
}

type vlenmax : Int = 65536
