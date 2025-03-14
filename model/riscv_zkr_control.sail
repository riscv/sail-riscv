/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Zkr entropy seed source */
function clause extensionEnabled(Ext_Zkr) = true

/* Valid return states for reading the seed CSR. */
enum seed_opst = {
  BIST, // Built-in-self-test. No randomness sampled.
  ES16, // Entropy-sample-16. Valid 16-bits of randomness sampled.
  WAIT, // Device still gathering entropy.
  DEAD  // Fatal device compromise. No randomness sampled.
}

/* Mapping of status codes and their actual encodings. */
mapping opst_code : seed_opst <-> bits(2) = {
  BIST <-> 0b00,
  WAIT <-> 0b01,
  ES16 <-> 0b10,
  DEAD <-> 0b11
}

/* Entropy source spec requires an Illegal opcode exception be raised if the
 * seed register is read without also being written. This function is only
 * called once we know the CSR is being written, and all other access control
 * checks have been done.
 */
function read_seed_csr() -> xlenbits = {
  let reserved_bits : bits(6) = 0b000000;
  let custom_bits : bits(8) = 0x00;
  let seed : bits(16) = get_16_random_bits();
  zero_extend(opst_code(ES16) @ reserved_bits @ custom_bits @ seed)
}

/* Writes to the seed CSR are ignored */
function write_seed_csr () -> xlenbits = zeros()

/* CSR mapping */
mapping clause csr_name_map = 0x015  <-> "seed"
function clause is_CSR_defined(0x015) = extensionEnabled(Ext_Zkr)
function clause read_CSR(0x015) = read_seed_csr()
function clause write_CSR(0x015, value) = write_seed_csr()
