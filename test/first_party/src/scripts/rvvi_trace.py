"""Parse RVVI-TEXT into per-retire TRACE samples and locate the `main` window."""

from __future__ import annotations

import re
import subprocess
from typing import Any

OPCODE_LOAD = 0b0000011
OPCODE_LOAD_FP = 0b0000111
OPCODE_STORE = 0b0100011
OPCODE_STORE_FP = 0b0100111
OPCODE_AMO = 0b0101111
OPCODE_SYSTEM = 0b1110011
OPCODE_OP = 0b0110011
OPCODE_OP_IMM = 0b0010011
OPCODE_AUIPC = 0b0010111
OPCODE_LUI = 0b0110111
OPCODE_OP_V = 0b1010111

LOAD_MNEMONIC = {
    0b000: "lb",
    0b001: "lh",
    0b010: "lw",
    0b011: "ld",
    0b100: "lbu",
    0b101: "lhu",
    0b110: "lwu",
}
STORE_MNEMONIC = {0b000: "sb", 0b001: "sh", 0b010: "sw", 0b011: "sd"}
FP_LOAD_MNEMONIC = {0b010: "flw", 0b011: "fld", 0b100: "flq"}
FP_STORE_MNEMONIC = {0b010: "fsw", 0b011: "fsd", 0b100: "fsq"}
VEC_LOAD_WIDTH = {0b000: "vle8.v", 0b101: "vle16.v", 0b110: "vle32.v", 0b111: "vle64.v"}
VEC_STORE_WIDTH = {
    0b000: "vse8.v",
    0b101: "vse16.v",
    0b110: "vse32.v",
    0b111: "vse64.v",
}
AMO_MNEMONIC = {
    (0b00010, 0b010): "lr.w",
    (0b00010, 0b011): "lr.d",
    (0b00011, 0b010): "sc.w",
    (0b00011, 0b011): "sc.d",
    (0b00000, 0b010): "amoadd.w",
    (0b00000, 0b011): "amoadd.d",
}

ECALL = 0x00000073
MRET = 0x30200073
SRET = 0x10200073
SFENCE_VMA = 0x12000073

MEM_HEAD_RE = re.compile(
    r"MEM\s+([ID])\s+(\d+)\s+(0x[0-9A-Fa-f]+)\s+(0x[0-9A-Fa-f]+)\s+(\d+)"
)
NM_RE = re.compile(r"^([0-9A-Fa-f]+)\s+([A-Za-z])\s+(\S+)\s*$")


def is_compressed(inst: int) -> bool:
    return (inst & 0x3) != 0x3


def insn_rd(inst: int) -> int:
    return (inst >> 7) & 0x1F


def insn_load_rd(inst: int) -> int:
    if not is_compressed(inst) or (inst & 0x3) == 0b10:
        return insn_rd(inst)
    return 8 + ((inst >> 2) & 0x7)


def parse_hex(tok: str) -> int:
    return int(tok, 16)


def last_write_wins(pairs: list[tuple[int, str | int]]) -> dict[int, int]:
    out: dict[int, int] = {}
    for idx, val in pairs:
        out[idx] = val if isinstance(val, int) else parse_hex(str(val))
    return out


def parse_mem_records(line: str) -> list[dict[str, Any]]:
    records = []
    for match in MEM_HEAD_RE.finditer(line):
        bus, nbytes, vaddr, paddr, count = match.groups()
        n = int(count)
        tokens = line[match.end() :].split()
        kv: dict[str, str] = {}
        ti = 0
        for _ in range(n):
            if ti + 1 >= len(tokens):
                break
            if tokens[ti] in ("MEM", "MODE", "VIRT", "HART", "RET", "TRAP"):
                break
            kv[tokens[ti]] = tokens[ti + 1]
            ti += 2
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


def parse_params(line: str) -> dict[str, str]:
    params: dict[str, str] = {}
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


def parse_event_line(line: str) -> dict[str, Any] | None:
    tokens = line.split()
    event = None
    pc = None
    inst = None
    x_writes: list[tuple[int, int]] = []
    f_writes: list[tuple[int, int]] = []
    v_writes: list[tuple[int, int]] = []
    c_writes: list[tuple[int, int]] = []
    mode = None
    virt = None
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in ("RET", "TRAP") and i + 2 < len(tokens):
            event = tok
            pc = parse_hex(tokens[i + 1])
            inst = parse_hex(tokens[i + 2])
            i += 3
            continue
        if tok == "X" and i + 2 < len(tokens):
            x_writes.append((int(tokens[i + 1]), parse_hex(tokens[i + 2])))
            i += 3
            continue
        if tok == "F" and i + 2 < len(tokens):
            f_writes.append((int(tokens[i + 1]), parse_hex(tokens[i + 2])))
            i += 3
            continue
        if tok == "V" and i + 2 < len(tokens):
            v_writes.append((int(tokens[i + 1]), parse_hex(tokens[i + 2])))
            i += 3
            continue
        if tok == "C" and i + 2 < len(tokens):
            try:
                c_writes.append((parse_hex(tokens[i + 1]), parse_hex(tokens[i + 2])))
            except ValueError:
                pass
            i += 3
            continue
        if tok == "MODE" and i + 1 < len(tokens):
            mode = parse_hex(tokens[i + 1])
            i += 2
            continue
        if tok == "VIRT" and i + 1 < len(tokens):
            virt = parse_hex(tokens[i + 1])
            i += 2
            continue
        i += 1
    if event is None or pc is None or inst is None:
        return None
    return {
        "event": event,
        "pc": pc,
        "inst": inst,
        "x": last_write_wins(x_writes),
        "f": last_write_wins(f_writes),
        "v": last_write_wins(v_writes),
        "c": last_write_wins(c_writes),
        "mode": mode,
        "virt": virt,
        "mem": parse_mem_records(line),
        "line": line.rstrip(),
    }


def parse_trace(text: str) -> tuple[dict[str, str], list[dict[str, Any]]]:
    params: dict[str, str] = {}
    events: list[dict[str, Any]] = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith(("VERSION", "VENDOR")):
            continue
        if stripped.startswith("PARAMS"):
            params = parse_params(stripped)
            continue
        parsed = parse_event_line(stripped)
        if parsed is not None:
            events.append(parsed)
    return params, events


def mnemonic(inst: int, xlen: int) -> str | None:
    inst &= (1 << 32) - 1 if not is_compressed(inst) else (1 << 16) - 1
    if not is_compressed(inst):
        if inst == ECALL:
            return "ecall"
        if inst == MRET:
            return "mret"
        if inst == SRET:
            return "sret"
        if inst == SFENCE_VMA:
            return "sfence.vma"
        opcode = inst & 0x7F
        funct3 = (inst >> 12) & 0x7
        if opcode == OPCODE_LOAD:
            return LOAD_MNEMONIC.get(funct3)
        if opcode == OPCODE_STORE:
            return STORE_MNEMONIC.get(funct3)
        if opcode == OPCODE_LOAD_FP:
            if funct3 in VEC_LOAD_WIDTH:
                return VEC_LOAD_WIDTH[funct3]
            return FP_LOAD_MNEMONIC.get(funct3)
        if opcode == OPCODE_STORE_FP:
            if funct3 in VEC_STORE_WIDTH:
                return VEC_STORE_WIDTH[funct3]
            return FP_STORE_MNEMONIC.get(funct3)
        if opcode == OPCODE_AMO:
            funct5 = (inst >> 27) & 0x1F
            return AMO_MNEMONIC.get((funct5, funct3), "amo")
        if opcode == OPCODE_SYSTEM:
            if funct3 == 0b001:
                return "csrw" if insn_rd(inst) == 0 else "csrrw"
            if funct3 == 0b010:
                return "csrs" if insn_rd(inst) == 0 else "csrrs"
            if funct3 == 0b011:
                return "csrc" if insn_rd(inst) == 0 else "csrrc"
            if funct3 == 0:
                return "system"
        if opcode == OPCODE_OP and funct3 == 0 and ((inst >> 25) & 0x7F) == 0:
            return "add"
        if opcode == OPCODE_AUIPC:
            return "auipc"
        if opcode == OPCODE_LUI:
            return "lui"
        if opcode == OPCODE_OP_IMM:
            return "addi"
        if opcode == OPCODE_OP_V:
            if funct3 == 0b111 and (inst >> 31) & 1:
                return "vsetivli"
            return "vop"
        return None

    op = inst & 0x3
    funct3 = (inst >> 13) & 0x7
    if op == 0b00:
        if funct3 == 0b010:
            return "c.lw"
        if funct3 == 0b110:
            return "c.sw"
        if funct3 == 0b011:
            return "c.ld" if xlen == 64 else "c.flw"
        if funct3 == 0b111:
            return "c.sd" if xlen == 64 else "c.fsw"
        if funct3 == 0b001:
            return "c.fld"
        if funct3 == 0b101:
            return "c.fsd"
    if op == 0b10:
        if funct3 == 0b010:
            return "c.lwsp"
        if funct3 == 0b110:
            return "c.swsp"
        if inst == 0x8082:
            return "ret"
        if (inst & 0xE003) == 0x8002 and ((inst >> 2) & 0x1F) == 0:
            return "ret"
        if (inst & 0xE003) == 0x8002:
            return "c.jr"
        if (inst & 0xE003) == 0x4001:
            return "c.li"
    return None


def ranges_overlap(a: dict[str, Any], b: dict[str, Any]) -> bool:
    a0, a1 = a["vaddr"], a["vaddr"] + a["bytes"]
    b0, b1 = b["vaddr"], b["vaddr"] + b["bytes"]
    return a["bus"] == b["bus"] and a0 < b1 and b0 < a1


def coalesce_mem(mems: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], bool]:
    """Merge overlapping same-bus records. Returns (merged, had_overlap)."""
    merged: list[dict[str, Any]] = []
    had_overlap = False
    for rec in mems:
        absorbed = False
        for prev in merged:
            if ranges_overlap(prev, rec):
                had_overlap = True
                lo = min(prev["vaddr"], rec["vaddr"])
                hi = max(prev["vaddr"] + prev["bytes"], rec["vaddr"] + rec["bytes"])
                prev["vaddr"] = lo
                prev["paddr"] = min(prev["paddr"], rec["paddr"])
                prev["bytes"] = hi - lo
                if not prev["kv"] and rec["kv"]:
                    prev["kv"] = rec["kv"]
                absorbed = True
                break
        if not absorbed:
            merged.append(dict(rec))
    return merged, had_overlap


def mem_d_bytes(
    mems: list[dict[str, Any]], *, coalesce: bool
) -> tuple[list[int], bool]:
    ds = [m for m in mems if m["bus"] == "D"]
    if coalesce:
        merged, had = coalesce_mem(ds)
        return [m["bytes"] for m in merged], had
    had = False
    for i, a in enumerate(ds):
        for b in ds[i + 1 :]:
            if ranges_overlap(a, b):
                had = True
    return [m["bytes"] for m in ds], had


def pt_values(mems: list[dict[str, Any]]) -> list[str]:
    vals = []
    for m in mems:
        if "PT" in m["kv"]:
            vals.append(m["kv"]["PT"])
    return vals


def _run_nm(elf_path: str) -> str:
    for cmd in (["nm", "-n", elf_path], ["llvm-nm", "-n", elf_path]):
        try:
            proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
        except FileNotFoundError:
            continue
        if proc.returncode == 0 and proc.stdout.strip():
            return proc.stdout
    raise RuntimeError(f"nm failed on {elf_path}")


def symbol_window(elf_path: str, start_name: str = "main") -> tuple[int, int]:
    """Return [start, end) from `start_name` to the next global text symbol."""
    start = None
    later: list[int] = []
    for line in _run_nm(elf_path).splitlines():
        m = NM_RE.match(line.strip())
        if not m:
            continue
        addr = int(m.group(1), 16)
        stype, name = m.group(2), m.group(3)
        if name.startswith("$"):
            continue
        if name == start_name and stype in "Tt":
            start = addr
            continue
        if start is not None and stype == "T" and addr > start:
            later.append(addr)
    if start is None:
        raise RuntimeError(f"{start_name} not found in {elf_path}")
    end = later[0] if later else start + 0x10000
    return start, end


def window_events(
    events: list[dict[str, Any]], start: int, end: int
) -> list[dict[str, Any]]:
    return [ev for ev in events if start <= ev["pc"] < end]
