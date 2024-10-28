/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Parameters for VM modes Sv32, Sv32x4, Sv39, Sv39x4, Sv48, Sv48x4, (TODO) Sv57 and (TODO) Sv57x4

// All VM modes use the same page size (4KB, with 12-bit index)

// This two-line idiom constrains the value (2nd line) to be a singleton,
// which helps in type-checking wherever it is used.
type PAGESIZE_BITS : Int = 12
let  pagesize_bits = sizeof(PAGESIZE_BITS)

// PRIVATE
struct SV_Params = {
  // Address translation modes:                                Sv32  Sv39  Sv48  Sv57  Sv32x4  Sv39x4  Sv48x4  Sv57x4

  // VA
  va_size_bits        : {32, 34, 39, 41, 48, 50, 57, 59},   //   32    39    48    57      34      41      50      59
  va_sign_extends     : bool,                               // true  true  true  true   false   false   false   false
  vpn_size_bits       : {10,  9},                           //   10     9     9     9      10       9       9       9
  root_vpn_size_bits  : {9,  10, 11, 12},                   //   10     9     9     9      12      11      11      11

  // PTE
  levels              : { 2,  3,  4,  5},                   //    2     3     4     5       2       3       4       5
  log_pte_size_bytes  : { 2,  3},                           //    2     3     3     3       2       3       3       3
  pte_msbs_lsb_index  : {32, 54},                           //   32    54    54    54      32      54      54      54
  pte_msbs_size_bits  : { 0, 10},                           //    0    10    10    10       0      10      10      10
  pte_PPNs_lsb_index  : {10},                               //   10    10    10    10      10      10      10      10
  pte_PPNs_size_bits  : {22, 44},                           //   22    44    44    44      22      44      44      44
  pte_PPN_j_size_bits : {10,  9}                            //   10     9     9     9      10       9       9       9
}

// Current level during a page-table walk (0 to SV_Params.levels - 1)
type PTW_Level = range(0, 4)

// PRIVATE
let sv32_params : SV_Params = struct {
       // VA
       va_size_bits        = 32,
       va_sign_extends     = true,
       vpn_size_bits       = 10,
       root_vpn_size_bits  = 10,

       // PTE
       levels              = 2,
       log_pte_size_bytes  = 2,    // 4 Bytes
       pte_msbs_lsb_index  = 32,
       pte_msbs_size_bits  = 0,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 22,
       pte_PPN_j_size_bits = 10
}

// PRIVATE
let sv39_params : SV_Params = struct {
       // VA
       va_size_bits        = 39,
       va_sign_extends     = true,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 9,

       // PTE
       levels              = 3,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}

// PRIVATE
let sv48_params : SV_Params = struct {
       // VA
       va_size_bits        = 48,
       va_sign_extends     = true,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 9,

       // PTE
       levels              = 4,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}

// TODO; not currently used
// PRIVATE
/*
let sv57_params : SV_Params = struct {
       // VA
       va_size_bits        = 57,
       va_sign_extends     = true,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 9,

       // PTE
       levels              = 5,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}
*/

// PRIVATE
let sv32x4_params : SV_Params = struct {
       // VA
       va_size_bits        = 34,
       va_sign_extends     = false,
       vpn_size_bits       = 10,
       root_vpn_size_bits  = 12,

       // PTE
       levels              = 2,
       log_pte_size_bytes  = 2,    // 4 Bytes
       pte_msbs_lsb_index  = 32,
       pte_msbs_size_bits  = 0,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 22,
       pte_PPN_j_size_bits = 10
}

let sv39x4_params : SV_Params = struct {
       // VA
       va_size_bits        = 41,
       va_sign_extends     = false,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 11,

       // PTE
       levels              = 3,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}

// PRIVATE
let sv48x4_params : SV_Params = struct {
       // VA
       va_size_bits        = 50,
       va_sign_extends     = false,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 11,

       // PTE
       levels              = 4,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}

// TODO; not currently used
// PRIVATE
/*
let sv57x4_params : SV_Params = struct {
       // VA
       va_size_bits        = 59,
       va_sign_extends     = false,
       vpn_size_bits       = 9,
       root_vpn_size_bits  = 11,

       // PTE
       levels              = 5,
       log_pte_size_bytes  = 3,    // 8 Bytes
       pte_msbs_lsb_index  = 54,
       pte_msbs_size_bits  = 10,
       pte_PPNs_lsb_index  = 10,
       pte_PPNs_size_bits  = 44,
       pte_PPN_j_size_bits = 9
}
*/
