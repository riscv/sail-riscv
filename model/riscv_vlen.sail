type elen : Int = 64

register VLEN : bits(2)

val get_vlen : unit -> {|64, 128, 256, 512|}

function get_vlen() = match VLEN {
    0b00 => 64,
    0b01 => 128,
    0b10 => 256,
    0b11 => 512
}

let vlen = get_vlen()

val vlen_bytes : unit -> {|8, 16, 32, 64|}

function vlen_bytes() = match VLEN {
    0b00 => 8,
    0b01 => 16,
    0b10 => 32,
    0b11 => 64
}

/* to determine the length of vstart csr */
val get_vstart_length : unit -> {|6, 7, 8, 9|}

function get_vstart_length() = match VLEN {
    0b00 => 6,
    0b01 => 7,
    0b10 => 8,
    0b11 => 9
}

let vstart_length = get_vstart_length()

type vlenmax : Int = 512
