#!/usr/bin/env python3
# Negative tests for rvviTextChecker.py and lint_rvvi_trace.py.
from __future__ import annotations

import io
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import lint_rvvi_trace  # noqa: E402
import rvviTextChecker  # noqa: E402


HEADER = """\
VERSION 0 5
VENDOR "sail_riscv" 0 1
PARAMS 6 ILEN 32 XLEN 64 FLEN 64 VLEN 256 NHART 1 RETIRE 1
"""

# ld a3, 0(t0)  and  sd a2, 0(t0)
LD = "0x0002B683"
SD = "0x00C2B023"
ADD = "0x00A605B3"  # add a1, a2, a0 — not a memory insn


def check_ok(text: str) -> bool:
    return rvviTextChecker.check_file(rvviTextChecker.CheckState(), io.StringIO(text))


class CheckerTests(unittest.TestCase):
    def test_pte_hex_is_accepted(self):
        text = HEADER + (
            f"HART 0 RET 0x80000000 {LD} X 13 0x0000000000000001 "
            "MEM I 4 0x80000000 0x80000000 0 "
            "MEM D 8 0x80001000 0x80001000 2 PTE 0x00000000000000CF PT G "
            "MODE 0x3 VIRT 0x0\n"
        )
        self.assertTrue(check_ok(text), "spec-compliant PTE hex must pass the checker")

    def test_pt_letter_is_accepted(self):
        text = HEADER + (
            f"HART 0 RET 0x80000000 {LD} X 13 0x0000000000000001 "
            "MEM I 4 0x80000000 0x80000000 0 "
            "MEM D 8 0x80001000 0x80001000 1 PT M "
            "MODE 0x3 VIRT 0x0\n"
        )
        self.assertTrue(check_ok(text))

    def test_bad_bus_is_rejected(self):
        text = HEADER + (
            f"HART 0 RET 0x80000000 {LD} X 13 0x0000000000000001 "
            "MEM X 8 0x80001000 0x80001000 0 MODE 0x3 VIRT 0x0\n"
        )
        self.assertFalse(check_ok(text))

    def test_zero_mem_bytes_rejected(self):
        text = HEADER + (
            f"HART 0 RET 0x80000000 {LD} X 13 0x0000000000000001 "
            "MEM D 0 0x80001000 0x80001000 0 MODE 0x3 VIRT 0x0\n"
        )
        self.assertFalse(check_ok(text))


class LintTests(unittest.TestCase):
    def test_correct_ld_passes(self):
        text = HEADER + (
            f"HART 0 RET 0x80000000 {LD} X 13 0x0000000000000001 "
            "MEM I 4 0x80000000 0x80000000 0 "
            "MEM D 8 0x80001000 0x80001000 0 MODE 0x3 VIRT 0x0\n"
        )
        self.assertEqual(lint_rvvi_trace.lint_trace(text), [])

    def test_ld_width_4_is_caught(self):
        text = HEADER + (
            f"HART 0 RET 0x80000000 {LD} X 13 0x0000000000000001 "
            "MEM I 4 0x80000000 0x80000000 0 "
            "MEM D 4 0x80001000 0x80001000 0 MODE 0x3 VIRT 0x0\n"
        )
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(any("bytes=8" in e or "bytes=4" in e for e in errors), errors)

    def test_store_without_mem_is_caught(self):
        text = HEADER + (
            f"HART 0 RET 0x80000000 {SD} "
            "MEM I 4 0x80000000 0x80000000 0 MODE 0x3 VIRT 0x0\n"
        )
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(any("missing MEM D" in e for e in errors), errors)

    def test_missing_fetch_is_caught(self):
        text = HEADER + (
            f"HART 0 RET 0x80000000 {LD} X 13 0x0000000000000001 "
            "MEM D 8 0x80001000 0x80001000 0 MODE 0x3 VIRT 0x0\n"
        )
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(any("MEM I" in e for e in errors), errors)

    def test_non_mem_insn_with_mem_d_is_caught(self):
        text = HEADER + (
            f"HART 0 RET 0x80000000 {ADD} X 11 0x0000000000000001 "
            "MEM I 4 0x80000000 0x80000000 0 "
            "MEM D 4 0x80001000 0x80001000 0 MODE 0x3 VIRT 0x0\n"
        )
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(any("non-memory" in e for e in errors), errors)

    def test_missing_rd_is_caught(self):
        text = HEADER + (
            f"HART 0 RET 0x80000000 {LD} "
            "MEM I 4 0x80000000 0x80000000 0 "
            "MEM D 8 0x80001000 0x80001000 0 MODE 0x3 VIRT 0x0\n"
        )
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(any("missing X 13" in e for e in errors), errors)


class LintResetLeakTests(unittest.TestCase):

    # JAL x1, 0  (rd=1)
    JAL_X1 = "0x000000EF"
    # ADDI a0, a0, 1  (opcode OP-IMM, rd=10)
    ADDI_A0 = "0x00150513"

    def _make_ret(self, insn_hex, extra=""):
        return (
            HEADER
            + "HART 0 RET 0x80000000 " + insn_hex + " "
            + extra
            + "MEM I 4 0x80000000 0x80000000 0 MODE 0x3 VIRT 0x0\n"
        )

    # -- C records on no-CSR-write opcodes --

    def test_jal_with_csr_record_is_caught(self):
        text = self._make_ret(
            self.JAL_X1,
            "X 1 0x0000000000000004 C 0x301 0x8000000000141101 ",
        )
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(
            any("reset-state" in e or "must not write CSR" in e for e in errors),
            "expected reset-state leak error, got: " + str(errors),
        )

    def test_arithmetic_with_csr_record_is_caught(self):
        text = self._make_ret(
            self.ADDI_A0,
            "X 10 0x0000000000000001 C 0x300 0x0000000A00001800 ",
        )
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(
            any("reset-state" in e or "must not write CSR" in e for e in errors),
            "expected reset-state leak error, got: " + str(errors),
        )

    # -- rd consistency on jump/arith opcodes --

    def test_jal_missing_rd_x_is_caught(self):
        text = self._make_ret(self.JAL_X1)
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(
            any("x1" in e or "rd=x1" in e or "missing X 1" in e for e in errors),
            "expected missing-rd error, got: " + str(errors),
        )

    def test_jal_rd0_with_x_record_is_caught(self):
        # JAL x0, 0
        text = self._make_ret(
            "0x0000006F",
            "X 1 0x0000000000000004 ",
        )
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(
            any("rd=x0" in e or "must not have X" in e for e in errors),
            "expected rd=x0 X-record error, got: " + str(errors),
        )

    def test_branch_with_x_record_is_caught(self):
        # BEQ x0, x0, 0
        text = self._make_ret(
            "0x00000063",
            "X 1 0x0000000000000004 ",
        )
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(
            any("has no rd" in e or "no rd" in e or "X records" in e for e in errors),
            "expected branch-has-no-rd error, got: " + str(errors),
        )

    # -- Positive: correct jal/addi must still pass --

    def test_correct_jal_passes(self):
        text = self._make_ret(self.JAL_X1, "X 1 0x0000000000000004 ")
        self.assertEqual(lint_rvvi_trace.lint_trace(text), [])

    def test_correct_addi_passes(self):
        text = self._make_ret(self.ADDI_A0, "X 10 0x0000000000000001 ")
        self.assertEqual(lint_rvvi_trace.lint_trace(text), [])


class LintModeAndAmoTests(unittest.TestCase):
    MRET = "0x30200073"
    # ADDI a0, a0, 1  (opcode OP-IMM, rd=10)
    ADDI_A0 = "0x00150513"
    # LR.D t1, 0(t0) / SC.D t2, 0(t0) / AMOADD.D t2, t1, (t0)
    LR_D = "0x1050332F"
    SC_D = "0x185033AF"
    AMOADD_D = "0x005333AF"
    # VLE32.V v1, 0(a0) — unit-stride, LOAD-FP opcode
    VLE32_V = "0x02052087"

    def _lines(self, *lines):
        return HEADER + "".join(lines)

    def _ret(self, insn_hex, extra="", mode="0x3"):
        return (
            "HART 0 RET 0x80000000 " + insn_hex + " " + extra
            + "MEM I 4 0x80000000 0x80000000 0 MODE " + mode + " VIRT 0x0\n"
        )

    # -- MODE changes --

    def test_mode_change_after_mret_passes(self):
        text = self._lines(
            self._ret(self.MRET, "X 1 0x0000000000000002 "),
            self._ret(self.ADDI_A0, "X 10 0x0000000000000001 ", mode="0x1"),
        )
        self.assertEqual(lint_rvvi_trace.lint_trace(text), [])

    def test_mode_change_after_trap_passes(self):
        trap_line = (
            "HART 0 TRAP 0x80000010 0x00000073 "
            "MEM I 4 0x80000010 0x80000010 0 MODE 0x3 VIRT 0x0\n"
        )
        text = self._lines(
            self._ret(self.ADDI_A0, "X 10 0x0000000000000001 "),
            trap_line,
            self._ret(self.ADDI_A0, "X 10 0x0000000000000002 ", mode="0x1"),
        )
        self.assertEqual(lint_rvvi_trace.lint_trace(text), [])

    def test_unexplained_mode_change_is_caught(self):
        text = self._lines(
            self._ret(self.ADDI_A0, "X 10 0x0000000000000001 "),
            self._ret(self.ADDI_A0, "X 10 0x0000000000000002 ", mode="0x1"),
        )
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(any("MODE changed" in e for e in errors), errors)

    # -- AMO / SC --

    def test_failed_sc_without_mem_d_passes(self):
        text = self._lines(self._ret(self.SC_D, "X 7 0x0000000000000001 "))
        self.assertEqual(lint_rvvi_trace.lint_trace(text), [])

    def test_successful_sc_with_dual_mem_d_passes(self):
        text = self._lines(
            self._ret(
                self.SC_D,
                "X 7 0x0000000000000000 "
                "MEM D 8 0x80001000 0x80001000 0 "
                "MEM D 8 0x80001000 0x80001000 0 ",
            )
        )
        self.assertEqual(lint_rvvi_trace.lint_trace(text), [])

    def test_amo_wrong_width_is_caught(self):
        text = self._lines(
            self._ret(
                self.AMOADD_D,
                "X 7 0x0000000000000001 "
                "MEM D 4 0x80001000 0x80001000 0 ",
            )
        )
        errors = lint_rvvi_trace.lint_trace(text)
        self.assertTrue(any("AMO expected MEM D bytes=8" in e for e in errors), errors)

    # Vector loads share LOAD-FP and emit one MEM D per element.

    def test_vector_load_per_element_mem_d_passes(self):
        mems = " ".join(
            f"MEM D 4 0x{0x80001000 + 4 * i:X} 0x{0x80001000 + 4 * i:X} 0"
            for i in range(8)
        )
        text = self._lines(self._ret(self.VLE32_V, "V 1 0x0000000000000000 " + mems + " "))
        self.assertEqual(lint_rvvi_trace.lint_trace(text), [])


if __name__ == "__main__":
    unittest.main()
