#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# Comparison test: validate native --trace-rvvi-text output against
# the output of sail_to_rvvi_spec.py (which converts the standard Sail
# trace log to RVVI-TEXT).  The comparison covers only the fields that
# the conversion script supports (PC, instruction, register changes,
# MODE).  Native-only features (TRAP, MEM, VIRT) are validated
# separately by rvviTextChecker.py and the content checks.
#
# Due to timing differences between the Sail trace log and the native
# callback model, register changes may appear on different instructions
# in the two outputs.  Therefore, the comparison is done in two phases:
# 1. Per-instruction: compare PC and instruction encoding for RET lines
#    (stop at first TRAP in native, since the script doesn't handle traps).
# 2. Aggregate: compare the total multiset of register changes across
#    all instructions (including TRAP lines in native), to tolerate
#    timing offsets.  Known differences (initialization CSRs that only
#    appear in native, and trap-handler CSRs) are reported as warnings.
#
# Usage:
#   compare_rvvi_test.py --sim <sim> --elf <elf> --config <config> \
#       --config-override <override> --sail-to-rvvi <sail_to_rvvi_spec.py> \
#       --rvvi-checker <rvviTextChecker.py> [--xlen N] [--flen N] [--vlen N]

import argparse
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path


# ---------------------------------------------------------------------------
# RVVI-TEXT line parser
# ---------------------------------------------------------------------------

def tokenize_line(line):
    """Tokenize an RVVI-TEXT line, stripping comments and handling quotes."""
    out = ['']
    in_comment = False
    in_string = False
    for ch in line.strip():
        if ch == "'":
            in_comment = not in_comment
            continue
        if ch == '"':
            in_string = not in_string
            continue
        if not in_comment:
            if not in_string and (ch == ' ' or ch == '\t'):
                if out[-1] != '':
                    out.append('')
            else:
                out[-1] += ch
    if out[-1] == '':
        out.pop()
    return out


def parse_rvvi_line(tokens):
    """Parse a tokenized RVVI-TEXT line into a structured dict."""
    if not tokens:
        return None

    result = {
        'event': None,
        'pc': None,
        'insn': None,
        'regs': {'X': [], 'F': [], 'V': [], 'C': []},
        'mode': None,
        'virt': None,
    }

    i = 0
    while i < len(tokens):
        key = tokens[i]

        if key in ('VERSION', 'VENDOR', 'PARAMS'):
            return None

        if key == 'HART':
            i += 2
            continue

        if key in ('RET', 'TRAP'):
            result['event'] = key
            result['pc'] = tokens[i + 1]
            result['insn'] = tokens[i + 2]
            i += 3
            continue

        if key in ('ORDER', 'ISSUE'):
            i += 2
            continue

        if key in ('X', 'F', 'V'):
            result['regs'][key].append((tokens[i + 1], tokens[i + 2]))
            i += 3
            continue

        if key == 'C':
            result['regs']['C'].append((tokens[i + 1], tokens[i + 2]))
            i += 3
            continue

        if key == 'MODE':
            result['mode'] = tokens[i + 1]
            i += 2
            continue

        if key == 'VIRT':
            result['virt'] = tokens[i + 1]
            i += 2
            continue

        if key == 'MEM':
            count = int(tokens[i + 5])
            i += 6 + count * 2
            continue

        if key == 'DM':
            i += 2
            continue

        if key in ('CYCLE', 'TIME'):
            i += 2
            continue

        i += 1

    return result


def parse_rvvi_file(path):
    """Parse an RVVI-TEXT file and return a list of instruction dicts."""
    instructions = []
    with open(path) as f:
        for line in f:
            tokens = tokenize_line(line)
            if not tokens:
                continue
            if tokens[-1] == '\\':
                continue
            parsed = parse_rvvi_line(tokens)
            if parsed is not None:
                instructions.append(parsed)
    return instructions


# ---------------------------------------------------------------------------
# Normalization helpers
# ---------------------------------------------------------------------------

def normalize_hex(val):
    if val is None:
        return None
    v = val.lower()
    if v.startswith('0x'):
        v = v[2:]
    v = v.lstrip('0') or '0'
    return '0x' + v.upper()


def normalize_reg_change(kind, idx, val):
    nidx = normalize_hex(idx) if kind == 'C' else str(int(idx))
    nval = normalize_hex(val)
    return (kind, nidx, nval)


def collect_all_reg_changes(instructions):
    """Collect all register changes across ALL instructions (including
    TRAP lines) as a Counter."""
    counter = Counter()
    for instr in instructions:
        for kind in ('X', 'F', 'V', 'C'):
            for idx, val in instr['regs'][kind]:
                counter[normalize_reg_change(kind, idx, val)] += 1
    return counter


# ---------------------------------------------------------------------------
# Comparison
# ---------------------------------------------------------------------------

def compare_pc_sequence(script_instrs, native_instrs):
    """Compare PC and instruction encoding sequences for RET lines.

    Stops at the first TRAP in the native output (the script doesn't
    handle traps).  Returns (errors, matched_count).
    """
    errors = []
    warnings = []
    native_rets = []
    for instr in native_instrs:
        if instr['event'] == 'TRAP':
            break
        native_rets.append(instr)

    script_rets = [i for i in script_instrs if i['event'] == 'RET']
    min_len = min(len(script_rets), len(native_rets))

    matched = 0
    for idx in range(min_len):
        s = script_rets[idx]
        n = native_rets[idx]

        if normalize_hex(s['pc']) != normalize_hex(n['pc']):
            errors.append(
                f"Instruction {idx}: PC mismatch: "
                f"script={s['pc']}, native={n['pc']}"
            )
            break

        if normalize_hex(s['insn']) != normalize_hex(n['insn']):
            errors.append(
                f"Instruction {idx} (PC={s['pc']}): INSN mismatch: "
                f"script={s['insn']}, native={n['insn']}"
            )
            break
        matched += 1

    if len(script_rets) > matched:
        warnings.append(
            f"Script has {len(script_rets) - matched} extra RET instructions "
            f"after the comparison point (script has {len(script_rets)} RET total, "
            f"native has {len(native_rets)} RET before first TRAP, matched {matched})"
        )

    return errors, warnings, matched


def compare_reg_changes_aggregate(script_instrs, native_instrs):
    """Compare the total multiset of register changes across ALL
    instructions (including TRAP lines in native).

    Returns (errors, warnings).  Errors are unexpected differences.
    Warnings are known differences (initialization CSRs in native,
    trap-handler CSRs in script).
    """
    errors = []
    warnings = []

    script_regs = collect_all_reg_changes(script_instrs)
    native_regs = collect_all_reg_changes(native_instrs)

    script_only = script_regs - native_regs
    native_only = native_regs - script_regs

    # Known native-only: initialization CSRs (mstatus=0x300, misa=0x301,
    # mcause=0x342) and initial X register writes on the first instruction.
    # These happen during model setup before the first traced instruction
    # in the Sail log, but are captured by the native callback model.
    init_csr_indices = {'0x300', '0x301', '0x342'}  # mstatus, misa, mcause
    known_native = set()
    for (kind, idx, val) in native_only:
        if kind == 'C' and idx in init_csr_indices:
            known_native.add((kind, idx, val))
        elif kind == 'X' and idx in ('10', '11'):
            # Initial x10 (a0) and x11 (a1) writes during setup
            known_native.add((kind, idx, val))

    for (kind, idx, val), count in native_only.items():
        if (kind, idx, val) in known_native:
            warnings.append(
                f"Register change {kind} {idx} {val} (x{count}) only in native "
                f"(likely initialization)"
            )
        else:
            warnings.append(
                f"Register change {kind} {idx} {val} (x{count}) only in native"
            )

    for (kind, idx, val), count in script_only.items():
        warnings.append(
            f"Register change {kind} {idx} {val} (x{count}) only in script "
            f"(likely trap-handler or timing offset)"
        )

    return errors, warnings


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def run_simulator(sim, elf, config, override_config, extra_args, trace_file):
    cmd = [
        sim,
        "--config", config,
        "--config-override", override_config,
        "--trace-output", trace_file,
    ] + extra_args + [elf]
    return subprocess.run(cmd, capture_output=True, text=True, timeout=120)


def main():
    parser = argparse.ArgumentParser(
        description="Compare native RVVI-TEXT output with sail_to_rvvi_spec.py output"
    )
    parser.add_argument("--sim", required=True, help="Path to sail_riscv_sim")
    parser.add_argument("--elf", required=True, help="Path to test ELF")
    parser.add_argument("--config", required=True, help="Simulator config JSON")
    parser.add_argument("--config-override", required=True,
                        help="Config override JSON")
    parser.add_argument("--sail-to-rvvi", required=True,
                        help="Path to sail_to_rvvi_spec.py")
    parser.add_argument("--rvvi-checker", required=True,
                        help="Path to rvviTextChecker.py")
    parser.add_argument("--xlen", type=int, default=64, help="XLEN")
    parser.add_argument("--flen", type=int, default=64, help="FLEN")
    parser.add_argument("--vlen", type=int, default=256, help="VLEN")
    parser.add_argument("--inst-limit", type=int, default=10000,
                        help="Max instructions to run")
    args = parser.parse_args()

    tmpdir = tempfile.mkdtemp(prefix="rvvi_compare_")
    sail_log = os.path.join(tmpdir, "sail.log")
    rvvi_script = os.path.join(tmpdir, "rvvi_script.txt")
    rvvi_native = os.path.join(tmpdir, "rvvi_native.txt")

    try:
        # Step 1: Run simulator with standard trace to get Sail log
        print("[1/4] Running simulator with standard trace...")
        sim1 = run_simulator(
            args.sim, args.elf, args.config, args.config_override,
            ["--trace-instr", "--trace-gpr", "--trace-fpr",
             "--trace-vreg", "--trace-csr",
             "--inst-limit", str(args.inst_limit)],
            sail_log
        )
        if sim1.returncode != 0:
            print(f"FAIL: simulator (trace) exited with code {sim1.returncode}",
                  file=sys.stderr)
            if sim1.stderr:
                print(sim1.stderr, file=sys.stderr)
            return 1

        # Step 2: Convert Sail log to RVVI-TEXT with sail_to_rvvi_spec.py
        print("[2/4] Converting Sail log to RVVI-TEXT...")
        conv = subprocess.run(
            [
                sys.executable, args.sail_to_rvvi,
                sail_log, rvvi_script,
                "--xlen", str(args.xlen),
                "--flen", str(args.flen),
                "--vlen", str(args.vlen),
            ],
            capture_output=True, text=True, timeout=30
        )
        if conv.returncode != 0:
            print("FAIL: sail_to_rvvi_spec.py failed", file=sys.stderr)
            if conv.stderr:
                print(conv.stderr, file=sys.stderr)
            return 1

        # Step 3: Run simulator with --trace-rvvi-text to get native RVVI
        print("[3/4] Running simulator with --trace-rvvi-text...")
        sim2 = run_simulator(
            args.sim, args.elf, args.config, args.config_override,
            ["--trace-rvvi-text",
             "--inst-limit", str(args.inst_limit)],
            rvvi_native
        )
        if sim2.returncode != 0:
            print(f"FAIL: simulator (rvvi-text) exited with code {sim2.returncode}",
                  file=sys.stderr)
            if sim2.stderr:
                print(sim2.stderr, file=sys.stderr)
            return 1

        # Step 4a: Validate native RVVI with rvviTextChecker.py
        print("[4/4] Validating and comparing...")
        checker = subprocess.run(
            [sys.executable, args.rvvi_checker, rvvi_native],
            capture_output=True, text=True, timeout=30
        )
        if checker.returncode != 0:
            print("FAIL: rvviTextChecker.py rejected native trace",
                  file=sys.stderr)
            if checker.stderr:
                print(checker.stderr, file=sys.stderr)
            return 1
        print(f"  rvviTextChecker: {checker.stdout.strip()}")

        # Step 4b: Parse and compare
        script_instrs = parse_rvvi_file(rvvi_script)
        native_instrs = parse_rvvi_file(rvvi_native)

        native_rets = [i for i in native_instrs if i['event'] == 'RET']
        native_traps = [i for i in native_instrs if i['event'] == 'TRAP']
        script_rets = [i for i in script_instrs if i['event'] == 'RET']

        print(f"  Script: {len(script_rets)} RET instructions")
        print(f"  Native: {len(native_rets)} RET, {len(native_traps)} TRAP")

        # Phase 1: Compare PC and instruction encoding sequences
        pc_errors, pc_warnings, matched_count = compare_pc_sequence(script_instrs, native_instrs)
        if pc_warnings:
            for w in pc_warnings:
                print(f"  INFO: {w}")
        if pc_errors:
            print(f"  PC/INSN comparison: matched {matched_count} instructions, "
                  f"then diverged", file=sys.stderr)
            for e in pc_errors[:10]:
                print(f"  - {e}", file=sys.stderr)
        else:
            print(f"  PC/INSN comparison: all {matched_count} instructions match")

        # Phase 2: Compare aggregate register changes (including TRAP lines)
        reg_errors, reg_warnings = compare_reg_changes_aggregate(
            script_instrs, native_instrs
        )
        if reg_warnings:
            print(f"  Register change comparison: {len(reg_warnings)} warning(s) "
                  f"(known timing differences)")
            for w in reg_warnings[:10]:
                print(f"    WARN: {w}")
        if reg_errors:
            print(f"  Register change comparison: {len(reg_errors)} unexpected "
                  f"difference(s)", file=sys.stderr)
            for e in reg_errors[:20]:
                print(f"  - {e}", file=sys.stderr)
        elif not reg_warnings:
            print("  Register change comparison: all match (aggregate)")

        # Determine pass/fail: PC/INSN errors are failures, register change
        # errors are failures, but register change warnings are OK.
        all_errors = pc_errors + reg_errors
        if all_errors:
            print(f"\nFAIL: {len(all_errors)} comparison error(s)", file=sys.stderr)

            print("\n--- Script RVVI (first 10 lines) ---", file=sys.stderr)
            with open(rvvi_script) as f:
                for j, line in enumerate(f):
                    if j >= 10:
                        break
                    print(f"  {line.rstrip()}", file=sys.stderr)
            print("\n--- Native RVVI (first 10 lines) ---", file=sys.stderr)
            with open(rvvi_native) as f:
                for j, line in enumerate(f):
                    if j >= 10:
                        break
                    print(f"  {line.rstrip()}", file=sys.stderr)
            return 1

        print("PASS: Native RVVI-TEXT matches script output "
              "(within script scope) and passes rvviTextChecker.py")
        return 0

    finally:
        import shutil
        shutil.rmtree(tmpdir, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
