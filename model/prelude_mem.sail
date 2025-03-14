/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* These functions define the primitives for physical memory access.
 * They depend on the XLEN of the architecture.
 *
 * They also depend on the type of metadata that is read and written
 * to physical memory.  For models that do not require this metadata,
 * a unit type can be used.
 */

$include <concurrency_interface.sail>

enum write_kind = {
  Write_plain,
  Write_RISCV_release,
  Write_RISCV_strong_release,
  Write_RISCV_conditional,
  Write_RISCV_conditional_release,
  Write_RISCV_conditional_strong_release,
}

enum read_kind = {
  Read_plain,
  Read_ifetch,
  Read_RISCV_acquire,
  Read_RISCV_strong_acquire,
  Read_RISCV_reserved,
  Read_RISCV_reserved_acquire,
  Read_RISCV_reserved_strong_acquire,
}

enum barrier_kind = {
  Barrier_RISCV_rw_rw,
  Barrier_RISCV_r_rw,
  Barrier_RISCV_r_r,
  Barrier_RISCV_rw_w,
  Barrier_RISCV_w_w,
  Barrier_RISCV_w_rw,
  Barrier_RISCV_rw_r,
  Barrier_RISCV_r_w,
  Barrier_RISCV_w_r,
  Barrier_RISCV_tso,
  Barrier_RISCV_i,
}

/* Most of the above read/write_kinds are understood natively by the
   Sail concurrency interface, except for the strong acquire release
   variants which require an architecture specific access kind. */
struct RISCV_strong_access = {
  variety : Access_variety,
}

/* The Sail concurrency interface lets us have a physical address type
   with additional information, provided we can supply a function that
   converts it into a bitvector. When in RV32 mode, physaddrbits is
   bits(34), which needs to be zero-extended to bits(64) for
   sail_mem_write/read interface. This conversion is necessary because
   the memory interface only supports 32-bit or 64-bit physical
   addresses regardless of the actual physical address width. */
val physaddrbits_zero_extend : physaddrbits -> bits(64)

function physaddrbits_zero_extend xs = zero_extend(xs)

instantiation sail_mem_write with
  'pa = physaddrbits,
  pa_bits = physaddrbits_zero_extend,
  /* We don't have a relaxed-memory translation model for RISC-V, so
     we just use unit as a dummy type. */
  'translation_summary = unit,
  'arch_ak = RISCV_strong_access,
  /* Similarly to translation_summary, we don't have a defined type for external
     aborts, so just use unit here too */
  'abort = unit

val write_ram : forall 'n, 0 < 'n <= max_mem_access. (write_kind, physaddr, int('n), bits(8 * 'n), mem_meta) -> bool

function write_ram(wk, physaddr(addr), width, data, meta) = {
  let request : Mem_write_request('n, 64, physaddrbits, unit, RISCV_strong_access) = struct {
    access_kind = match wk {
      Write_plain => AK_explicit(struct { variety = AV_plain, strength = AS_normal }),
      Write_RISCV_release => AK_explicit(struct { variety = AV_plain, strength = AS_rel_or_acq }),
      Write_RISCV_strong_release => AK_arch(struct { variety = AV_plain }),
      Write_RISCV_conditional => AK_explicit(struct { variety = AV_exclusive, strength = AS_normal }),
      Write_RISCV_conditional_release => AK_explicit(struct { variety = AV_exclusive, strength = AS_rel_or_acq }),
      Write_RISCV_conditional_strong_release => AK_arch(struct { variety = AV_exclusive }),
    },
    va = None(),
    pa = addr,
    translation = (),
    size = width,
    value = Some(data),
    tag = None(),
  };
  /* Write out metadata only if the value write succeeds.
   * It is assumed for now that this write always succeeds;
   * there is currently no return value.
   * FIXME: We should convert the external API for all backends
   * (not just for Lem) to consume the value along with the
   * metadata to ensure atomicity.
   */
  match sail_mem_write(request) {
    Ok(_) => {
      __WriteRAM_Meta(addr, width, meta);
      true
    },
    Err() => false,
  }
}

val write_ram_ea : forall 'n, 0 < 'n <= max_mem_access. (write_kind, physaddr, int('n)) -> unit
function write_ram_ea(wk, physaddr(addr), width) = ()

instantiation sail_mem_read with
  pa_bits = physaddrbits_zero_extend

val read_ram : forall 'n, 0 < 'n <= max_mem_access.  (read_kind, physaddr, int('n), bool) -> (bits(8 * 'n), mem_meta)
function read_ram(rk, physaddr(addr), width, read_meta) = {
  let meta = if read_meta then __ReadRAM_Meta(addr, width) else default_meta;
  let request : Mem_read_request('n, 64, physaddrbits, unit, RISCV_strong_access) = struct {
    access_kind = match rk {
      Read_plain => AK_explicit(struct { variety = AV_plain, strength = AS_normal }),
      Read_ifetch => AK_ifetch(),
      Read_RISCV_acquire => AK_explicit(struct { variety = AV_plain, strength = AS_rel_or_acq }),
      Read_RISCV_strong_acquire => AK_arch(struct { variety = AV_plain }),
      Read_RISCV_reserved => AK_explicit(struct { variety = AV_exclusive, strength = AS_normal }),
      Read_RISCV_reserved_acquire => AK_explicit(struct { variety = AV_exclusive, strength = AS_rel_or_acq }),
      Read_RISCV_reserved_strong_acquire => AK_arch(struct { variety = AV_exclusive }),
    },
    va = None(),
    pa = addr,
    translation = (),
    size = width,
    tag = false,
  };
  match sail_mem_read(request) {
    Ok((value, _)) => (value, meta),
    Err() => exit(),
  }
}

instantiation sail_barrier with 'barrier = barrier_kind

val __TraceMemoryWrite : forall 'n 'm. (int('n), bits('m), bits(8 * 'n)) -> unit
val __TraceMemoryRead  : forall 'n 'm. (int('n), bits('m), bits(8 * 'n)) -> unit
