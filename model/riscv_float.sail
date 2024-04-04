// ---------------------------------------------------------------------------

// Split a floating point bitvec up into its sign, exponent, mantissa parts.
val fsplit : forall 'n, 'n in {16, 32, 64}.
  bits('n) -> (
    bits(1),
    bits(if 'n == 16 then 5 else (if 'n == 32 then 8 else 11)),
    bits(if 'n == 16 then 10 else (if 'n == 32 then 23 else 52)),
  )
function fsplit(x) = {
  if      'n == 16 then (x[15..15], x[14..10], x[9..0])
  else if 'n == 32 then (x[31..31], x[30..23], x[22..0])
  else                  (x[63..63], x[62..52], x[51..0])
}

// Join sign, exponent, mantissa parts back into a single bit vector.
val fmake : forall 'e, 'e in {5, 8, 11}.
  (
    bits(1),
    bits('e),
    bits(if 'e == 5 then 10 else (if 'e == 8 then 23 else 52)),
  ) -> bits(if 'e == 5 then 16 else (if 'e == 8 then 32 else 64))
function fmake(sign, exp, mant) = sign @ exp @ mant

// ---------------------------------------------------------------------------
// Floating point property functions.

// Bit vector type for floating points - restricted to f16, f32, f64.
type fbits = { 'n, 'n in {16, 32, 64}. bits('n) }

function f_is_neg_inf(x : fbits) -> bool = {
  let (sign, exp, mant) = fsplit(x);
  (  (sign == 0b1)
   & (exp  == ones())
   & (mant == zeros()))
}

function f_is_neg_norm(x : fbits) -> bool = {
  let (sign, exp, mant) = fsplit(x);
  (  (sign == 0b1)
   & (exp  != zeros())
   & (exp  != ones()))
}

function f_is_neg_subnorm(x : fbits) -> bool = {
  let (sign, exp, mant) = fsplit(x);
  (  (sign == 0b1)
   & (exp  == zeros())
   & (mant != zeros()))
}

function f_is_neg_zero(x : fbits) -> bool = {
  let (sign, exp, mant) = fsplit(x);
  (  (sign == ones())
   & (exp  == zeros())
   & (mant == zeros()))
}

function f_is_pos_zero(x : fbits) -> bool = {
  let (sign, exp, mant) = fsplit(x);
  (  (sign == zeros())
   & (exp  == zeros())
   & (mant == zeros()))
}

function f_is_pos_subnorm(x : fbits) -> bool = {
  let (sign, exp, mant) = fsplit(x);
  (  (sign == zeros())
   & (exp  == zeros())
   & (mant != zeros()))
}

function f_is_pos_norm(x : fbits) -> bool = {
  let (sign, exp, mant) = fsplit(x);
  (  (sign == zeros())
   & (exp  != zeros())
   & (exp  != ones()))
}

function f_is_pos_inf(x : fbits) -> bool = {
  let (sign, exp, mant) = fsplit(x);
  (  (sign == zeros())
   & (exp  == ones())
   & (mant == zeros()))
}

function f_is_SNaN(x : fbits) -> bool = {
  let (sign, exp, 'mant) = fsplit(x);
  (  (exp == ones())
   & (mant['mant - 1] == bitzero)
   & (mant != zeros()))
}

function f_is_QNaN(x : fbits) -> bool = {
  let (sign, exp, 'mant) = fsplit(x);
  (  (exp == ones())
   & (mant['mant - 1] == bitone))
}

// Either QNaN or SNan
function f_is_NaN(x : fbits) -> bool = {
  let (sign, exp, mant) = fsplit(x);
  (  (exp == ones())
   & (mant != zeros()))
}

// ---------------------------------------------------------------------------

// Negation (invert the sign bit which is always the top bit).
val      f_negate : forall 'n, 'n in {16, 32, 64}. bits('n) -> bits('n)
function f_negate(x) = ~(x['n - 1 .. 'n - 1]) @ x['n - 2 .. 0]
