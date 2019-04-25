/* Some helper functions for the assembler mappings. */

/* Python:
f = """val hex_bits_{0} : bits({0}) <-> string
val hex_bits_{0}_forwards = "decimal_string_of_bits" : bits({0}) -> string
val hex_bits_{0}_forwards_matches : bits({0}) -> bool
function hex_bits_{0}_forwards_matches bv = true
val "hex_bits_{0}_matches_prefix" : string -> option((bits({0}), nat))
val hex_bits_{0}_backwards_matches : string -> bool
function hex_bits_{0}_backwards_matches s = match s {{
  s if match hex_bits_{0}_matches_prefix(s) {{
    Some (_, n) if n == string_length(s) => true,
    _ => false
  }} => true,
  _ => false
}}
val hex_bits_{0}_backwards : string -> bits({0})
function hex_bits_{0}_backwards s =
  match hex_bits_{0}_matches_prefix(s) {{
      Some (bv, n) if n == string_length(s) => bv
  }}
"""

for i in list(range(1, 34)) + [48, 64]:
  print(f.format(i))

*/
val hex_bits_1 : bits(1) <-> string
val hex_bits_1_forwards = "decimal_string_of_bits" : bits(1) -> string
val hex_bits_1_forwards_matches : bits(1) -> bool
function hex_bits_1_forwards_matches bv = true
val "hex_bits_1_matches_prefix" : string -> option((bits(1), nat))
val hex_bits_1_backwards_matches : string -> bool
function hex_bits_1_backwards_matches s = match s {
  s if match hex_bits_1_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_1_backwards : string -> bits(1)
function hex_bits_1_backwards s =
  match hex_bits_1_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_2 : bits(2) <-> string
val hex_bits_2_forwards = "decimal_string_of_bits" : bits(2) -> string
val hex_bits_2_forwards_matches : bits(2) -> bool
function hex_bits_2_forwards_matches bv = true
val "hex_bits_2_matches_prefix" : string -> option((bits(2), nat))
val hex_bits_2_backwards_matches : string -> bool
function hex_bits_2_backwards_matches s = match s {
  s if match hex_bits_2_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_2_backwards : string -> bits(2)
function hex_bits_2_backwards s =
  match hex_bits_2_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_3 : bits(3) <-> string
val hex_bits_3_forwards = "decimal_string_of_bits" : bits(3) -> string
val hex_bits_3_forwards_matches : bits(3) -> bool
function hex_bits_3_forwards_matches bv = true
val "hex_bits_3_matches_prefix" : string -> option((bits(3), nat))
val hex_bits_3_backwards_matches : string -> bool
function hex_bits_3_backwards_matches s = match s {
  s if match hex_bits_3_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_3_backwards : string -> bits(3)
function hex_bits_3_backwards s =
  match hex_bits_3_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_4 : bits(4) <-> string
val hex_bits_4_forwards = "decimal_string_of_bits" : bits(4) -> string
val hex_bits_4_forwards_matches : bits(4) -> bool
function hex_bits_4_forwards_matches bv = true
val "hex_bits_4_matches_prefix" : string -> option((bits(4), nat))
val hex_bits_4_backwards_matches : string -> bool
function hex_bits_4_backwards_matches s = match s {
  s if match hex_bits_4_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_4_backwards : string -> bits(4)
function hex_bits_4_backwards s =
  match hex_bits_4_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_5 : bits(5) <-> string
val hex_bits_5_forwards = "decimal_string_of_bits" : bits(5) -> string
val hex_bits_5_forwards_matches : bits(5) -> bool
function hex_bits_5_forwards_matches bv = true
val "hex_bits_5_matches_prefix" : string -> option((bits(5), nat))
val hex_bits_5_backwards_matches : string -> bool
function hex_bits_5_backwards_matches s = match s {
  s if match hex_bits_5_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_5_backwards : string -> bits(5)
function hex_bits_5_backwards s =
  match hex_bits_5_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_6 : bits(6) <-> string
val hex_bits_6_forwards = "decimal_string_of_bits" : bits(6) -> string
val hex_bits_6_forwards_matches : bits(6) -> bool
function hex_bits_6_forwards_matches bv = true
val "hex_bits_6_matches_prefix" : string -> option((bits(6), nat))
val hex_bits_6_backwards_matches : string -> bool
function hex_bits_6_backwards_matches s = match s {
  s if match hex_bits_6_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_6_backwards : string -> bits(6)
function hex_bits_6_backwards s =
  match hex_bits_6_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_7 : bits(7) <-> string
val hex_bits_7_forwards = "decimal_string_of_bits" : bits(7) -> string
val hex_bits_7_forwards_matches : bits(7) -> bool
function hex_bits_7_forwards_matches bv = true
val "hex_bits_7_matches_prefix" : string -> option((bits(7), nat))
val hex_bits_7_backwards_matches : string -> bool
function hex_bits_7_backwards_matches s = match s {
  s if match hex_bits_7_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_7_backwards : string -> bits(7)
function hex_bits_7_backwards s =
  match hex_bits_7_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_8 : bits(8) <-> string
val hex_bits_8_forwards = "decimal_string_of_bits" : bits(8) -> string
val hex_bits_8_forwards_matches : bits(8) -> bool
function hex_bits_8_forwards_matches bv = true
val "hex_bits_8_matches_prefix" : string -> option((bits(8), nat))
val hex_bits_8_backwards_matches : string -> bool
function hex_bits_8_backwards_matches s = match s {
  s if match hex_bits_8_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_8_backwards : string -> bits(8)
function hex_bits_8_backwards s =
  match hex_bits_8_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_9 : bits(9) <-> string
val hex_bits_9_forwards = "decimal_string_of_bits" : bits(9) -> string
val hex_bits_9_forwards_matches : bits(9) -> bool
function hex_bits_9_forwards_matches bv = true
val "hex_bits_9_matches_prefix" : string -> option((bits(9), nat))
val hex_bits_9_backwards_matches : string -> bool
function hex_bits_9_backwards_matches s = match s {
  s if match hex_bits_9_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_9_backwards : string -> bits(9)
function hex_bits_9_backwards s =
  match hex_bits_9_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_10 : bits(10) <-> string
val hex_bits_10_forwards = "decimal_string_of_bits" : bits(10) -> string
val hex_bits_10_forwards_matches : bits(10) -> bool
function hex_bits_10_forwards_matches bv = true
val "hex_bits_10_matches_prefix" : string -> option((bits(10), nat))
val hex_bits_10_backwards_matches : string -> bool
function hex_bits_10_backwards_matches s = match s {
  s if match hex_bits_10_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_10_backwards : string -> bits(10)
function hex_bits_10_backwards s =
  match hex_bits_10_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_11 : bits(11) <-> string
val hex_bits_11_forwards = "decimal_string_of_bits" : bits(11) -> string
val hex_bits_11_forwards_matches : bits(11) -> bool
function hex_bits_11_forwards_matches bv = true
val "hex_bits_11_matches_prefix" : string -> option((bits(11), nat))
val hex_bits_11_backwards_matches : string -> bool
function hex_bits_11_backwards_matches s = match s {
  s if match hex_bits_11_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_11_backwards : string -> bits(11)
function hex_bits_11_backwards s =
  match hex_bits_11_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_12 : bits(12) <-> string
val hex_bits_12_forwards = "decimal_string_of_bits" : bits(12) -> string
val hex_bits_12_forwards_matches : bits(12) -> bool
function hex_bits_12_forwards_matches bv = true
val "hex_bits_12_matches_prefix" : string -> option((bits(12), nat))
val hex_bits_12_backwards_matches : string -> bool
function hex_bits_12_backwards_matches s = match s {
  s if match hex_bits_12_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_12_backwards : string -> bits(12)
function hex_bits_12_backwards s =
  match hex_bits_12_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_13 : bits(13) <-> string
val hex_bits_13_forwards = "decimal_string_of_bits" : bits(13) -> string
val hex_bits_13_forwards_matches : bits(13) -> bool
function hex_bits_13_forwards_matches bv = true
val "hex_bits_13_matches_prefix" : string -> option((bits(13), nat))
val hex_bits_13_backwards_matches : string -> bool
function hex_bits_13_backwards_matches s = match s {
  s if match hex_bits_13_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_13_backwards : string -> bits(13)
function hex_bits_13_backwards s =
  match hex_bits_13_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_14 : bits(14) <-> string
val hex_bits_14_forwards = "decimal_string_of_bits" : bits(14) -> string
val hex_bits_14_forwards_matches : bits(14) -> bool
function hex_bits_14_forwards_matches bv = true
val "hex_bits_14_matches_prefix" : string -> option((bits(14), nat))
val hex_bits_14_backwards_matches : string -> bool
function hex_bits_14_backwards_matches s = match s {
  s if match hex_bits_14_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_14_backwards : string -> bits(14)
function hex_bits_14_backwards s =
  match hex_bits_14_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_15 : bits(15) <-> string
val hex_bits_15_forwards = "decimal_string_of_bits" : bits(15) -> string
val hex_bits_15_forwards_matches : bits(15) -> bool
function hex_bits_15_forwards_matches bv = true
val "hex_bits_15_matches_prefix" : string -> option((bits(15), nat))
val hex_bits_15_backwards_matches : string -> bool
function hex_bits_15_backwards_matches s = match s {
  s if match hex_bits_15_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_15_backwards : string -> bits(15)
function hex_bits_15_backwards s =
  match hex_bits_15_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_16 : bits(16) <-> string
val hex_bits_16_forwards = "decimal_string_of_bits" : bits(16) -> string
val hex_bits_16_forwards_matches : bits(16) -> bool
function hex_bits_16_forwards_matches bv = true
val "hex_bits_16_matches_prefix" : string -> option((bits(16), nat))
val hex_bits_16_backwards_matches : string -> bool
function hex_bits_16_backwards_matches s = match s {
  s if match hex_bits_16_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_16_backwards : string -> bits(16)
function hex_bits_16_backwards s =
  match hex_bits_16_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_17 : bits(17) <-> string
val hex_bits_17_forwards = "decimal_string_of_bits" : bits(17) -> string
val hex_bits_17_forwards_matches : bits(17) -> bool
function hex_bits_17_forwards_matches bv = true
val "hex_bits_17_matches_prefix" : string -> option((bits(17), nat))
val hex_bits_17_backwards_matches : string -> bool
function hex_bits_17_backwards_matches s = match s {
  s if match hex_bits_17_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_17_backwards : string -> bits(17)
function hex_bits_17_backwards s =
  match hex_bits_17_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_18 : bits(18) <-> string
val hex_bits_18_forwards = "decimal_string_of_bits" : bits(18) -> string
val hex_bits_18_forwards_matches : bits(18) -> bool
function hex_bits_18_forwards_matches bv = true
val "hex_bits_18_matches_prefix" : string -> option((bits(18), nat))
val hex_bits_18_backwards_matches : string -> bool
function hex_bits_18_backwards_matches s = match s {
  s if match hex_bits_18_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_18_backwards : string -> bits(18)
function hex_bits_18_backwards s =
  match hex_bits_18_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_19 : bits(19) <-> string
val hex_bits_19_forwards = "decimal_string_of_bits" : bits(19) -> string
val hex_bits_19_forwards_matches : bits(19) -> bool
function hex_bits_19_forwards_matches bv = true
val "hex_bits_19_matches_prefix" : string -> option((bits(19), nat))
val hex_bits_19_backwards_matches : string -> bool
function hex_bits_19_backwards_matches s = match s {
  s if match hex_bits_19_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_19_backwards : string -> bits(19)
function hex_bits_19_backwards s =
  match hex_bits_19_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_20 : bits(20) <-> string
val hex_bits_20_forwards = "decimal_string_of_bits" : bits(20) -> string
val hex_bits_20_forwards_matches : bits(20) -> bool
function hex_bits_20_forwards_matches bv = true
val "hex_bits_20_matches_prefix" : string -> option((bits(20), nat))
val hex_bits_20_backwards_matches : string -> bool
function hex_bits_20_backwards_matches s = match s {
  s if match hex_bits_20_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_20_backwards : string -> bits(20)
function hex_bits_20_backwards s =
  match hex_bits_20_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_21 : bits(21) <-> string
val hex_bits_21_forwards = "decimal_string_of_bits" : bits(21) -> string
val hex_bits_21_forwards_matches : bits(21) -> bool
function hex_bits_21_forwards_matches bv = true
val "hex_bits_21_matches_prefix" : string -> option((bits(21), nat))
val hex_bits_21_backwards_matches : string -> bool
function hex_bits_21_backwards_matches s = match s {
  s if match hex_bits_21_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_21_backwards : string -> bits(21)
function hex_bits_21_backwards s =
  match hex_bits_21_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_22 : bits(22) <-> string
val hex_bits_22_forwards = "decimal_string_of_bits" : bits(22) -> string
val hex_bits_22_forwards_matches : bits(22) -> bool
function hex_bits_22_forwards_matches bv = true
val "hex_bits_22_matches_prefix" : string -> option((bits(22), nat))
val hex_bits_22_backwards_matches : string -> bool
function hex_bits_22_backwards_matches s = match s {
  s if match hex_bits_22_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_22_backwards : string -> bits(22)
function hex_bits_22_backwards s =
  match hex_bits_22_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_23 : bits(23) <-> string
val hex_bits_23_forwards = "decimal_string_of_bits" : bits(23) -> string
val hex_bits_23_forwards_matches : bits(23) -> bool
function hex_bits_23_forwards_matches bv = true
val "hex_bits_23_matches_prefix" : string -> option((bits(23), nat))
val hex_bits_23_backwards_matches : string -> bool
function hex_bits_23_backwards_matches s = match s {
  s if match hex_bits_23_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_23_backwards : string -> bits(23)
function hex_bits_23_backwards s =
  match hex_bits_23_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_24 : bits(24) <-> string
val hex_bits_24_forwards = "decimal_string_of_bits" : bits(24) -> string
val hex_bits_24_forwards_matches : bits(24) -> bool
function hex_bits_24_forwards_matches bv = true
val "hex_bits_24_matches_prefix" : string -> option((bits(24), nat))
val hex_bits_24_backwards_matches : string -> bool
function hex_bits_24_backwards_matches s = match s {
  s if match hex_bits_24_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_24_backwards : string -> bits(24)
function hex_bits_24_backwards s =
  match hex_bits_24_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_25 : bits(25) <-> string
val hex_bits_25_forwards = "decimal_string_of_bits" : bits(25) -> string
val hex_bits_25_forwards_matches : bits(25) -> bool
function hex_bits_25_forwards_matches bv = true
val "hex_bits_25_matches_prefix" : string -> option((bits(25), nat))
val hex_bits_25_backwards_matches : string -> bool
function hex_bits_25_backwards_matches s = match s {
  s if match hex_bits_25_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_25_backwards : string -> bits(25)
function hex_bits_25_backwards s =
  match hex_bits_25_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_26 : bits(26) <-> string
val hex_bits_26_forwards = "decimal_string_of_bits" : bits(26) -> string
val hex_bits_26_forwards_matches : bits(26) -> bool
function hex_bits_26_forwards_matches bv = true
val "hex_bits_26_matches_prefix" : string -> option((bits(26), nat))
val hex_bits_26_backwards_matches : string -> bool
function hex_bits_26_backwards_matches s = match s {
  s if match hex_bits_26_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_26_backwards : string -> bits(26)
function hex_bits_26_backwards s =
  match hex_bits_26_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_27 : bits(27) <-> string
val hex_bits_27_forwards = "decimal_string_of_bits" : bits(27) -> string
val hex_bits_27_forwards_matches : bits(27) -> bool
function hex_bits_27_forwards_matches bv = true
val "hex_bits_27_matches_prefix" : string -> option((bits(27), nat))
val hex_bits_27_backwards_matches : string -> bool
function hex_bits_27_backwards_matches s = match s {
  s if match hex_bits_27_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_27_backwards : string -> bits(27)
function hex_bits_27_backwards s =
  match hex_bits_27_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_28 : bits(28) <-> string
val hex_bits_28_forwards = "decimal_string_of_bits" : bits(28) -> string
val hex_bits_28_forwards_matches : bits(28) -> bool
function hex_bits_28_forwards_matches bv = true
val "hex_bits_28_matches_prefix" : string -> option((bits(28), nat))
val hex_bits_28_backwards_matches : string -> bool
function hex_bits_28_backwards_matches s = match s {
  s if match hex_bits_28_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_28_backwards : string -> bits(28)
function hex_bits_28_backwards s =
  match hex_bits_28_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_29 : bits(29) <-> string
val hex_bits_29_forwards = "decimal_string_of_bits" : bits(29) -> string
val hex_bits_29_forwards_matches : bits(29) -> bool
function hex_bits_29_forwards_matches bv = true
val "hex_bits_29_matches_prefix" : string -> option((bits(29), nat))
val hex_bits_29_backwards_matches : string -> bool
function hex_bits_29_backwards_matches s = match s {
  s if match hex_bits_29_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_29_backwards : string -> bits(29)
function hex_bits_29_backwards s =
  match hex_bits_29_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_30 : bits(30) <-> string
val hex_bits_30_forwards = "decimal_string_of_bits" : bits(30) -> string
val hex_bits_30_forwards_matches : bits(30) -> bool
function hex_bits_30_forwards_matches bv = true
val "hex_bits_30_matches_prefix" : string -> option((bits(30), nat))
val hex_bits_30_backwards_matches : string -> bool
function hex_bits_30_backwards_matches s = match s {
  s if match hex_bits_30_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_30_backwards : string -> bits(30)
function hex_bits_30_backwards s =
  match hex_bits_30_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_31 : bits(31) <-> string
val hex_bits_31_forwards = "decimal_string_of_bits" : bits(31) -> string
val hex_bits_31_forwards_matches : bits(31) -> bool
function hex_bits_31_forwards_matches bv = true
val "hex_bits_31_matches_prefix" : string -> option((bits(31), nat))
val hex_bits_31_backwards_matches : string -> bool
function hex_bits_31_backwards_matches s = match s {
  s if match hex_bits_31_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_31_backwards : string -> bits(31)
function hex_bits_31_backwards s =
  match hex_bits_31_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_32 : bits(32) <-> string
val hex_bits_32_forwards = "decimal_string_of_bits" : bits(32) -> string
val hex_bits_32_forwards_matches : bits(32) -> bool
function hex_bits_32_forwards_matches bv = true
val "hex_bits_32_matches_prefix" : string -> option((bits(32), nat))
val hex_bits_32_backwards_matches : string -> bool
function hex_bits_32_backwards_matches s = match s {
  s if match hex_bits_32_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_32_backwards : string -> bits(32)
function hex_bits_32_backwards s =
  match hex_bits_32_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_33 : bits(33) <-> string
val hex_bits_33_forwards = "decimal_string_of_bits" : bits(33) -> string
val hex_bits_33_forwards_matches : bits(33) -> bool
function hex_bits_33_forwards_matches bv = true
val "hex_bits_33_matches_prefix" : string -> option((bits(33), nat))
val hex_bits_33_backwards_matches : string -> bool
function hex_bits_33_backwards_matches s = match s {
  s if match hex_bits_33_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_33_backwards : string -> bits(33)
function hex_bits_33_backwards s =
  match hex_bits_33_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_48 : bits(48) <-> string
val hex_bits_48_forwards = "decimal_string_of_bits" : bits(48) -> string
val hex_bits_48_forwards_matches : bits(48) -> bool
function hex_bits_48_forwards_matches bv = true
val "hex_bits_48_matches_prefix" : string -> option((bits(48), nat))
val hex_bits_48_backwards_matches : string -> bool
function hex_bits_48_backwards_matches s = match s {
  s if match hex_bits_48_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_48_backwards : string -> bits(48)
function hex_bits_48_backwards s =
  match hex_bits_48_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

val hex_bits_64 : bits(64) <-> string
val hex_bits_64_forwards = "decimal_string_of_bits" : bits(64) -> string
val hex_bits_64_forwards_matches : bits(64) -> bool
function hex_bits_64_forwards_matches bv = true
val "hex_bits_64_matches_prefix" : string -> option((bits(64), nat))
val hex_bits_64_backwards_matches : string -> bool
function hex_bits_64_backwards_matches s = match s {
  s if match hex_bits_64_matches_prefix(s) {
    Some (_, n) if n == string_length(s) => true,
    _ => false
  } => true,
  _ => false
}
val hex_bits_64_backwards : string -> bits(64)
function hex_bits_64_backwards s =
  match hex_bits_64_matches_prefix(s) {
      Some (bv, n) if n == string_length(s) => bv
  }

