/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

val vector_table_fetch : xlenbits -> VectorTableFetchResult
function vector_table_fetch(table_addr) -> VectorTableFetchResult =
  if sizeof(xlen) == 32 then { 
    match mem_read(Execute(), table_addr, 4, false, false, false) {
      MemException(e)       => F_TableError(e, table_addr),
      MemValue(table_entry) => F_TableEntry(table_entry)
    }
  } else { /* xlen == 64 */
    match mem_read(Execute(), table_addr, 8, false, false, false) {
      MemException(e)       => F_TableError(e, table_addr),
      MemValue(table_entry) => F_TableEntry(table_entry)
    }
  }
