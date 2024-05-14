/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* This file implements utility functions for accessing memory that
 * can be used by instruction definitions.
 */

/* This is a external option that controls the order in which the model
 * performs misaligned accesses.
 */
val sys_misaligned_order_decreasing = pure "sys_misaligned_order_decreasing" : unit -> bool

/* This is an external option that, when true, causes all misaligned accesses
 * to be split into single byte operations.
 */
val sys_misaligned_to_byte = pure "sys_misaligned_to_byte" : unit -> bool

/* This is an external option that returns an integer N, such that
 * when N is greater than zero, misaligned accesses to physical memory
 * (as atomic events) are allowed provided the access occurs within a N
 * byte region. N must be a power of two.
 *
 * This option cannot be unlimited (i.e. allowing all misaligned accesses
 * to be atomic) as this would be incorrect above the maximum supported
 * page size.
 */
val sys_misaligned_allowed_within = pure "sys_misaligned_allowed_within" : unit -> bits(64)

/* The Zama16b extensions implies that misaligned loads, stores, and
 * AMOs to main memory regions that do not cross a naturally aligned
 * 16-byte boundary are atomic.
 */
enum clause extension = Ext_Zama16b

val sys_enable_zama16b = pure "sys_enable_zama16b" : unit -> bool

function clause extensionEnabled(Ext_Zama16b) = sys_enable_zama16b()

/* Check if an 'n byte access for an address is within an aligned 'r byte region */
val access_within : forall 'width 'n 'r, 1 <= 'n <= 'r. (bits('width), int('n), int('r)) -> bool

function access_within(addr, bytes, region_bytes) = {
  let low = addr & ~(get_slice_int(length(addr), bytes - 1, 0));
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
    access_within(addr, bytes, bytes) == (fmod_int(unsigned(addr), bytes) == 0)
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
  let region_width = min_int(2 ^ pagesize_bits, unsigned(sys_misaligned_allowed_within()));

  // If the Zama16b extension is enabled, the region_width must be at least 16
  let region_width = if extensionEnabled(Ext_Zama16b) then {
    max_int(16, region_width)
  } else {
    region_width
  };

  if width > region_width then return false;

  access_within(vaddr, width, region_width)
}

val count_trailing_zeros : forall 'n, 'n >= 0. (bits('n)) -> range(0, 'n)

function count_trailing_zeros(xs) = {
  foreach (i from 0 to (length(xs) - 1)) {
    if xs[i] == bitone then return i;
  };
  length(xs)
}

val split_misaligned : forall 'width, 'width > 0.
  (xlenbits, int('width)) -> {'n 'bytes, 'width == 'n * 'bytes & 'bytes > 0. (int('n), int('bytes))}

function split_misaligned(vaddr, width) = {
  if is_aligned_addr(vaddr, width) | allowed_misaligned(vaddr, width) then (1, width)
  else if sys_misaligned_to_byte() then (width, 1)
  else {
    let num_accesses = 2 ^ count_trailing_zeros(vaddr);
    let bytes_per_access = width / num_accesses;
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

val vmem_read : forall 'width, 'width in {1, 2, 4, 8} & 'width <= xlen_bytes.
  (xlenbits, int('width), bool, bool, bool) -> result(bits(8 * 'width), (xlenbits, ExceptionType))

function vmem_read(vaddr, bytes, aq, rl, res) = {
  /* If the load is misaligned, split into `n` (single-copy-atomic) memory operations,
     each of `bytes` width. If the load is aligned, then `n` = 1 and bytes will remain
     unchanged. */
  let ('n, bytes) = split_misaligned(vaddr, bytes);
  var data = zeros(8 * n * bytes);

  let (first, last, step) = misaligned_order(n);
  var i : range(0, 'n - 1) = first;
  var finished : bool = false;

  repeat {
    let offset = i;
    let vaddr = vaddr + (offset * bytes);
    match translateAddr(vaddr, Read(Data)) {
      TR_Failure(e, _) => return Err(vaddr, e),

      TR_Address(paddr, _) => match mem_read(Read(Data), paddr, bytes, aq, rl, res) {
        MemException(e) => return Err(vaddr, e),

        MemValue(v) => {
          if res then {
            load_reservation(paddr)
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

/* Currently this function takes the X register index as an argument.
 * It does this so the register access only occurs after the effective
 * address for the access has been announced. This is for the RVWMO
 * operational model.
 */
val vmem_write : forall 'width, 'width in {1, 2, 4, 8} & 'width <= xlen_bytes.
  (xlenbits, int('width), bits(8 * 'width), bool, bool, bool) -> result(bool, (xlenbits, ExceptionType))

function vmem_write(vaddr, bytes, data, aq, rl, res) = {
  /* If the store is misaligned, split into `n` (single-copy-atomic) memory operations,
     each of `bytes` width. If the store is aligned, then `n` = 1 and bytes will remain
     unchanged. */
  let ('n, bytes) = split_misaligned(vaddr, bytes);

  let (first, last, step) = misaligned_order(n);
  var i : range(0, 'n - 1) = first;
  var finished : bool = false;

  var write_success : bool = true;

  repeat {
    let offset = i;
    let vaddr = vaddr + (offset * bytes);
    match translateAddr(vaddr, Write(Data)) {
      TR_Failure(e, _) => return Err(vaddr, e),

      /* NOTE: Currently, we only announce the effective address if address translation is successful.
         This may need revisiting, particularly in the misaligned case. */
      TR_Address(paddr, _) => {
        /* If res is true, the load should be aligned, and this loop should only execute once */
        if res & not(match_reservation(paddr)) then {
          write_success = false
        } else match mem_write_ea(paddr, bytes, aq, rl, res) {
          MemException(e) => return Err(vaddr, e),

          MemValue(()) => {
            let write_value = data[(8 * (offset + 1) * bytes) - 1 .. 8 * offset * bytes];
            match mem_write_value(paddr, bytes, write_value, aq, rl, res) {
              MemException(e) => return Err(vaddr, e),
              MemValue(s)  => write_success = write_success & s,
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
