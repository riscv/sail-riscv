/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* This file implements utility functions for accessing memory that
 * can be used by instruction definitions.
 *
 * The external API of this module is:
 *
 *   check_misaligned - checks for the alignment of a virtual address given platform settings
 *
 *  These memory accessors take arguments specifying the registers containing the data and
 *  address values:
 *
 *   vmem_read -  performs address translation and retrieves data using Read(Data) accesses
 *   vmem_write - performs address translation and writes data using Write(Data) accesses
 */

/* This is a external option that controls the order in which the model
 * performs misaligned accesses.
 */
function sys_misaligned_order_decreasing() -> bool = config memory.misaligned.order_decreasing

/* This is an external option that, when true, causes all misaligned accesses
 * to be split into single byte operations.
 */
function sys_misaligned_to_byte() -> bool = config memory.misaligned.to_byte

/* This is an external option that returns an integer N, such that
 * when N is greater than zero, misaligned accesses to physical memory
 * (as atomic events) are allowed provided the access occurs within a N
 * byte region. N must be a power of two.
 *
 * This option cannot be unlimited (i.e. allowing all misaligned accesses
 * to be atomic) as this would be incorrect above the maximum supported
 * page size.
 */
function sys_misaligned_allowed_within() -> nat = config memory.misaligned.allowed_within

function clause currentlyEnabled(Ext_Zama16b) = hartSupports(Ext_Zama16b)

/* Check if an 'n byte access for an address is within an aligned 'r byte region */
val access_within : forall 'width 'n 'r, 1 <= 'n <= 'r. (bits('width), int('n), int('r)) -> bool

function access_within(addr, bytes, region_bytes) = {
  let low = addr & ~(get_slice_int(length(addr), region_bytes - 1, 0));
  let high = low + (region_bytes - 1);
  let addr_high = addr + (bytes - 1);
  low <=_u addr & addr <=_u addr_high & addr_high <=_u high
}

/* This property demonstrates that when bytes == region_bytes, the access_within check above is
 * equivalent to a regular alignment check (for a constrained set of inputs to help the SMT solver).
 */
$[property]
function prop_access_within_is_aligned(addr : bits(32), bytes : bits(4)) -> bool = {
  let bytes = unsigned(zero_extend(32, 0b1) << unsigned(bytes));
  if bytes > 0 then {
    access_within(addr, bytes, bytes) == (unsigned(addr) % bytes == 0)
  } else {
    true
  }
}

/* A 1-byte access is always within a 1-byte region. */
$[property]
function prop_access_within_single(addr : bits(32)) -> bool = {
  access_within(addr, 1, 1)
}

val allowed_misaligned : forall 'width, 'width > 0. (xlenbits, int('width)) -> bool

function allowed_misaligned(vaddr, width) = {
  let region_width = min_int(2 ^ pagesize_bits, sys_misaligned_allowed_within());

  // If the Zama16b extension is enabled, the region_width must be at least 16
  let region_width = if currentlyEnabled(Ext_Zama16b) then {
    max_int(16, region_width)
  } else {
    region_width
  };

  if width > region_width then return false;

  access_within(vaddr, width, region_width)
}

val split_misaligned : forall 'width, 'width > 0.
  (virtaddr, int('width)) -> {'n 'bytes, 'width == 'n * 'bytes & 'bytes > 0. (int('n), int('bytes))}

function split_misaligned(vaddr, width) = {
  let vaddr_bits = virtaddr_bits(vaddr);
  if is_aligned_addr(vaddr, width) | allowed_misaligned(vaddr_bits, width) then (1, width)
  else if sys_misaligned_to_byte() then (width, 1)
  else {
    let bytes_per_access = 2 ^ count_trailing_zeros(vaddr_bits);
    let num_accesses = width / bytes_per_access;
    assert(width == num_accesses * bytes_per_access);
    (num_accesses, bytes_per_access)
  }
}

type valid_misaligned_order('n, 'first, 'last, 'step) -> Bool =
    ('first == 0 & 'last == 'n - 1 & 'step == 1)
  | ('first == 'n - 1 & 'last == 0 & 'step == -1)

val misaligned_order : forall 'n.
  int('n) -> {'first 'last 'step, valid_misaligned_order('n, 'first, 'last, 'step). (int('first), int('last), int('step))}

function misaligned_order(n) = {
  if sys_misaligned_order_decreasing() then {
    (n - 1, 0, -1)
  } else {
    (0, n - 1, 1)
  }
}

/* External API */

function check_misaligned(vaddr : virtaddr, width : word_width) -> bool = {
  if plat_enable_misaligned_access() then {
    false
  } else {
    not(is_aligned_addr(vaddr, size_bytes(width)))
  }
}

val vmem_read : forall 'width, 'width in {1, 2, 4, 8} & 'width <= xlen_bytes.
  (regidx, xlenbits, int('width), bool, bool, bool) -> result(bits(8 * 'width), Retire_Failure)

function vmem_read(rs, offset, width, aq, rl, res) = {
  /* Get the address, X(rs1) + offset.
   * Some extensions perform additional checks on address validity.
   */
  let vaddr : virtaddr = match ext_data_get_addr(rs, offset, Read(Data), width) {
    Ext_DataAddr_OK(vaddr) => vaddr,
    Ext_DataAddr_Error(e)  => return Err(Ext_DataAddr_Check_Failure(e)),
  };

  // TODO: Rationalize to use a single alignment definition if possible.
  if res then {
    /* "LR faults like a normal load, even though it's in the AMO major opcode space."
     * - Andrew Waterman, isa-dev, 10 Jul 2018.
     */
    if   not(is_aligned_addr(vaddr, width))
    then return Err(Memory_Exception(vaddr, E_Load_Addr_Align()));
  } else {
    if check_misaligned(vaddr, size_bytes(width))
    then return Err(Memory_Exception(vaddr, E_Load_Addr_Align()));
  };

  /* If the load is misaligned, split into `n` (single-copy-atomic) memory operations,
     each of `bytes` width. If the load is aligned, then `n` = 1 and bytes will remain
     unchanged. */
  let ('n, bytes) = split_misaligned(vaddr, width);
  var data = zeros(8 * n * bytes);

  let (first, last, step) = misaligned_order(n);
  var i : range(0, 'n - 1) = first;
  var finished : bool = false;

  let vaddr = virtaddr_bits(vaddr);
  repeat {
    let offset = i;
    let vaddr = vaddr + (offset * bytes);
    match translateAddr(Virtaddr(vaddr), Read(Data)) {
      TR_Failure(e, _) => return Err(Memory_Exception(Virtaddr(vaddr), e)),

      TR_Address(paddr, _) => match mem_read(Read(Data), paddr, bytes, aq, rl, res) {
        Err(e) => return Err(Memory_Exception(Virtaddr(vaddr), e)),

        Ok(v) => {
          if res then {
            load_reservation(physaddr_bits(paddr))
          };

          data[(8 * (offset + 1) * bytes) - 1 .. 8 * offset * bytes] = v
        },
      }
    };

    if offset == last then {
      finished = true
    } else {
      i = offset + step
    }
  } until finished;

  Ok(data)
}

val vmem_write_addr : forall 'width, 'width in {1, 2, 4, 8} & 'width <= xlen_bytes.
  (virtaddr, int('width), bits(8 * 'width), bool, bool, bool) -> result(bool, Retire_Failure)

function vmem_write_addr(vaddr, width, data, aq, rl, res) = {
  /* If the store is misaligned, split into `n` (single-copy-atomic) memory operations,
     each of `bytes` width. If the store is aligned, then `n` = 1 and bytes will remain
     unchanged. */
  let ('n, bytes) = split_misaligned(vaddr, width);

  let (first, last, step) = misaligned_order(n);
  var i : range(0, 'n - 1) = first;
  var finished : bool = false;

  var write_success : bool = true;
  let vaddr = virtaddr_bits(vaddr);
  repeat {
    let offset = i;
    let vaddr = vaddr + (offset * bytes);
    match translateAddr(Virtaddr(vaddr), Write(Data)) {
      TR_Failure(e, _) => return Err(Memory_Exception(Virtaddr(vaddr), e)),

      /* NOTE: Currently, we only announce the effective address if address translation is successful.
         This may need revisiting, particularly in the misaligned case. */
      TR_Address(paddr, _) => {
        /* If res is true, the load should be aligned, and this loop should only execute once */
        if res & not(match_reservation(physaddr_bits(paddr))) then {
          write_success = false
        } else match mem_write_ea(paddr, bytes, aq, rl, res) {
          Err(e) => return Err(Memory_Exception(Virtaddr(vaddr), e)),

          Ok(()) => {
            let write_value = data[(8 * (offset + 1) * bytes) - 1 .. 8 * offset * bytes];
            match mem_write_value(paddr, bytes, write_value, aq, rl, res) {
              Err(e) => return Err(Memory_Exception(Virtaddr(vaddr), e)),
              Ok(s)  => write_success = write_success & s,
            }
          }
        }
      }
    };

    if offset == last then {
      finished = true
    } else {
      i = offset + step
    }
  } until finished;

  Ok(write_success)
}

/* Currently this function takes the X register index as an argument.
 * It does this so the register access only occurs after the effective
 * address for the access has been announced. This is for the RVWMO
 * operational model.
 */
// TODO: I think the above comment can be deleted according to
// https://github.com/riscv/sail-riscv/issues/766#issuecomment-2698992551
// I'm keeping it here for confirmation during code review.

val vmem_write : forall 'width, 'width in {1, 2, 4, 8} & 'width <= xlen_bytes.
  (regidx, xlenbits, int('width), regidx, bool, bool, bool) -> result(bool, Retire_Failure)

function vmem_write(rs_addr, offset, width, rs_data, aq, rl, res) = {
  /* Get the address, X(rs1) (no offset).
   * Extensions might perform additional checks on address validity.
   */
  let vaddr : virtaddr = match ext_data_get_addr(rs_addr, offset, Write(Data), width) {
    Ext_DataAddr_OK(vaddr) => vaddr,
    Ext_DataAddr_Error(e)  => return Err(Ext_DataAddr_Check_Failure(e)),
  };

  if res then {
    if not(is_aligned_addr(vaddr, width))
    then return Err(Memory_Exception(vaddr, E_SAMO_Addr_Align()));
  } else {
    if   check_misaligned(vaddr, size_bytes(width))
    then return Err(Memory_Exception(vaddr, E_SAMO_Addr_Align()));
  };

  let data = X(rs_data)[width * 8 - 1 .. 0];

  vmem_write_addr(vaddr, width, data, aq, rl, res)
}
