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
 * These memory accessors performs address translation and return a
 * Retire_Failure on error.  In order to support RVWMO memory model,
 * address and when possible data arguments are passed as their source
 * registers.
 *
 * All addresses are provided in integer source register arguments.
 * For write accessors, there are functions for each kind of source
 * data register type (integer, floating point, vector).
 *
 * The external API of this module is:
 *
 *   check_misaligned - checks for the alignment of a virtual address given platform settings
 *
 *   vmem_read        - reads data of the specified width
 *   vmem_write       - writes a specified data payload
 */

/* This is a external option that controls the order in which the model
 * performs misaligned accesses.
 */
let sys_misaligned_order_decreasing : bool = config memory.misaligned.order_decreasing

/* This is an external option that, when true, causes all misaligned accesses
 * to be split into single byte operations.  Otherwise, misaligned accesses
 * are split into multiple accesses of smaller widths such that each of the latter
 * accesses is aligned.
 */
let sys_misaligned_byte_by_byte : bool = config memory.misaligned.byte_by_byte

/* This is an external option that returns an integer N, such that
 * when N is greater than zero, misaligned accesses to physical memory
 * (as atomic events) are allowed provided the access occurs within a
 * naturally aligned 2^N byte region.  This region must be smaller than
 * the page size (i.e. 2^12 = 4096 bytes).
 */
let sys_misaligned_allowed_within_exp : range(0, 11) = config memory.misaligned.allowed_within_exp

/* Check if an 'n byte access for an address is within an aligned 2^'r byte region */
val access_within : forall 'width 'n ('r : Nat), 'r <= 'width & 1 <= 'n <= 2^'r.
  (bits('width), int('n), int('r)) -> bool
function access_within(addr, bytes, region_width_exp) = {
  let mask : bits('width) = ~(zero_extend(ones(region_width_exp)));
  (addr & mask) == ((addr + (bytes - 1)) & mask)
}

/* This property demonstrates that when bytes == 2^region_width_exp, the access_within check above is
 * equivalent to a regular alignment check (for a constrained set of inputs to help the SMT solver).
 */
$[property]
function prop_access_within_is_aligned(addr : bits(32), region_width_exp : bits(4)) -> bool = {
  let region_width_exp = unsigned(region_width_exp);
  let bytes = 2 ^ region_width_exp;
  access_within(addr, bytes, region_width_exp) == (unsigned(addr) % bytes == 0)
}

/* A 1-byte access is always within a 2^0 = 1-byte region. */
$[property]
function prop_access_within_single(addr : bits(32)) -> bool = {
  access_within(addr, 1, 0)
}

val allowed_misaligned : forall 'width, 'width > 0. (xlenbits, int('width)) -> bool

function allowed_misaligned(vaddr, width) = {
  let region_width_exp = sys_misaligned_allowed_within_exp;
  let region_width = 2 ^ region_width_exp;

  if width > region_width then return false;

  access_within(vaddr, width, region_width_exp)
}

val split_misaligned : forall 'width, 'width > 0.
  (virtaddr, int('width)) -> {'n 'bytes, 'width == 'n * 'bytes & 'bytes > 0. (int('n), int('bytes))}

function split_misaligned(vaddr, width) = {
  let vaddr_bits = bits_of(vaddr);
  if is_aligned_addr(vaddr, width) | allowed_misaligned(vaddr_bits, width) then (1, width)
  else if sys_misaligned_byte_by_byte then (width, 1)
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
  if sys_misaligned_order_decreasing then {
    (n - 1, 0, -1)
  } else {
    (0, n - 1, 1)
  }
}

val vmem_write_addr : forall 'width, is_mem_width('width).
  (virtaddr, int('width), bits(8 * 'width), AccessType(ext_access_type), bool, bool, bool)
  -> result(bool, ExecutionResult)

function vmem_write_addr(vaddr, width, data, acc, aq, rl, res) = {
  /* If the store is misaligned or an allowed misaligned access, split into `n`
     (single-copy-atomic) memory operations, each of `bytes` width. If the store is
     aligned, then `n` = 1 and bytes will remain unchanged. */
  let ('n, 'bytes) = split_misaligned(vaddr, width);

  let (first, last, step) = misaligned_order(n);
  var i : range(0, 'n - 1) = first;
  var finished : bool = false;

  var write_success : bool = true;
  let vaddr = bits_of(vaddr);
  repeat {
    let offset = i;
    let vaddr = vaddr + (offset * bytes);
    match translateAddr(Virtaddr(vaddr), acc) {
      Err(e, _) => return Err(Memory_Exception(Virtaddr(vaddr), e)),

      /* NOTE: Currently, we only announce the effective address if address translation is successful.
         This may need revisiting, particularly in the misaligned case. */
      Ok(paddr, _) => {
        /* If res is true, the load should be aligned, and this loop should only execute once */
        if res & not(match_reservation(bits_of(paddr))) then {
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

/****    External API    ****/

function check_misaligned(vaddr : virtaddr, width : word_width) -> bool = {
  if plat_enable_misaligned_access then {
    false
  } else {
    not(is_aligned_addr(vaddr, width))
  }
}

val vmem_read : forall 'width, is_mem_width('width).
  (regidx, xlenbits, int('width), AccessType(ext_access_type), bool, bool, bool)
  -> result(bits(8 * 'width), ExecutionResult)

function vmem_read(rs, offset, width, acc, aq, rl, res) = {
  /* Get the address, X(rs1) + offset.
   * Some extensions perform additional checks on address validity.
   */
  let vaddr : virtaddr = match ext_data_get_addr(rs, offset, acc, width) {
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
    if check_misaligned(vaddr, width)
    then return Err(Memory_Exception(vaddr, E_Load_Addr_Align()));
  };

  /* If the load is misaligned or an allowed misaligned access, split into `n`
     (single-copy-atomic) memory operations, each of `bytes` width. If the load is
     aligned, then `n` = 1 and bytes will remain unchanged. */
  let ('n, 'bytes) = split_misaligned(vaddr, width);
  var data = zeros(8 * n * bytes);

  let (first, last, step) = misaligned_order(n);
  var i : range(0, 'n - 1) = first;
  var finished : bool = false;

  let vaddr = bits_of(vaddr);
  repeat {
    let offset = i;
    let vaddr = vaddr + (offset * bytes);
    match translateAddr(Virtaddr(vaddr), acc) {
      Err(e, _) => return Err(Memory_Exception(Virtaddr(vaddr), e)),

      Ok(paddr, _) => match mem_read(acc, paddr, bytes, aq, rl, res) {
        Err(e) => return Err(Memory_Exception(Virtaddr(vaddr), e)),

        Ok(v) => {
          if res then {
            load_reservation(bits_of(paddr))
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

val vmem_write : forall 'width, is_mem_width('width).
  (regidx, xlenbits, int('width), bits(8 * 'width), AccessType(ext_access_type), bool, bool, bool)
  -> result(bool, ExecutionResult)

function vmem_write(rs_addr, offset, width, data, acc, aq, rl, res) = {
  /* Get the address, X(rs_addr) (no offset).
   * Extensions might perform additional checks on address validity.
   */
  let vaddr : virtaddr = match ext_data_get_addr(rs_addr, offset, acc, width) {
    Ext_DataAddr_OK(vaddr) => vaddr,
    Ext_DataAddr_Error(e)  => return Err(Ext_DataAddr_Check_Failure(e)),
  };

  if   check_misaligned(vaddr, width)
  then return Err(Memory_Exception(vaddr, E_SAMO_Addr_Align()));

  vmem_write_addr(vaddr, width, data, acc, aq, rl, res)
}
