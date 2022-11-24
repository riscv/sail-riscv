register ELEN : bits(1)

val get_elen : unit -> {|32, 64|}

function get_elen() = match ELEN {
    0b0 => 32,
    0b1 => 64
}

let elen = get_elen()

register VLEN : bits(4)

val get_vlen : unit -> {|32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536|}

function get_vlen() = match VLEN {
    0b0000 => 32,
    0b0001 => 64,
    0b0010 => 128,
    0b0011 => 256,
    0b0100 => 512,
    0b0101 => 1024,
    0b0110 => 2048,
    0b0111 => 4096,
    0b1000 => 8192,
    0b1001 => 16384,
    0b1010 => 32768,
    _      => 65536
}

let vlen = get_vlen()

val vlen_bytes : unit -> {|4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192|}

function vlen_bytes() = match VLEN {
    0b0000 => 4,
    0b0001 => 8,
    0b0010 => 16,
    0b0011 => 32,
    0b0100 => 64,
    0b0101 => 128,
    0b0110 => 256,
    0b0111 => 512,
    0b1000 => 1024,
    0b1001 => 2048,
    0b1010 => 4096,
    _      => 8192
}

/* to determine the length of vstart csr */
val get_vstart_length : unit -> {|5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16|}

function get_vstart_length() = match VLEN {
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

let vstart_length = get_vstart_length()

type vlenmax : Int = 65536
