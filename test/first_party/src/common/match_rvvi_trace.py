#!/usr/bin/env python3
"""Match a main-window TRACE sample stream against a field golden file."""

from __future__ import annotations

import argparse
import json
import sys
from typing import Any

from rvvi_trace import (
    insn_load_rd,
    insn_rd,
    mem_d_bytes,
    mnemonic,
    parse_trace,
    pt_values,
    symbol_window,
    window_events,
)

LOAD_LIKE = {
    "lb",
    "lh",
    "lw",
    "ld",
    "lbu",
    "lhu",
    "lwu",
    "c.lw",
    "c.ld",
    "lr.w",
    "lr.d",
    "sc.w",
    "sc.d",
    "amoadd.w",
    "amoadd.d",
}

ALIASES = {
    "c.lw": "lw",
    "c.sw": "sw",
    "c.ld": "ld",
    "c.sd": "sd",
    "csrrw": "csrw",
    "csrrs": "csrs",
}


def when_ok(when: str | None, xlen: int) -> bool:
    if not when:
        return True
    return when.replace(" ", "") == f"xlen=={xlen}"


def event_matches(ev: dict[str, Any], spec: dict[str, Any], xlen: int) -> bool:
    want_event = spec.get("event", "RET")
    if ev["event"] != want_event:
        return False
    name = mnemonic(ev["inst"], xlen)
    got = ALIASES.get(name, name)
    want = spec["match"]
    return got == want or name == want


def check_fields(ev: dict[str, Any], spec: dict[str, Any], xlen: int) -> list[str]:
    errors: list[str] = []
    loc = f"pc={ev['pc']:#x} {mnemonic(ev['inst'], xlen)}"
    allow_overlap = spec.get("allow_overlap", False)
    d_bytes, had_overlap = mem_d_bytes(ev["mem"], coalesce=allow_overlap)
    if had_overlap and not allow_overlap:
        errors.append(f"{loc}: overlapping MEM D records {d_bytes}")
    if "mem_d" in spec and sorted(d_bytes) != sorted(spec["mem_d"]):
        errors.append(f"{loc}: mem_d expected {spec['mem_d']}, got {d_bytes}")
    if "mem_d_sum" in spec and sum(d_bytes) != spec["mem_d_sum"]:
        errors.append(
            f"{loc}: mem_d_sum expected {spec['mem_d_sum']}, got {sum(d_bytes)} from {d_bytes}"
        )
    if spec.get("x_rd"):
        rd = (
            insn_load_rd(ev["inst"])
            if spec["match"] in LOAD_LIKE
            else insn_rd(ev["inst"])
        )
        if rd != 0 and rd not in ev["x"]:
            errors.append(f"{loc}: missing X {rd}")
    if "pt" in spec:
        pts = pt_values(ev["mem"])
        if spec["pt"] not in pts:
            errors.append(f"{loc}: expected PT {spec['pt']}, got {pts}")
    if spec.get("f_rd"):
        rd = insn_rd(ev["inst"])
        if rd not in ev["f"]:
            errors.append(f"{loc}: missing F {rd}")
    if "v_rd" in spec and spec["v_rd"] not in ev["v"]:
        errors.append(f"{loc}: missing V {spec['v_rd']}")
    return errors


def match_events(
    events: list[dict[str, Any]], golden: dict[str, Any], xlen: int
) -> list[str]:
    specs = [s for s in golden.get("events", []) if when_ok(s.get("when"), xlen)]
    errors: list[str] = []
    i = 0
    for si, spec in enumerate(specs):
        found = None
        while i < len(events):
            ev = events[i]
            i += 1
            if event_matches(ev, spec, xlen):
                found = ev
                break
        if found is None:
            errors.append(
                f"golden[{si}] {spec.get('event', 'RET')} {spec['match']}: not found in window"
            )
            continue
        errors.extend(check_fields(found, spec, xlen))
    return errors


def match_text(text: str, golden: dict[str, Any], elf: str | None) -> list[str]:
    params, events = parse_trace(text)
    xlen = int(params.get("XLEN", "64"))
    start_name = golden.get("window", "main")
    if elf:
        start, end = symbol_window(elf, start_name)
        events = window_events(events, start, end)
        if not events:
            return [f"no TRACE events in {start_name} window [{start:#x}, {end:#x})"]
    return match_events(events, golden, xlen)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Match RVVI-TEXT against TRACE field golden"
    )
    parser.add_argument("trace")
    parser.add_argument("--golden", required=True)
    parser.add_argument("--elf", required=True)
    args = parser.parse_args()
    with open(args.trace, encoding="utf-8") as f:
        text = f.read()
    with open(args.golden, encoding="utf-8") as f:
        golden = json.load(f)
    errors = match_text(text, golden, args.elf)
    if errors:
        print("FAIL:", file=sys.stderr)
        for e in errors:
            print(" ", e, file=sys.stderr)
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
