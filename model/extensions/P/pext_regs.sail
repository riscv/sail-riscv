// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

mapping encdec_preg : pregidx <-> bits(4) = {
  forwards Pregidx(r) => zero_extend(r),
  backwards r if not(base_E_enabled) | r[3] == 0b0 => Pregidx(r[3 .. 0]),
}

function regidx_of_pregidx(p : pregidx) -> regidx = {
  match p {
    Pregidx(n) => {
      let i = unsigned(n);

      if base_E_enabled & i >= 8 then {
        internal_error(__FILE__, __LINE__, "bad pregidx for base E")
      } else {
        Regidx(to_bits((if base_E_enabled then 4 else 5), 2 * i))
      }
    }
  }
}
