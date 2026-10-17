// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

private function check_fli_assembly(index : bits(5), immediate : string) -> unit = {
  let rd = Fregidx(index);
  let operands = freg_name(rd) ^ ", " ^ immediate;
  assert(assembly(FLI_H(index, rd)) == "fli.h " ^ operands);
  assert(assembly(FLI_S(index, rd)) == "fli.s " ^ operands);
  assert(assembly(FLI_D(index, rd)) == "fli.d " ^ operands);
}

$[test]
function test_fli_assembly() -> unit = {
  check_fli_assembly(0b00000, "-1.0");
  check_fli_assembly(0b00001, "min");
  check_fli_assembly(0b00010, "0x1p-16");
  check_fli_assembly(0b00011, "0x1p-15");
  check_fli_assembly(0b00100, "0x1p-8");
  check_fli_assembly(0b00101, "0x1p-7");
  check_fli_assembly(0b00110, "0.0625");
  check_fli_assembly(0b00111, "0.125");
  check_fli_assembly(0b01000, "0.25");
  check_fli_assembly(0b01001, "0.3125");
  check_fli_assembly(0b01010, "0.375");
  check_fli_assembly(0b01011, "0.4375");
  check_fli_assembly(0b01100, "0.5");
  check_fli_assembly(0b01101, "0.625");
  check_fli_assembly(0b01110, "0.75");
  check_fli_assembly(0b01111, "0.875");
  check_fli_assembly(0b10000, "1.0");
  check_fli_assembly(0b10001, "1.25");
  check_fli_assembly(0b10010, "1.5");
  check_fli_assembly(0b10011, "1.75");
  check_fli_assembly(0b10100, "2.0");
  check_fli_assembly(0b10101, "2.5");
  check_fli_assembly(0b10110, "3.0");
  check_fli_assembly(0b10111, "4.0");
  check_fli_assembly(0b11000, "8.0");
  check_fli_assembly(0b11001, "16.0");
  check_fli_assembly(0b11010, "128.0");
  check_fli_assembly(0b11011, "256.0");
  check_fli_assembly(0b11100, "32768.0");
  check_fli_assembly(0b11101, "65536.0");
  check_fli_assembly(0b11110, "inf");
  check_fli_assembly(0b11111, "nan");
}

$[test]
function test_bf16_assembly() -> unit = {
  let vd = Vregidx(0b10000);
  let vs1 = Vregidx(0b01000);
  let vs2 = Vregidx(0b00100);
  let fs1 = Fregidx(0b01000);
  foreach (i from 0 to 1) {
    let vm : bits(1) = to_bits(1, i);
    let mask = if vm == 0b0 then ", v0.t" else "";
    assert(assembly(VFNCVTBF16_F_F_W(vm, vs2, vd)) == "vfncvtbf16.f.f.w v16, v4" ^ mask);
    assert(assembly(VFWCVTBF16_F_F_V(vm, vs2, vd)) == "vfwcvtbf16.f.f.v v16, v4" ^ mask);
    assert(assembly(VFWMACCBF16_VV(vm, vs2, vs1, vd)) == "vfwmaccbf16.vv v16, v8, v4" ^ mask);
    assert(assembly(VFWMACCBF16_VF(vm, vs2, fs1, vd)) == "vfwmaccbf16.vf v16, " ^ freg_name(fs1) ^ ", v4" ^ mask);
  }
}
