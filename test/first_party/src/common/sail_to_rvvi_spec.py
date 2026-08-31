#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# Convert a Sail log file into RVVI-TEXT spec-compliant trace format.
# Based on sail_to_rvvi.py from riscv-arch-test (act4), updated to
# follow the RVVI-TEXT specification (VERSION/VENDOR/PARAMS header,
# RET instead of ORDER/PC/INSN, C instead of CSR, 0x prefixes, etc.).
#
# Usage: sail_to_rvvi_spec.py <input.log> <output.rvvi> [--xlen N] [--flen N] [--vlen N]

import argparse
import re
import sys
from pathlib import Path


def sailLog2Trace(inputLogFile: Path, outputTraceFile: Path,
                  xlen: int, flen: int, vlen: int) -> None:
    # Regular expression to match instruction lines
    #                             [STEP]     [MODE]:    0xPC              (0xINSN)           DISASM
    # Sail logs Supervisor as "HS" when the H extension is enabled and
    # VirtualSupervisor as "VS" (model/core/types.sail).
    insn_pattern = re.compile(
        r"\[(\d+)\] \[([MSU]|HS|VS)\]: 0x([0-9a-fA-F]+) \(0x([0-9a-fA-F]+)\) (.*)"
    )

    # Regular expressions to match register updates
    reg_patterns = {
        "C": re.compile(r"CSR .* \(0x([0-9a-fA-F]+)\) (?:<-|->) 0x([0-9a-fA-F]+)"),
        "X": re.compile(r"x(\d+) <- 0x([0-9a-fA-F]+)"),
        "F": re.compile(r"f(\d+) <- 0x([0-9a-fA-F]+)"),
        "V": re.compile(r"v(\d+) <- 0x([0-9a-fA-F]+)"),
    }

    # Mode mapping: Sail privilege letter -> RVVI-TEXT MODE hex value
    # HS and VS are both privilege level 1 (VS is distinguished by VIRT).
    mode_map = {"M": "0x3", "S": "0x1", "HS": "0x1", "VS": "0x1", "U": "0x0"}

    # TODO: Add support for parsing traps, interrupts, and VM signals

    with inputLogFile.open() as f, outputTraceFile.open("w") as outfile:
        # Write RVVI-TEXT header
        outfile.write("VERSION 0 5\n")
        outfile.write('VENDOR "sail_riscv" 0 1\n')
        param_count = 6  # ILEN, XLEN, FLEN, VLEN, NHART, RETIRE
        outfile.write(
            f"PARAMS {param_count} ILEN 32 XLEN {xlen} "
            f"FLEN {flen} VLEN {vlen} NHART 1 RETIRE 1\n"
        )

        lines = f.readlines()
        output_line = ""
        prev_mode_hex: str | None = None

        for i in range(len(lines)):
            line = lines[i]

            # Check for instruction line
            insn_match = insn_pattern.search(line)
            if insn_match:
                _order, prev_mode, pc, insn, _ = insn_match.groups()
                prev_mode_hex = mode_map.get(prev_mode)

                # Format the beginning of the instruction line.
                # mode is set later based on the mode for the next
                # instruction because RVVI expects the mode at the END
                # of the instruction, but Sail logs have the mode at
                # the START of the instruction.
                next_output = (
                    f"HART 0 RET 0x{pc} 0x{insn} MODE " + "{mode_hex}"
                )

                # Check for register updates until the next instruction line
                j = i + 1
                while j < len(lines):
                    for reg_type, pattern in reg_patterns.items():
                        reg_match = pattern.search(lines[j])
                        if reg_match:
                            reg_num, reg_val = reg_match.groups()
                            if reg_type == "C":
                                # CSR: C 0x<index> 0x<value>
                                next_output += f" C 0x{reg_num} 0x{reg_val}"
                            else:
                                # X/F/V: <kind> <decimal_index> 0x<value>
                                next_output += f" {reg_type} {reg_num} 0x{reg_val}"
                            break
                    if insn_pattern.search(lines[j]):
                        break
                    j += 1

                # Reached end of instruction
                next_output += "\n"

                # Update the previous instruction with the new privilege
                # mode and output it to the trace file.
                if output_line:
                    outfile.write(output_line.format(mode_hex=prev_mode_hex))
                output_line = next_output

        # Flush the final instruction. Sail logs mode at the start of an
        # instruction, so the trailing instruction has no "next" mode to
        # inherit from; fall back to its own start mode as the closest
        # approximation.
        if output_line and prev_mode_hex is not None:
            outfile.write(output_line.format(mode_hex=prev_mode_hex))


def main():
    parser = argparse.ArgumentParser(
        description="Convert Sail log to RVVI-TEXT spec-compliant trace"
    )
    parser.add_argument("input_file", type=str, help="Path to Sail log file")
    parser.add_argument("output_file", type=str, help="Path to output RVVI trace")
    parser.add_argument("--xlen", type=int, default=64, help="XLEN (32 or 64)")
    parser.add_argument("--flen", type=int, default=64, help="FLEN (0, 32, 64, or 128)")
    parser.add_argument("--vlen", type=int, default=256, help="VLEN (0 or positive)")
    args = parser.parse_args()

    sailLog2Trace(
        Path(args.input_file),
        Path(args.output_file),
        args.xlen,
        args.flen,
        args.vlen,
    )


if __name__ == "__main__":
    main()
