#!/usr/bin/env bash
# Rebuild golden traces in src/golden/. Review the diff before committing.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
BUILD_DIR="${1:-${REPO_DIR}/build}"
SIM="${BUILD_DIR}/c_emulator/sail_riscv_sim"
OVR="${REPO_DIR}/test/first_party/src/no_override.json"
GOLD="${REPO_DIR}/test/first_party/src/golden"
LINT="${REPO_DIR}/test/first_party/src/common/lint_rvvi_trace.py"
CHECKER="${REPO_DIR}/test/first_party/src/common/rvviTextChecker.py"
INST_LIMIT=10000

if [[ ! -x "${SIM}" ]]; then
  echo "ERROR: simulator not found at ${SIM}" >&2
  echo "Build sail_riscv_sim in ${BUILD_DIR} first." >&2
  exit 1
fi

mkdir -p "${GOLD}"

for xlen in 32 64; do
  arch="rv${xlen}d"
  cfg="${BUILD_DIR}/config/${arch}_v256_e${xlen}.json"
  for stub in basic vmem amo sc vector mem_widths compressed fp trap_mem; do
    elf="${BUILD_DIR}/test/first_party/${arch}_test_rvvi_text_${stub}.S.elf"
    out="${GOLD}/${arch}_test_rvvi_text_${stub}.S.rvvi"
    if [[ ! -f "${elf}" ]]; then
      echo "SKIP: ${elf} not found (build tests first)" >&2
      continue
    fi
    "${SIM}" --config "${cfg}" --config-override "${OVR}" \
             --trace-rvvi-text --trace-output "${out}" \
             --inst-limit "${INST_LIMIT}" "${elf}" > /dev/null 2>&1
    echo -n "  ${arch}_${stub}: lint="
    python3 "${LINT}" "${out}" && echo -n " checker="
    python3 "${CHECKER}" "${out}" > /dev/null 2>&1 && echo "PASS" || echo "FAIL (checker)"
  done
done

echo "Review git diff test/first_party/src/golden/ before committing."
