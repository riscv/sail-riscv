/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Zcmt) = extensionEnabled(Ext_Zca) & sys_enable_zcmt() & not(sys_enable_zcd()) & (xlen == 32 | xlen == 64)

type target_address = bits(xlen)

union FJT_Result = {
  FJT_Success : target_address,
  FJT_Failure : unit
}

function fetch_jump_table(table_address : bits(xlen)) -> FJT_Result = {
  /* Fetching jump table address needs execute permission */
  match ext_data_get_addr_from_bits(table_address, Execute(), xlen_bytes) {
    Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); FJT_Failure() },
    Ext_DataAddr_OK(vaddr) => {
      if   check_misaligned(vaddr, size_bytes(xlen_bytes))
      then { handle_mem_exception(vaddr, E_Load_Addr_Align()); FJT_Failure() }
      else match translateAddr(vaddr, Execute()) {
        TR_Failure(e, _) => { handle_mem_exception(vaddr, e); FJT_Failure() },
        TR_Address(paddr, _) =>
          match mem_read(Execute(), paddr, xlen_bytes, false, false, false) {
            Ok(result) => { FJT_Success(result) },
            Err(e)     => { handle_mem_exception(vaddr, e); FJT_Failure() },
          }
      }
    }
  }
}

union clause ast = CM_JALT : (bits(8))

mapping clause encdec_compressed = CM_JALT(index) if extensionEnabled(Ext_Zcmt) & 32 <= unsigned(index)
  <-> 0b101 @ 0b000 @ index : bits(8) @ 0b10 if extensionEnabled(Ext_Zcmt) & 32 <= unsigned(index)

function clause execute (CM_JALT(index)) = {
  let base : bits(xlen) = jvt[base] @ 0b000000;
  let index : bits(xlen) = zero_extend(index);
  if jvt[mode] == 0b000000 then {
    let table_address = base + index << log2_xlen_bytes;
    match fetch_jump_table(table_address) {
        FJT_Failure(_) => { RETIRE_FAIL },
        FJT_Success(target_address) => { X(1) = get_next_pc(); set_next_pc(target_address & ~(zero_extend(0x1))); RETIRE_SUCCESS }
    };
  } else { handle_illegal(); RETIRE_FAIL };
}

mapping clause assembly = CM_JALT(index) if (xlen == 32 | xlen == 64) <->
  "cm.jalt" ^ spc() ^ hex_bits_8(index) if (xlen == 32 | xlen == 64)

/* ****************************************************************** */
union clause ast = CM_JT : (bits(8))

mapping clause encdec_compressed = CM_JT(index) if extensionEnabled(Ext_Zcmt) & unsigned(index) < 32
  <-> 0b101 @ 0b000 @ index : bits(8) @ 0b10 if extensionEnabled(Ext_Zcmt) & unsigned(index) < 32

function clause execute (CM_JT(index)) = {
  let base : bits(xlen) = jvt[base] @ 0b000000;
  let index : bits(xlen) = zero_extend(index);
  var a : bits(xlen) = zeros();
  if jvt[mode] == 0b000000 then {
    let table_address = base + index << log2_xlen_bytes;
    match fetch_jump_table(table_address) {
        FJT_Failure(_) => { RETIRE_FAIL },
        FJT_Success(target_address) => { set_next_pc(target_address & ~(zero_extend(0x1))); RETIRE_SUCCESS }
    };
  } else { handle_illegal(); RETIRE_FAIL };
}

mapping clause assembly = CM_JT(index) if (xlen == 32 | xlen == 64) <->
  "cm.jt" ^ spc() ^ hex_bits_8(index) if (xlen == 32 | xlen == 64)
