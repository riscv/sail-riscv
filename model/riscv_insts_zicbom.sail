/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Cache Block Operations - Management

function clause extensionEnabled(Ext_Zicbom) = sys_enable_zicbom()

function cbo_clean_flush_enabled(p : Privilege) -> bool = feature_enabled_for_priv(p, menvcfg[CBCFE][0], senvcfg[CBCFE][0])
function cbo_inval_enabled(p : Privilege) -> bool = feature_enabled_for_priv(p, menvcfg[CBIE][0], senvcfg[CBIE][0])
function cbo_inval_as_inval(p : Privilege) -> bool = feature_enabled_for_priv(p, menvcfg[CBIE][1], senvcfg[CBIE][1])

/* ****************************************************************** */
union clause ast = RISCV_ZICBOM : (cbop_zicbom, regidx)

mapping encdec_cbop : cbop_zicbom <-> bits(12) = {
  CBO_CLEAN <-> 0b000000000001,
  CBO_FLUSH <-> 0b000000000010,
  CBO_INVAL <-> 0b000000000000,
}

mapping clause encdec = RISCV_ZICBOM(cbop, rs1)             if extensionEnabled(Ext_Zicbom)
  <-> encdec_cbop(cbop) @ rs1 @ 0b010 @ 0b00000 @ 0b0001111 if extensionEnabled(Ext_Zicbom)

mapping cbop_mnemonic : cbop_zicbom <-> string = {
  CBO_CLEAN <-> "cbo.clean",
  CBO_FLUSH <-> "cbo.flush",
  CBO_INVAL <-> "cbo.inval"
}

mapping clause assembly = RISCV_ZICBOM(cbop, rs1)
  <-> cbop_mnemonic(cbop) ^ spc() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

val process_clean_inval : (regidx, cbop_zicbom) -> Retired
function process_clean_inval(rs1, cbop) = {
  let rs1_val = X(rs1);
  let cache_block_size_exp = plat_cache_block_size_exp();
  let cache_block_size = 2 ^ cache_block_size_exp;

  // Offset from rs1 to the beginning of the cache block. This is 0 if rs1
  // is aligned to the cache block, or negative if rs1 is misaligned.
  let offset = (rs1_val & ~(zero_extend(ones(cache_block_size_exp)))) - rs1_val;

  // TODO: This is incorrect since CHERI only requires at least one byte
  // to be in bounds here, whereas `ext_data_get_addr()` checks that all bytes
  // are in bounds. We will need to add a new function, parameter or access type.
  match ext_data_get_addr(rs1, offset, Read(Data), cache_block_size) {
    Ext_DataAddr_Error(e) => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) => {
      let res: option(ExceptionType) = match translateAddr(vaddr, Read(Data)) {
        TR_Address(paddr, _) => {
          // "A cache-block management instruction is permitted to access the
          // specified cache block whenever a load instruction or store instruction
          // is permitted to access the corresponding physical addresses. If
          // neither a load instruction nor store instruction is permitted to
          // access the physical addresses, but an instruction fetch is permitted
          // to access the physical addresses, whether a cache-block management
          // instruction is permitted to access the cache block is UNSPECIFIED."
          //
          // In this implementation we currently don't allow access for fetches.
          let exc_read = phys_access_check(Read(Data), cur_privilege, paddr, cache_block_size);
          let exc_write = phys_access_check(Write(Data), cur_privilege, paddr, cache_block_size);
          match (exc_read, exc_write) {
            // Access is permitted if read OR write are allowed. If neither
            // are allowed then we always report a store exception.
            (Some(exc_read), Some(exc_write)) => Some(exc_write),
            _ => None(),
          }
        },
        TR_Failure(e, _) => Some(e)
      };
      // "If access to the cache block is not permitted, a cache-block management
      //  instruction raises a store page fault or store guest-page fault exception
      //  if address translation does not permit any access or raises a store access
      //  fault exception otherwise."
      match res {
        // The model has no caches so there's no action required.
        None() => RETIRE_SUCCESS,
        Some(e) => {
          let e : ExceptionType = match e {
            E_Load_Access_Fault() => E_SAMO_Access_Fault(),
            E_SAMO_Access_Fault() => E_SAMO_Access_Fault(),
            E_Load_Page_Fault() => E_SAMO_Page_Fault(),
            E_SAMO_Page_Fault() => E_SAMO_Page_Fault(),
            // No other exceptions should be generated since we're not checking
            // for fetch access and it's can't be misaligned.
            _ => internal_error(__FILE__, __LINE__, "unexpected exception for cmo.clean/inval"),
          };
          // Errors report the address that was encoded in the instruction rather
          // than the address that caused the fault (i.e. the aligned address).
          handle_mem_exception(vaddr - offset, e);
          RETIRE_FAIL
        }
      }
    }
  }
}

function clause execute(RISCV_ZICBOM(cbop, rs1)) =
  match cbop {
    CBO_CLEAN if cbo_clean_flush_enabled(cur_privilege) =>
      process_clean_inval(rs1, cbop),
    CBO_FLUSH if cbo_clean_flush_enabled(cur_privilege) =>
      process_clean_inval(rs1, cbop),
    CBO_INVAL if cbo_inval_enabled(cur_privilege) =>
      process_clean_inval(rs1, if cbo_inval_as_inval(cur_privilege) then CBO_INVAL else CBO_FLUSH),
    _ => {
      handle_illegal();
      RETIRE_FAIL
    },
  }
