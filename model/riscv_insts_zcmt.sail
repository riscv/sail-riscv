/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zcmt) = hartSupports(Ext_Zcmt) & currentlyEnabled(Ext_Zca) & not(currentlyEnabled(Ext_Zcd))

type target_address = xlenbits

function fetch_jump_table(table_address : xlenbits) -> result(target_address, unit) = {
  /* Executable permission required to fetch jump table address */
  match ext_data_get_addr_from_bits(table_address, Execute(), xlen_bytes) {
    Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); Err() },
    Ext_DataAddr_OK(vaddr) => {
      if   check_misaligned(vaddr, size_bytes(xlen_bytes))
      then { handle_mem_exception(vaddr, E_Load_Addr_Align()); Err() }
      else match translateAddr(vaddr, Execute()) {
        TR_Failure(e, _) => { handle_mem_exception(vaddr, e); Err() },
        TR_Address(paddr, _) =>
          match mem_read(Execute(), paddr, xlen_bytes, false, false, false) {
            Ok(result) => { Ok(result) },
            Err(e)     => { handle_mem_exception(vaddr, e); Err() },
          }
      }
    }
  }
}

union clause ast = CM_JALT : (bits(8))

mapping clause encdec_compressed = CM_JALT(index)
  <-> 0b101 @ 0b000 @ index : bits(8) @ 0b10
  when currentlyEnabled(Ext_Zcmt) & 32 <= unsigned(index)

function clause execute (CM_JALT(index)) = {
  let base  : bits(xlen) = jvt[base] @ 0b000000;
  let index : bits(xlen) = zero_extend(index);
  if jvt[mode] == 0b000000 then {
    let table_address = base + (index << log2_xlen_bytes);
    match fetch_jump_table(table_address) {
        Err(_) => { RETIRE_FAIL },
        Ok(target_address) => {
          X(ra) = get_next_pc();
          set_next_pc([target_address with 0 = bitzero]);
          RETIRE_SUCCESS
        }
    };
  } else {
    handle_illegal();
    RETIRE_FAIL
  };
}

mapping clause assembly = CM_JALT(index)
   <-> "cm.jalt" ^ spc() ^ hex_bits_8(index)

/* ****************************************************************** */
union clause ast = CM_JT : (bits(8))

mapping clause encdec_compressed = CM_JT(index)
  <-> 0b101 @ 0b000 @ index : bits(8) @ 0b10
  when currentlyEnabled(Ext_Zcmt) & unsigned(index) < 32

function clause execute (CM_JT(index)) = {
  let base  : bits(xlen) = jvt[base] @ 0b000000;
  let index : bits(xlen) = zero_extend(index);
  if jvt[mode] == 0b000000 then {
    let table_address = base + (index << log2_xlen_bytes);
    match fetch_jump_table(table_address) {
        Err(_) => { RETIRE_FAIL },
        Ok(target_address) => {
          set_next_pc([target_address with 0 = bitzero]);
          RETIRE_SUCCESS
        }
    };
  } else {
      handle_illegal();
      RETIRE_FAIL
    };
}

mapping clause assembly = CM_JT(index)
  <-> "cm.jt" ^ spc() ^ hex_bits_8(index)
