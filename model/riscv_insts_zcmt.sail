/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zcmt) = hartSupports(Ext_Zcmt) & currentlyEnabled(Ext_Zca) & not(currentlyEnabled(Ext_Zcd))

type target_address = xlenbits

function fetch_jump_table(table_address : xlenbits) -> result(target_address, ExecutionResult) = {
  /* Executable permission required to fetch jump table address */
  match ext_data_get_addr_from_bits(table_address, InstructionFetch(), xlen_bytes) {
    Ext_DataAddr_Error(e)  => { Err(Ext_DataAddr_Check_Failure(e)) },
    Ext_DataAddr_OK(vaddr) => {
      if   check_misaligned(vaddr, size_bytes(xlen_bytes))
      then { Err(Memory_Exception(vaddr, E_Load_Addr_Align())) }
      else match translateAddr(vaddr, InstructionFetch()) {
        TR_Failure(e, _) => { Err(Memory_Exception(vaddr, e)) },
        TR_Address(paddr, _) =>
          match mem_read(InstructionFetch(), paddr, xlen_bytes, false, false, false) {
            Err(e)     => { Err(Memory_Exception(vaddr, e)) },
            Ok(result) => { Ok(result) },
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
        Err(e) => { e },
        Ok(target_address) => {
          X(ra) = get_next_pc();
          set_next_pc([target_address with 0 = bitzero]);
          RETIRE_SUCCESS
        }
    };
  } else {
    Illegal_Instruction()
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
        Err(e) => { e },
        Ok(target_address) => {
          set_next_pc([target_address with 0 = bitzero]);
          RETIRE_SUCCESS
        }
    };
  } else {
      Illegal_Instruction()
    };
}

mapping clause assembly = CM_JT(index)
  <-> "cm.jt" ^ spc() ^ hex_bits_8(index)
