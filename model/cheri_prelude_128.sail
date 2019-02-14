/*========================================================================*/
/*                                                                        */
/*  Copyright (c) 2015-2017 Robert M. Norton                              */
/*  Copyright (c) 2015-2017 Kathyrn Gray                                  */
/*  All rights reserved.                                                  */
/*                                                                        */
/*  This software was developed by the University of Cambridge Computer   */
/*  Laboratory as part of the Rigorous Engineering of Mainstream Systems  */
/*  (REMS) project, funded by EPSRC grant EP/K008528/1.                   */
/*                                                                        */
/*  Redistribution and use in source and binary forms, with or without    */
/*  modification, are permitted provided that the following conditions    */
/*  are met:                                                              */
/*  1. Redistributions of source code must retain the above copyright     */
/*     notice, this list of conditions and the following disclaimer.      */
/*  2. Redistributions in binary form must reproduce the above copyright  */
/*     notice, this list of conditions and the following disclaimer in    */
/*     the documentation and/or other materials provided with the         */
/*     distribution.                                                      */
/*                                                                        */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''    */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A       */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR   */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,          */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT      */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF      */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND   */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,    */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT    */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF    */
/*  SUCH DAMAGE.                                                          */
/*========================================================================*/

type CapBits = bits(128)
let max_otype = MAX(18)

/*
A partially decompressed version of a capability -- E, B, T,
lenMSB, sealed and otype fields are not present in all formats and are
populated by capBitsToCapability
 */
struct Capability = {
  tag                    : bool    ,
  uperms                 : bits(4) ,
  permit_set_CID         : bool    ,
  access_system_regs     : bool    ,
  permit_unseal          : bool    ,
  permit_ccall           : bool    ,
  permit_seal            : bool    ,
  permit_store_local_cap : bool    ,
  permit_store_cap       : bool    ,
  permit_load_cap        : bool    ,
  permit_store           : bool    ,
  permit_load            : bool    ,
  permit_execute         : bool    ,
  global                 : bool    ,
  reserved               : bits(3) ,
  internal_e             : bool    ,
  E                      : bits(6) ,
  sealed                 : bool    ,
  B                      : bits(14),
  T                      : bits(14),
  otype                  : bits(18),
  address                : bits(64)
}

/* Reset E and T calculated to make top 2**64. */
let resetE = to_bits(6, 52)
let resetT = 0b01 @ 0x000 /* bit 12 set */

let null_cap : Capability = struct {
  tag                    = false,
  uperms                 = zeros(),
  permit_set_CID         = false,
  access_system_regs     = false,
  permit_unseal          = false,
  permit_ccall           = false,
  permit_seal            = false,
  permit_store_local_cap = false,
  permit_store_cap       = false,
  permit_load_cap        = false,
  permit_store           = false,
  permit_load            = false,
  permit_execute         = false,
  global                 = false,
  reserved               = zeros(),
  internal_e             = true,
  E                      = resetE,
  sealed                 = false,
  B                      = zeros(),
  T                      = resetT,
  otype                  = ones(),
  address                = zeros()
}

let default_cap : Capability = struct {
  tag                    = true,
  uperms                 = ones(),
  permit_set_CID         = true,
  access_system_regs     = true,
  permit_unseal          = true,
  permit_ccall           = true,
  permit_seal            = true,
  permit_store_local_cap = true,
  permit_store_cap       = true,
  permit_load_cap        = true,
  permit_store           = true,
  permit_load            = true,
  permit_execute         = true,
  global                 = true,
  reserved               = zeros(),
  internal_e             = true,
  E                      = resetE,
  sealed                 = false,
  B                      = zeros(),
  T                      = resetT,
  otype                  = ones(),
  address                = zeros()
}

let 'cap_size = 16

/*
Convert from capabilty bits (128 bits with tag) to a more convenient struct.
 */
function capBitsToCapability(t, c) : (bool, CapBits) -> Capability = {
  internal_exponent : bool = c[90];
  otype : bits(18) = c[108..91];
  let sealed : bool = otype != ones();
  E : bits(6)  = zeros();
  Bs : bits(14) = zeros();
  T : bits(12) = zeros();
  lenMSBs : bits(2) = zeros();
  if internal_exponent then {
    /* Exponent stored instead of T[2..0] and B[2..0] */
    E = c[80..78] @ c [66..64];
    /* Exponent chosen so that length MSBs is 01 */
    lenMSBs = 0b01;
    T = c[89..81] @ 0b000;
    Bs = c[77..67] @ 0b000;
  } else {
    /* Exponent zero */
    lenMSBs = 0b00;
    T = c[89..78];
    Bs = c[77..64];
  };
  /* 
  Reconstruct top two bits of T given T = B + len and:
  1) the top two bits of B 
  2) most significant two bits of length derived from format above
  3) carry out of B[20..0] + len[20..0] that is implied if T[20..0] < B[20..0]
  */
  carry_out = if T <_u Bs[11..0] then 0b01 else 0b00;
  Ttop2 = Bs[13..12] + lenMSBs + carry_out;
  return struct {
    tag                    = t,
    uperms                 = c[127..124],
    permit_set_CID         = c[123],
    access_system_regs     = c[122],
    permit_unseal          = c[121],
    permit_ccall           = c[120],
    permit_seal            = c[119],
    permit_store_local_cap = c[118],
    permit_store_cap       = c[117],
    permit_load_cap        = c[116],
    permit_store           = c[115],
    permit_load            = c[114],
    permit_execute         = c[113],
    global                 = c[112],
    reserved               = c[111..109],
    internal_e             = internal_exponent,
    E                      = E,
    sealed                 = sealed,
    B                      = Bs,
    T                      = Ttop2 @ T,
    otype                  = otype,
    address                = c[63..0]
  }
}

function getCapHardPerms(cap) : Capability -> bits(12) =
   (cap.permit_set_CID
  @ cap.access_system_regs
  @ cap.permit_unseal
  @ cap.permit_ccall
  @ cap.permit_seal
  @ cap.permit_store_local_cap
  @ cap.permit_store_cap
  @ cap.permit_load_cap
  @ cap.permit_store
  @ cap.permit_load
  @ cap.permit_execute
  @ cap.global)

/*
Convert from capabilty struct to bits (128 -- no tag) 
 */
function capToBits(cap) : Capability -> bits(128) = {
  t_hi : bits(9)  = cap.T[11..3];
  t_lo : bits(3)  = cap.T[2..0];
  b_hi : bits(11) = cap.B[13..3];
  b_lo : bits(3)  = cap.B[2..0];
  if cap.internal_e then {
    t_lo = cap.E[5..3];
    b_lo = cap.E[2..0];
  };
  return (cap.uperms
    @ getCapHardPerms(cap)
    @ cap.reserved
    @ cap.otype
    @ cap.internal_e
    @ t_hi
    @ t_lo
    @ b_hi
    @ b_lo
    @ cap.address
  );
}
 
/* When saving/restoring capabilities xor them with bits of null_cap --
   this ensures that canonical null_cap is always all-zeros in memory
   even though it may have bits set logically (e.g. length or exponent */

let null_cap_bits : bits(128) = capToBits(null_cap)

function capToMemBits(cap) : Capability -> bits(128) =
  capToBits(cap) ^ null_cap_bits

function memBitsToCapability(tag, b) : (bool, bits(128)) -> Capability =
  capBitsToCapability(tag, b ^ null_cap_bits)

function getCapPerms(cap) : Capability -> bits(31) = 
    let perms : bits(15) = zero_extend(getCapHardPerms(cap)) in
    (0x000 /* uperms 30-19 */
  @ cap.uperms
  @ perms)

function setCapPerms(cap, perms) : (Capability, bits(31)) -> Capability =
    { cap with
      uperms                 = perms[18..15],
      /* 14..12 reserved -- ignore */
      permit_set_CID         = perms[11],
      access_system_regs     = perms[10],
      permit_unseal          = perms[9],
      permit_ccall           = perms[8],
      permit_seal            = perms[7],
      permit_store_local_cap = perms[6],
      permit_store_cap       = perms[5],
      permit_load_cap        = perms[4],
      permit_store           = perms[3],
      permit_load            = perms[2],
      permit_execute         = perms[1],
      global                 = perms[0]
      }

function sealCap(cap, otyp) : (Capability, bits(24)) -> (bool, Capability) =
    (true, {cap with sealed=true, otype=otyp[17..0]})

function unsealCap(cap) : Capability -> Capability =
    {cap with sealed=false, otype=ones()}

function a_top_correction(a_mid, R, bound) : (bits(3), bits(3), bits(3)) -> bits(65) =
    match (a_mid <_u R, bound <_u R) {
      (false, false)  => zeros(),
      (false, true)   => zero_extend(0b1),
      (true, false)   => ones(),
      (true, true)    => zeros()
    }

function getCapBounds(c) : Capability -> (uint64, CapLen) = {
  let E = unsigned(c.E) in
  let a : bits(65) = zero_extend(c.address) in
  /* Extract bits we need to make the top correction and calculate representable limit */
  let a3 = truncate(a >> (E + 11), 3) in
  let B3 = truncateLSB(c.B, 3) in
  let T3 = truncateLSB(c.T, 3) in
  let R3 = B3 - 0b001 in /* wraps */
  let correction_base = a_top_correction(a3, R3, B3) in
  let correction_top  = a_top_correction(a3, R3, T3) in
  let a_top = (a >> E+14) in
  let e_zeros = zeros(E) in
  let base : bits(64) = truncate((a_top + correction_base) @ c.B @ e_zeros, 64) in
  let top  : bits(65) = truncate((a_top + correction_top)  @ c.T @ e_zeros, 65) in
  (unsigned(base), unsigned(top))
}

function getCapBase(c) : Capability -> uint64 =
    let (base, _) = getCapBounds(c) in
    base

function getCapTop (c) : Capability -> CapLen =
    let (_, top) = getCapBounds(c) in
    top

function getCapOffset(c) : Capability -> uint64 = 
    let base = getCapBase(c) in
    (unsigned(c.address) - base) % pow2(64)

function getCapLength(c) : Capability -> CapLen =
    let ('base, 'top) = getCapBounds(c) in {
        /* For valid capabilties we expect top >= base and hence
           length >= 0 but representation does allow top < base in some 
           cases so might encounter on untagged capabilities. Here we just 
           pretend it is a 65-bit quantitiy and wrap. */
        assert (not(c.tag) | top >= base);
        (top - base) % pow2(65)
    }

function getCapCursor(cap) : Capability -> uint64 = unsigned(cap.address)

/*
function fastRepCheck(c, i) : (Capability, bits(64)) -> bool=
    let 'E = unsigned(c.E) in
    if (E >= resetE) then
        true /* in this case representable region is whole address space */
    else
        let E'       = min(E, resetE) in
        let i_top    = signed(i >>_s (E+23)) in
        let i_mid : bits(23) = truncate(i >>_s E)in
        let a_mid : bits(23) = truncate(c.address >> E) in
        let R : bits(20)     = (c.B) - 0x01000 in
        let diff : bits(20)  = R - a_mid in
        let diff1 : bits(20) = diff - 1 in
        /* i_top determines 1. whether the increment is inRange
           i.e. less than the size of the representable region
           (2**(E+20)) and 2. whether it is positive or negative. To
           satisfy 1. all top bits must be the same so we are
           interested in the cases i_top is 0 or -1 */
        if (i_top == 0) then
          i_mid <_u diff1
        else if (i_top == -1) then
          (i_mid >=_u diff) & (R != a_mid)
        else
          false
*/

function capBoundsEqual (c1, c2) : (Capability, Capability) -> bool =
    let (base1, top1) = getCapBounds(c1) in
    let (base2, top2) = getCapBounds(c2) in
    (base1 == base2) & (top1 == top2)

function setCapOffset(c, offset) : (Capability, bits(64)) -> (bool, Capability) =
    let base64 : bits(64) = to_bits(64, getCapBase(c)) in
    let newAddress : bits(64) = base64 + offset in
    let newCap     = { c with address = newAddress } in
    let representable = capBoundsEqual(c, newCap) in
/*    let representable = fastRepCheck(c, (newAddress - c.address)) in*/
    (representable, newCap)

function incCapOffset(c, delta) : (Capability, bits(64)) -> (bool, Capability) =
    let newAddress : bits(64) = c.address + delta in
    let newCap     = { c with address = newAddress } in
    let representable = capBoundsEqual(c, newCap) in
/*    let representable = fastRepCheck(c, delta) in*/
    (representable, newCap)

val CountLeadingZeros : forall 'N , 'N >= 2. bits('N) -> {'n, 0 <= 'n <= 'N . atom('n)}
function CountLeadingZeros x = {
  foreach (i from ('N - 1) to 0 by 1 in dec)
    if [x[i]] == 0b1 then return 'N - i - 1;
  return 'N;
}

/* 
An 'ideal' version of setCapBounds as described in paper.
 */
function setCapBounds(cap, base, top) : (Capability, bits(64), bits(65)) -> (bool, Capability) = {
  /* {cap with base=base; length=(bits(64)) length; offset=0} */
  let base65 = 0b0 @ base;
  let length = top - base65;
  /* Find an exponent that will put the most significant bit of length 
     second from the top as assumed during decoding. We ignore the bottom
     MW - 1 bits because those are handled by the ie = 0 format. */
  let e = 52 - CountLeadingZeros(length[64..13]);
  // Use use internal exponent if e is non-zero or if e is zero but
  // but the implied bit of length is not zero (denormal vs. normal case)
  let ie = (e != 0) | length[12];

  /* The non-ie e == 0 case is easy. It is exact so just extract relevant bits. */
  Bbits = truncate(base, 14);
  Tbits = truncate(top, 14);
  lostSignificantTop : bool = false;
  lostSignificantBase : bool = false;
  incE : bool = false;
  
  if ie then {
    /* the internal exponent case is trickier */

    /* Extract B and T bits (we lose 3 bits of each to store the exponent) */
    B_ie = truncate(base >> (e + 3), 11);
    T_ie = truncate(top >> (e + 3), 11);
    
    /* Find out whether we have lost significant bits of base and top using a
       mask of bits that we will lose (including 3 extra for exp). */
    maskLo : bits(65) = zero_extend(replicate_bits(0b1, e + 3));
    z65    : bits(65) = zeros();
    lostSignificantBase = (base65 & maskLo) != z65;
    lostSignificantTop = (top & maskLo) != z65;

    if lostSignificantTop then {
      /* we must increment T to make sure it is still above top even with lost bits.
         It might wrap around but if that makes B<T then decoding will compensate. */
      T_ie = T_ie + 1;
    };

    /* Has the length overflowed? We chose e so that the top two bits of len would be 0b01,
       but either because of incrementing T or losing bits of base it might have grown. */
    len_ie = T_ie - B_ie;
    if len_ie[10] then {
      /* length overflow -- increment E by one and then recalculate 
         T, B etc accordingly */
      incE = true;

      lostSignificantBase = lostSignificantBase | B_ie[0];
      lostSignificantTop  = lostSignificantTop | T_ie[0];
      
      B_ie = truncate(base >> (e + 4), 11);
      let incT : range(0,1) = if lostSignificantTop then 1 else 0;
      T_ie = truncate(top >> (e + 4), 11) + incT;
    };

    Bbits = B_ie @ 0b000;
    Tbits = T_ie @ 0b000;
  };
  let newCap = {cap with address=base, E=to_bits(6, if incE then e + 1 else e), B=Bbits, T=Tbits, internal_e=ie};
  let exact = not(lostSignificantBase | lostSignificantTop);
  (exact, newCap)
}

function int_to_cap (offset) : bits(64) -> Capability = 
    {null_cap with address = offset}

val checkCP2usable : unit -> unit
function checkCP2usable () = ()
