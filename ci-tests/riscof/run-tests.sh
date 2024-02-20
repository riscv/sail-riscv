# !bin/bash

set -e

# Check if argument (work directory name) provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <argument>"
    exit 1
fi

riscof -v debug run --config=config.ini \
           --suite=riscv-arch-test/riscv-test-suite/ \
           --env=riscv-arch-test/riscv-test-suite/env \
           --no-browser --work-dir "$1"

if grep -rniq "$1"/report.html -e '>0failed<'
then
    echo "Test successful!"
    exit 0
else
    echo "Test FAILED!"
    exit 1
fi
