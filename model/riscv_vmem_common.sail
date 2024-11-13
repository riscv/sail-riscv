/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// ****************************************************************
// Parameters for VM modes sv32, sv39, sv48 and (TODO) Sv57

// All VM modes use the same page size (4KB, with 12-bit index)

// This two-line idiom constrains the value (2nd line) to be a singleton,
// which helps in type-checking wherever it is used.
type PAGESIZE_BITS : Int = 12
let  pagesize_bits = sizeof(PAGESIZE_BITS)

// PRIVATE
struct SV_Params = {
  // VA
  va_size_bits        : {32, 39, 48},    //   32    39    48
  vpn_size_bits       : {10,  9},        //   10     9     9

  // PTE
  levels              : { 2,  3,  4},    //    2     3     4
  log_pte_size_bytes  : { 2,  3},        //    2     3     3
  pte_msbs_lsb_index  : {32, 54},        //   32    54    54
  pte_msbs_size_bits  : { 0, 10},        //    0    10    10
  pte_PPNs_lsb_index  : {10},            //   10    10    10
  pte_PPNs_size_bits  : {22, 44},        //   22    44    44
  pte_PPN_j_size_bits : {10,  9}         //   10     9     9
}

// Current level during a page-table walk (0 to SV_Params.levels - 1)
type PTW_Level = range(0,3)    // range(0,4) when add Sv57 (TODO)

// PRIVATE
let sv32_params : SV_Params = struct {
       // VA
       va_size_bits        = 32,
       vpn_size_bits       = 10,

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
       vpn_size_bits       = 9,

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
       vpn_size_bits       = 9,

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
       vpn_size_bits       = 9,

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
