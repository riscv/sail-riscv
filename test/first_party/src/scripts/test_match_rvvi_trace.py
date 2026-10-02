#!/usr/bin/env python3
from __future__ import annotations

import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from match_rvvi_trace import match_events
from rvvi_trace import (
    last_write_wins,
    mnemonic,
    parse_event_line,
    parse_trace,
)

HEADER = """VERSION 0 5
VENDOR "sail_riscv" 0 1
PARAMS 6 ILEN 32 XLEN 64 FLEN 64 VLEN 256 NHART 1 RETIRE 1
"""


class ParseTests(unittest.TestCase):
    def test_last_write_wins_keeps_final_value(self):
        self.assertEqual(
            last_write_wins([(1, "0x1"), (1, "0x2"), (2, "0x3")]), {1: 2, 2: 3}
        )

    def test_duplicate_v_on_one_line(self):
        line = (
            "HART 0 RET 0x80002000 0x02056087 "
            "V 1 0x1 V 1 0x2 MEM D 4 0x80001000 0x80001000 0 MODE 0x3 VIRT 0x0"
        )
        ev = parse_event_line(line)
        self.assertEqual(ev["v"], {1: 2})

    def test_mnemonic_load_store(self):
        self.assertEqual(mnemonic(0x00028383, 64), "lb")  # lb t2, 0(t0)
        self.assertEqual(mnemonic(0x00628023, 64), "sb")
        self.assertEqual(mnemonic(0x0002B303, 64), "ld")
        self.assertEqual(mnemonic(0x0062A3AF, 64), "amoadd.w")
        self.assertEqual(mnemonic(0x00000073, 64), "ecall")
        self.assertEqual(mnemonic(0x30200073, 64), "mret")
        self.assertEqual(mnemonic(0xC10C, 64), "c.sw")
        self.assertEqual(mnemonic(0x4110, 64), "c.lw")
        self.assertEqual(mnemonic(0x02056087, 64), "vle32.v")
        self.assertEqual(mnemonic(0x0002B507, 64), "fld")


class MatchTests(unittest.TestCase):
    def _ev(self, extra: str, insn="0x00628023", event="RET"):
        line = f"HART 0 {event} 0x80002000 {insn} {extra} MODE 0x3 VIRT 0x0"
        return parse_event_line(line)

    def test_subsequence_skips_unrelated(self):
        events = [
            self._ev("", insn="0x06400513"),  # addi
            self._ev("MEM D 1 0x80001000 0x80001000 0", insn="0x00628023"),  # sb
        ]
        errors = match_events(events, {"events": [{"match": "sb", "mem_d": [1]}]}, 64)
        self.assertEqual(errors, [])

    def test_wrong_width_is_caught(self):
        events = [self._ev("MEM D 4 0x80001000 0x80001000 0", insn="0x00628023")]
        errors = match_events(events, {"events": [{"match": "sb", "mem_d": [1]}]}, 64)
        self.assertTrue(any("mem_d" in e for e in errors), errors)

    def test_overlap_without_allow_is_caught(self):
        extra = "MEM D 4 0x80003260 0x80003260 0 MEM D 4 0x80003260 0x80003260 0"
        events = [self._ev(extra, insn="0x0062A3AF")]
        errors = match_events(
            events, {"events": [{"match": "amoadd.w", "mem_d": [4]}]}, 64
        )
        self.assertTrue(any("overlap" in e or "mem_d" in e for e in errors), errors)

    def test_overlap_allowed_coalesces(self):
        extra = "MEM D 4 0x80003260 0x80003260 0 MEM D 4 0x80003260 0x80003260 0"
        events = [self._ev(extra, insn="0x0062A3AF")]
        errors = match_events(
            events,
            {"events": [{"match": "amoadd.w", "mem_d": [4], "allow_overlap": True}]},
            64,
        )
        self.assertEqual(errors, [])

    def test_when_xlen_skips(self):
        events = [self._ev("MEM D 4 0x1 0x1 0", insn="0x0062A023")]  # sw
        golden = {
            "events": [
                {"match": "sd", "when": "xlen==64", "mem_d": [8]},
                {"match": "sw", "when": "xlen==32", "mem_d": [4]},
            ]
        }
        self.assertEqual(match_events(events, golden, 32), [])

    def test_parse_trace_header(self):
        text = HEADER + (
            "HART 0 RET 0x80002000 0x00628023 "
            "MEM I 4 0x80002000 0x80002000 0 "
            "MEM D 1 0x80001000 0x80001000 0 MODE 0x3 VIRT 0x0\n"
        )
        params, events = parse_trace(text)
        self.assertEqual(params["XLEN"], "64")
        self.assertEqual(len(events), 1)
        self.assertEqual([m["bus"] for m in events[0]["mem"]], ["I", "D"])


if __name__ == "__main__":
    unittest.main()
