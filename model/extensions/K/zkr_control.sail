// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Zkr entropy seed source
function clause currentlyEnabled(Ext_Zkr) = hartSupports(Ext_Zkr)

// Valid return states for reading the seed CSR.
private enum seed_opst = {
  BIST, // Built-in-self-test. No randomness sampled.
  ES16, // Entropy-sample-16. Valid 16-bits of randomness sampled.
  WAIT, // Device still gathering entropy.
  DEAD  // Fatal device compromise. No randomness sampled.
}

// Mapping of status codes and their actual encodings.
private mapping opst_code : seed_opst <-> bits(2) = {
  BIST <-> 0b00,
  WAIT <-> 0b01,
  ES16 <-> 0b10,
  DEAD <-> 0b11
}

// Entropy source spec requires an Illegal opcode exception be raised if the
// seed register is read without also being written. This function is only
// called once we know the CSR is being written, and all other access control
// checks have been done.
private function read_seed_csr() -> xlenbits = {
  let reserved_bits : bits(6) = 0b000000;
  let custom_bits : bits(8) = 0x00;
  let seed : bits(16) = get_16_random_bits();
  zero_extend(opst_code(ES16) @ reserved_bits @ custom_bits @ seed)
}

// Writes to the seed CSR are ignored
private function write_seed_csr () -> xlenbits = zeros()

// CSR mapping
mapping clause csr_name_map = 0x015  <-> "seed"

// This implements the "Entropy Source Access Control" Table in the manual.
function clause is_CSR_accessible(0x015, priv, access_type) = {
  if not(currentlyEnabled(Ext_Zkr)) | access_type == CSRRead
  then return Err(CSR_Access_Illegal);

  match priv {
    Machine           => Ok(()),
    User              => if mseccfg[USEED] == 0b1 then Ok(()) else Err(CSR_Access_Illegal),
    Supervisor        => if mseccfg[SSEED] == 0b1 then Ok(()) else Err(CSR_Access_Illegal),
    VirtualSupervisor => if mseccfg[SSEED] == 0b1
                         then Err(if access_type == CSRReadWrite then CSR_Access_Virtual else CSR_Access_Illegal)
                         else Err(CSR_Access_Illegal),
    VirtualUser       => if mseccfg[SSEED] == 0b1
                         then Err(if access_type == CSRReadWrite then CSR_Access_Virtual else CSR_Access_Illegal)
                         else Err(CSR_Access_Illegal),
  }
}

function clause read_CSR(0x015) = read_seed_csr()
function clause write_CSR(0x015, _value) = Ok(write_seed_csr())
