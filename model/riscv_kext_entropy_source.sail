/*
 * Contains a basic model for the RISC-V cryptography extension entropy
 * source. See section 4 of the specifications for details.
 * - https://github.com/riscv/riscv-crypto/releases
 */

/*
 * The mnoise CSR
 * ------------------------------------------------------------
 */

/* Bitfield definition for the mnoise CSR.
 * Most of this is implementation defined, so only the architectural bit
 * `NOISE_TEST` is actually specified here.
 */
bitfield Mnoise : xlenbits = {
  NOISE_TEST : 31
}

register mnoise : Mnoise

/* mnoise is defined in machine mode only */
function clause ext_is_CSR_defined(0x7A9, Machine) = {
  true
}

function clause ext_read_CSR(0x7A9) = {
   Some(mnoise.bits())
}

/* Only bit 31 of mnoise is architecturally defined. */
function clause ext_write_CSR(0x7A9, value) = {
  mnoise -> NOISE_TEST() = value[31..31];
  Some(mnoise.bits())
}

/* Used by mentropy to check if we are (not) in noise capture mode */
val in_noise_capture_mode : unit -> bool effect {rreg}
function in_noise_capture_mode() = {
  if mnoise.NOISE_TEST() == 0b1 then true else false
}

/*
 * The mentropy CSR
 * ------------------------------------------------------------
 */

/* Valid return states for reading the mentropy CSR. */
enum mentropy_opst = {
  BIST, // Built-in-self-test. No randomness sampled.
  ES16, // Entropy-sample-16. Valid 16-bits of randomness sampled.
  WAIT, // Device still gathering entropy.
  DEAD  // Fatal device compromise. No randomness sampled.
}

/* Mapping of status codes and their actual encodings. */
mapping opst_code : mentropy_opst <-> bits(2) = {
  BIST <-> 0b00,
  ES16 <-> 0b01,
  WAIT <-> 0b10,
  DEAD <-> 0b11
}

/* 
 * function representing an entropy samping.
 * This is a wrapper around a platform provided function for getting
 * entropy bits.
 * See riscv_platform.sail for plat_get_16_random_bits definition.
 *
 * WARNING: This function currently lacks a proper side-effect annotation.
 *          If you are using theorem prover tool flows, you
 *          may need to modify or stub out this function for now.
 */
val get_random_bits : unit -> bits(16)
function get_random_bits() = {
  plat_get_16_random_bits()[15..0]
}

/* mentropy is defined in machine mode only */
function clause ext_is_CSR_defined(0xF15, Machine) = {
  true
}

function clause ext_read_CSR(0xF15) = {
  let reserved_bits : bits(6) = 0b000000;
  let custom_bits : bits(8) = 0x00;
  if in_noise_capture_mode()  then {
    let seed : bits(16) = 0x0000;
    Some(EXTZ(opst_code(BIST) @ reserved_bits @ custom_bits @ seed))
  } else {
    let seed : bits(16) = get_random_bits();
    Some(EXTZ(opst_code(ES16) @ reserved_bits @ custom_bits @ seed))
  }
}

/* Always ignore writes to mentropy */
function clause ext_write_CSR(0xF15, value) = {
  Some(EXTZ(0x0))
}
