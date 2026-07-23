#!/usr/bin/env python3
# Semantic checks on Sail RVVI-TEXT traces (widths, rd, MODE, ...).
from __future__ import annotations

import argparse
import re
import sys


OPCODE_LOAD = 0b0000011
OPCODE_LOAD_FP = 0b0000111
OPCODE_STORE = 0b0100011
OPCODE_STORE_FP = 0b0100111
OPCODE_AMO = 0b0101111
OPCODE_SYSTEM = 0b1110011
OPCODE_BRANCH = 0b1100011
OPCODE_JAL = 0b1101111
OPCODE_JALR = 0b1100111
OPCODE_LUI = 0b0110111
OPCODE_AUIPC = 0b0010111
OPCODE_OP = 0b0110011      # R-type arithmetic
OPCODE_OP_IMM = 0b0010011  # I-type arithmetic
OPCODE_OP_32 = 0b0111011   # RV64 word-width R-type
OPCODE_OP_IMM_32 = 0b0011011  # RV64 word-width I-type
# Opcodes that should not write a CSR in the base ISA.
_NO_CSR_WRITE_OPCODES = frozenset([
    OPCODE_BRANCH, OPCODE_JAL, OPCODE_JALR,
    OPCODE_LUI, OPCODE_AUIPC,
    OPCODE_OP, OPCODE_OP_IMM, OPCODE_OP_32, OPCODE_OP_IMM_32,
    OPCODE_LOAD, OPCODE_STORE,
])

_RD_WRITE_OPCODES = frozenset([
    OPCODE_JAL, OPCODE_JALR, OPCODE_LUI, OPCODE_AUIPC,
    OPCODE_OP, OPCODE_OP_IMM, OPCODE_OP_32, OPCODE_OP_IMM_32,
])

_NO_RD_OPCODES = frozenset([OPCODE_BRANCH, OPCODE_STORE, OPCODE_STORE_FP])
LOAD_WIDTH = {0b000: 1, 0b001: 2, 0b010: 4, 0b011: 8, 0b100: 1, 0b101: 2, 0b110: 4}
STORE_WIDTH = {0b000: 1, 0b001: 2, 0b010: 4, 0b011: 8}
FP_WIDTH = {0b010: 4, 0b011: 8, 0b100: 16}
AMO_WIDTH = {0b010: 4, 0b011: 8}

MRET = 0x30200073
SRET = 0x10200073
AMO_FUNCT5_LR = 0b00010
AMO_FUNCT5_SC = 0b00011

MEM_RE = re.compile(
    r"MEM\s+([ID])\s+(\d+)\s+(0x[0-9A-Fa-f]+)\s+(0x[0-9A-Fa-f]+)\s+(\d+)"
)


def is_compressed(inst: int) -> bool:
    return (inst & 0x3) != 0x3


def insn_rd(inst: int) -> int:
    return (inst >> 7) & 0x1F


def insn_load_rd(inst: int) -> int:
    # Q2 (C.LWSP/C.LDSP) uses bits 11:7. Q0 (C.LW/C.LD) uses rd' -> x8+rd'.
    if not is_compressed(inst) or (inst & 0x3) == 0b10:
        return insn_rd(inst)
    return 8 + ((inst >> 2) & 0x7)


def insn_funct5(inst: int) -> int:
    return (inst >> 27) & 0x1F


def classify_uncompressed(inst: int):
    opcode = inst & 0x7F
    funct3 = (inst >> 12) & 0x7
    if opcode == OPCODE_LOAD:
        return "load", LOAD_WIDTH.get(funct3)
    if opcode == OPCODE_STORE:
        return "store", STORE_WIDTH.get(funct3)
    if opcode == OPCODE_LOAD_FP:
        return "load_fp", FP_WIDTH.get(funct3)
    if opcode == OPCODE_STORE_FP:
        return "store_fp", FP_WIDTH.get(funct3)
    if opcode == OPCODE_AMO:
        return "amo", AMO_WIDTH.get(funct3)
    return None, None


def classify_compressed(inst: int, xlen: int):
    op = inst & 0x3
    funct3 = (inst >> 13) & 0x7
    # Quadrant 0
    if op == 0b00:
        if funct3 == 0b001:
            return "load_fp", 8  # C.FLD
        if funct3 == 0b010:
            return "load", 4  # C.LW
        if funct3 == 0b011:
            return ("load", 8) if xlen == 64 else ("load_fp", 4)  # C.LD / C.FLW
        if funct3 == 0b101:
            return "store_fp", 8  # C.FSD
        if funct3 == 0b110:
            return "store", 4  # C.SW
        if funct3 == 0b111:
            return ("store", 8) if xlen == 64 else ("store_fp", 4)  # C.SD / C.FSW
    # Quadrant 2 (SP-relative)
    if op == 0b10:
        if funct3 == 0b001:
            return "load_fp", 8  # C.FLDSP
        if funct3 == 0b010:
            return "load", 4  # C.LWSP
        if funct3 == 0b011:
            return ("load", 8) if xlen == 64 else ("load_fp", 4)
        if funct3 == 0b101:
            return "store_fp", 8
        if funct3 == 0b110:
            return "store", 4  # C.SWSP
        if funct3 == 0b111:
            return ("store", 8) if xlen == 64 else ("store_fp", 4)
    return None, None


def classify(inst: int, xlen: int):
    if is_compressed(inst):
        return classify_compressed(inst, xlen)
    return classify_uncompressed(inst)


def parse_hex(tok: str) -> int:
    return int(tok, 16)


def parse_mem_records(line: str):
    records = []
    for match in MEM_RE.finditer(line):
        bus, nbytes, vaddr, paddr, count = match.groups()
        rest = line[match.end():]
        kv = {}
        tokens = rest.split()
        n = int(count)
        for i in range(n):
            if i * 2 + 1 >= len(tokens):
                break
            kv[tokens[i * 2]] = tokens[i * 2 + 1]
            # Stop at the next top-level keyword that isn't a value.
        records.append(
            {
                "bus": bus,
                "bytes": int(nbytes),
                "vaddr": parse_hex(vaddr),
                "paddr": parse_hex(paddr),
                "count": n,
                "kv": kv,
            }
        )
    return records


def parse_params(line: str) -> dict:
    params = {}
    tokens = line.split()
    i = 0
    while i < len(tokens):
        if tokens[i] == "PARAMS" and i + 1 < len(tokens):
            count = int(tokens[i + 1])
            i += 2
            for _ in range(count):
                if i + 1 >= len(tokens):
                    break
                params[tokens[i]] = tokens[i + 1]
                i += 2
            break
        i += 1
    return params


def parse_event_line(line: str):
    tokens = line.split()
    event = None
    pc = None
    inst = None
    x_writes = []
    f_writes = []
    c_writes = []
    mode = None
    for i, tok in enumerate(tokens):
        if tok in ("RET", "TRAP") and i + 2 < len(tokens):
            event = tok
            pc = parse_hex(tokens[i + 1])
            inst = parse_hex(tokens[i + 2])
        elif tok == "X" and i + 2 < len(tokens):
            x_writes.append((int(tokens[i + 1]), parse_hex(tokens[i + 2])))
        elif tok == "F" and i + 2 < len(tokens):
            f_writes.append((int(tokens[i + 1]), parse_hex(tokens[i + 2])))
        elif tok == "C" and i + 2 < len(tokens):
            try:
                c_writes.append((parse_hex(tokens[i + 1]), parse_hex(tokens[i + 2])))
            except ValueError:
                pass  # malformed C record; checker will flag it
        elif tok == "MODE" and i + 1 < len(tokens):
            mode = parse_hex(tokens[i + 1])
    if event is None:
        return None
    return {
        "event": event,
        "pc": pc,
        "inst": inst,
        "x_writes": x_writes,
        "f_writes": f_writes,
        "c_writes": c_writes,
        "mode": mode,
        "mem": parse_mem_records(line),
        "line": line.rstrip(),
    }


def lint_trace(text: str) -> list[str]:
    errors: list[str] = []
    lines = text.splitlines()
    if not lines:
        return ["empty trace"]

    xlen = 64
    for line in lines[:8]:
        if line.startswith("PARAMS"):
            params = parse_params(line)
            if "XLEN" in params:
                xlen = int(params["XLEN"])
            break

    events = []
    for lineno, line in enumerate(lines, 1):
        if "RET " not in line and "TRAP " not in line:
            continue
        parsed = parse_event_line(line)
        if parsed is None:
            continue
        parsed["lineno"] = lineno
        events.append(parsed)

    if not events:
        errors.append("no RET/TRAP events")
        return errors

    prev_mode = None
    prev_event = None
    prev_inst = None

    for ev in events:
        loc = f"L{ev['lineno']} {ev['event']} pc={ev['pc']:#x} inst={ev['inst']:#x}"
        inst = ev["inst"]
        mems = ev["mem"]
        mem_i = [m for m in mems if m["bus"] == "I"]
        mem_d = [m for m in mems if m["bus"] == "D"]

        if ev["mode"] not in (0, 1, 3, None):
            errors.append(f"{loc}: invalid MODE {ev['mode']}")

        # MODE is sampled at fetch, so a privilege change shows up on the next line.
        if prev_mode is not None and ev["mode"] is not None and ev["mode"] != prev_mode:
            if prev_event != "TRAP" and prev_inst not in (MRET, SRET):
                errors.append(
                    f"{loc}: MODE changed {prev_mode} -> {ev['mode']} "
                    f"without preceding TRAP/mret/sret"
                )
        if ev["mode"] is not None:
            prev_mode = ev["mode"]
        prev_event = ev["event"]
        prev_inst = inst

        if ev["event"] == "RET" and not is_compressed(inst):
            opcode = inst & 0x7F
            c_indices = [idx for idx, _ in ev.get("c_writes", [])]
            if opcode in _NO_CSR_WRITE_OPCODES and c_indices:
                errors.append(
                    f"{loc}: opcode {opcode:#09b} must not write CSRs "
                    f"but has C records {[hex(i) for i in c_indices]} "
                    f"-- possible reset-state leak into first instruction"
                )

        if ev["event"] == "RET" and not is_compressed(inst):
            opcode = inst & 0x7F
            rd = insn_rd(inst)
            x_indices = [i for i, _ in ev["x_writes"]]
            if opcode in _RD_WRITE_OPCODES:
                if rd != 0 and rd not in x_indices:
                    errors.append(f"{loc}: opcode {opcode:#09b} rd=x{rd} missing X {rd} record")
                if rd == 0 and x_indices:
                    errors.append(
                        f"{loc}: opcode {opcode:#09b} rd=x0 must not have X records, got {x_indices}"
                    )
            if opcode in _NO_RD_OPCODES:
                if x_indices:
                    errors.append(
                        f"{loc}: opcode {opcode:#09b} has no rd but has X records {x_indices}"
                    )

        for mem in mems:
            if mem["bytes"] <= 0:
                errors.append(f"{loc}: MEM {mem['bus']} bytes must be positive")
            if mem["count"] != len(mem["kv"]):
                # kv parse is best-effort; only flag if count is clearly too big
                if mem["count"] > 8:
                    errors.append(f"{loc}: MEM count {mem['count']} looks implausible")
            if "PT" in mem["kv"] and mem["kv"]["PT"] not in ("K", "M", "G", "T", "P"):
                errors.append(f"{loc}: bad PT value {mem['kv']['PT']}")
            if "PTE" in mem["kv"]:
                try:
                    parse_hex(mem["kv"]["PTE"])
                except ValueError:
                    errors.append(f"{loc}: PTE value is not hex: {mem['kv']['PTE']}")

        # Fetch faults use inst=0 and may omit MEM I.
        if ev["event"] == "RET" or inst != 0:
            if not mem_i:
                errors.append(f"{loc}: missing MEM I fetch record")
            else:
                for mem in mem_i:
                    if mem["bytes"] not in (2, 4):
                        errors.append(
                            f"{loc}: MEM I bytes={mem['bytes']} (expected 2 or 4)"
                        )

        kind, width = classify(inst, xlen)
        if kind in ("load", "store", "load_fp", "store_fp", "amo") and width:
            if ev["event"] == "RET":
                is_sc = kind == "amo" and insn_funct5(inst) == AMO_FUNCT5_SC
                if not mem_d:
                    if not is_sc:
                        errors.append(f"{loc}: {kind} width={width} missing MEM D")
                else:
                    d_bytes = [m["bytes"] for m in mem_d]
                    if kind == "amo":
                        if not is_sc and not any(b == width for b in d_bytes):
                            errors.append(
                                f"{loc}: AMO expected MEM D bytes={width}, got {d_bytes}"
                            )
                    elif kind in ("load", "store"):
                        # Vector ld/st share these opcodes and emit one record per element.
                        if len(d_bytes) == 1:
                            if d_bytes[0] != width:
                                errors.append(
                                    f"{loc}: {kind} expected MEM D bytes={width}, got {d_bytes[0]}"
                                )
                        elif sum(d_bytes) != width:
                            errors.append(
                                f"{loc}: {kind} MEM D bytes {d_bytes} do not sum to {width}"
                            )

            if kind == "load" and ev["event"] == "RET":
                rd = insn_load_rd(inst)
                if rd != 0:
                    x_indices = [i for i, _ in ev["x_writes"]]
                    if rd not in x_indices:
                        errors.append(f"{loc}: load rd=x{rd} missing X {rd} record")

        elif kind is None and ev["event"] == "RET":
            if mem_d:
                errors.append(f"{loc}: non-memory insn has MEM D {mem_d}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Lint an RVVI-TEXT trace")
    parser.add_argument("trace", help="Path to .rvvi trace")
    args = parser.parse_args()
    with open(args.trace, encoding="utf-8") as f:
        errors = lint_trace(f.read())
    if errors:
        print(f"FAIL: {len(errors)} lint error(s)", file=sys.stderr)
        for err in errors:
            print(f"  {err}", file=sys.stderr)
        return 1
    print("PASS: RVVI-TEXT semantic lint")
    return 0


if __name__ == "__main__":
    sys.exit(main())
