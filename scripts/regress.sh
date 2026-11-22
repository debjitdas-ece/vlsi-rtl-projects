#!/usr/bin/env bash
cd "$(dirname "$0")/.." || exit 1
fail=0
for d in 02_ALU 03_UART 04_SPI PWM_Controller axi 05_FIFO_CDC_RDC; do
  if [ ! -f "$d/Makefile" ]; then echo "--- skip $d (no Makefile) ---"; continue; fi
  echo "=== $d ==="
  make -C "$d" test || { echo "!!! $d FAILED"; fail=1; }
done
exit $fail
