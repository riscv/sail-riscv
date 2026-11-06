// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Hardware Performance Monitoring counters
function clause currentlyEnabled(Ext_Zihpm) = hartSupports(Ext_Zihpm) & currentlyEnabled(Ext_Zicsr)

// Hardware performance monitoring counters
mapping clause csr_name_map = 0xC03  <-> "hpmcounter3"
mapping clause csr_name_map = 0xC04  <-> "hpmcounter4"
mapping clause csr_name_map = 0xC05  <-> "hpmcounter5"
mapping clause csr_name_map = 0xC06  <-> "hpmcounter6"
mapping clause csr_name_map = 0xC07  <-> "hpmcounter7"
mapping clause csr_name_map = 0xC08  <-> "hpmcounter8"
mapping clause csr_name_map = 0xC09  <-> "hpmcounter9"
mapping clause csr_name_map = 0xC0A  <-> "hpmcounter10"
mapping clause csr_name_map = 0xC0B  <-> "hpmcounter11"
mapping clause csr_name_map = 0xC0C  <-> "hpmcounter12"
mapping clause csr_name_map = 0xC0D  <-> "hpmcounter13"
mapping clause csr_name_map = 0xC0E  <-> "hpmcounter14"
mapping clause csr_name_map = 0xC0F  <-> "hpmcounter15"
mapping clause csr_name_map = 0xC10  <-> "hpmcounter16"
mapping clause csr_name_map = 0xC11  <-> "hpmcounter17"
mapping clause csr_name_map = 0xC12  <-> "hpmcounter18"
mapping clause csr_name_map = 0xC13  <-> "hpmcounter19"
mapping clause csr_name_map = 0xC14  <-> "hpmcounter20"
mapping clause csr_name_map = 0xC15  <-> "hpmcounter21"
mapping clause csr_name_map = 0xC16  <-> "hpmcounter22"
mapping clause csr_name_map = 0xC17  <-> "hpmcounter23"
mapping clause csr_name_map = 0xC18  <-> "hpmcounter24"
mapping clause csr_name_map = 0xC19  <-> "hpmcounter25"
mapping clause csr_name_map = 0xC1A  <-> "hpmcounter26"
mapping clause csr_name_map = 0xC1B  <-> "hpmcounter27"
mapping clause csr_name_map = 0xC1C  <-> "hpmcounter28"
mapping clause csr_name_map = 0xC1D  <-> "hpmcounter29"
mapping clause csr_name_map = 0xC1E  <-> "hpmcounter30"
mapping clause csr_name_map = 0xC1F  <-> "hpmcounter31"

mapping clause csr_name_map = 0xC83  <-> "hpmcounter3h"
mapping clause csr_name_map = 0xC84  <-> "hpmcounter4h"
mapping clause csr_name_map = 0xC85  <-> "hpmcounter5h"
mapping clause csr_name_map = 0xC86  <-> "hpmcounter6h"
mapping clause csr_name_map = 0xC87  <-> "hpmcounter7h"
mapping clause csr_name_map = 0xC88  <-> "hpmcounter8h"
mapping clause csr_name_map = 0xC89  <-> "hpmcounter9h"
mapping clause csr_name_map = 0xC8A  <-> "hpmcounter10h"
mapping clause csr_name_map = 0xC8B  <-> "hpmcounter11h"
mapping clause csr_name_map = 0xC8C  <-> "hpmcounter12h"
mapping clause csr_name_map = 0xC8D  <-> "hpmcounter13h"
mapping clause csr_name_map = 0xC8E  <-> "hpmcounter14h"
mapping clause csr_name_map = 0xC8F  <-> "hpmcounter15h"
mapping clause csr_name_map = 0xC90  <-> "hpmcounter16h"
mapping clause csr_name_map = 0xC91  <-> "hpmcounter17h"
mapping clause csr_name_map = 0xC92  <-> "hpmcounter18h"
mapping clause csr_name_map = 0xC93  <-> "hpmcounter19h"
mapping clause csr_name_map = 0xC94  <-> "hpmcounter20h"
mapping clause csr_name_map = 0xC95  <-> "hpmcounter21h"
mapping clause csr_name_map = 0xC96  <-> "hpmcounter22h"
mapping clause csr_name_map = 0xC97  <-> "hpmcounter23h"
mapping clause csr_name_map = 0xC98  <-> "hpmcounter24h"
mapping clause csr_name_map = 0xC99  <-> "hpmcounter25h"
mapping clause csr_name_map = 0xC9A  <-> "hpmcounter26h"
mapping clause csr_name_map = 0xC9B  <-> "hpmcounter27h"
mapping clause csr_name_map = 0xC9C  <-> "hpmcounter28h"
mapping clause csr_name_map = 0xC9D  <-> "hpmcounter29h"
mapping clause csr_name_map = 0xC9E  <-> "hpmcounter30h"
mapping clause csr_name_map = 0xC9F  <-> "hpmcounter31h"

// Hardware Performance Monitoring user mode counters
function clause is_CSR_accessible((0b1100000 /* 0xC00 */ @ index : bits(5), priv, _) if unsigned(index) >= 3) = currentlyEnabled(Ext_Zihpm) & counter_enabled(unsigned(index), priv) // hpmcounter3..31
function clause is_CSR_accessible((0b1100100 /* 0xC80 */ @ index : bits(5), priv, _) if unsigned(index) >= 3) = currentlyEnabled(Ext_Zihpm) & xlen == 32 & counter_enabled(unsigned(index), priv) // hpmcounterh3..31

function clause read_CSR(0b1100000 /* 0xC00 */ @ index : bits(5) if unsigned(index) >= 3) = read_mhpmcounter(hpmidx_from_bits(index))
function clause read_CSR(0b1100100 /* 0xC80 */ @ index : bits(5) if xlen == 32 & unsigned(index) >= 3) = read_mhpmcounterh(hpmidx_from_bits(index))
