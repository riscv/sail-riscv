// Verify that the reset sxl and uxl are correct.
$[test]
function test_mstatus_sxl_uxl_reset_values() -> unit = {
  let mstatush_val : bits(32) = match xlen {
    32 => read_CSR(0x310),
    64 => read_CSR(0x300)[63 .. 32],
    _  => internal_error(__FILE__, __LINE__, "unsupported xlen"),
  };
  // 0 = 32, 1 = 64, 2 = 128, but on RV32 SXL/UXL don't actually
  // exist (they are currently WPRI). For now we set them to 0.
  // If those bits are used in future we may expect a different value.
  let expected_xl : bits(2) = match xlen {
    32 => 0b00,
    64 => 0b10,
    _  => internal_error(__FILE__, __LINE__, "unsupported xlen"),
  };
  // SXL
  assert(mstatush_val[3 .. 2] == expected_xl);
  // UXL
  assert(mstatush_val[1 .. 0] == expected_xl);
}
