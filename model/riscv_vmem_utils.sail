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
val sys_misaligned_order_decreasing = {
  ocaml: "Platform.misaligned_order_decreasing",
  _: "sys_misaligned_order_decreasing"
} : unit -> bool

/* This is an external option that, when true, causes all misaligned accesses
 * to be split into single byte operations.
 */
val sys_misaligned_to_byte = {
  ocaml: "Platform.misaligned_to_byte",
  _: "sys_misaligned_to_byte"
} : unit -> bool

val split_misaligned : forall 'width, 'width in {1, 2, 4, 8}.
  (xlenbits, int('width)) -> {'n 'bytes, 'width == 'n * 'bytes & 'bytes > 0. (int('n), int('bytes))}

function split_misaligned(vaddr, width) = {
  let misaligned_to_byte = sys_misaligned_to_byte();
  match width {
    1 => (1, 1),

    2 if is_aligned_addr(vaddr, 2) => (1, 2),
    2 => (2, 1),

    4 if is_aligned_addr(vaddr, 4) => (1, 4),
    4 if is_aligned_addr(vaddr, 2) & not(misaligned_to_byte) => (2, 2),
    4 => (4, 1),

    8 if is_aligned_addr(vaddr, 8) => (1, 8),
    8 if is_aligned_addr(vaddr, 4) & not(misaligned_to_byte) => (2, 4),
    8 if is_aligned_addr(vaddr, 2) & not(misaligned_to_byte) => (4, 2),
    8 => (8, 1)
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
val vmem_write_from_register : forall 'width, 'width in {1, 2, 4, 8} & 'width <= xlen_bytes.
  (xlenbits, int('width), range(0, 31), bool, bool, bool) -> result(unit, (xlenbits, ExceptionType))

function vmem_write_from_register(vaddr, bytes, reg, aq, rl, res) = {
  /* If the store is misaligned, split into `n` (single-copy-atomic) memory operations,
     each of `bytes` width. If the store is aligned, then `n` = 1 and bytes will remain
     unchanged. */
  let ('n, bytes) = split_misaligned(vaddr, bytes);

  let (first, last, step) = misaligned_order(n);
  var i : range(0, 'n - 1) = first;
  var finished : bool = false;

  repeat {
    let offset = i;
    let vaddr = vaddr + (offset * bytes);
    match translateAddr(vaddr, Write(Data)) {
      TR_Failure(e, _) => return Err(vaddr, e),

      /* NOTE: Currently, we only announce the effective address if address translation is successful.
         This may need revisiting, particularly in the misaligned case. */
      TR_Address(paddr, _) => match mem_write_ea(paddr, bytes, aq, rl, false) {
        MemException(e) => return Err(vaddr, e),

        MemValue(()) => {
          let reg_val = X(reg);
          let data = reg_val[(8 * (offset + 1) * bytes) - 1 .. 8 * offset * bytes];
          match mem_write_value(paddr, bytes, data, aq, rl, false) {
            MemException(e) => return Err(vaddr, e),
            MemValue(true)  => (),
            MemValue(false) =>
              internal_error(__FILE__, __LINE__, "got false from mem_write_value"),
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

  Ok()
}
