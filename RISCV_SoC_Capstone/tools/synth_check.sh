#!/usr/bin/env bash
# Generic Yosys synthesis sanity check (no PDK): catches initial blocks, latches, undriven nets.
# Usage: SRAM_WORDS=64 bash tools/synth_check.sh      (real PPA numbers come from OpenLane)
set -e
cd "$(dirname "$0")/.."
SW=${SRAM_WORDS:-256}
mkdir -p build/synth
COMMON="rtl/picorv32.v rtl/axi_bridge.v rtl/axi_decoder.v rtl/axi_lite_interconnect.v rtl/axil_reg_if.v rtl/sram.v rtl/uart_axi.v rtl/uart_tx.v rtl/uart_rx.v rtl/sync2.v rtl/rst_sync.v"
PWM="rtl/pwm/*.v rtl/pwm_axi.v rtl/gpio_axi.v"
for v in base plus; do
  make -s fw-$v SRAM_WORDS=$SW >/dev/null
  python3 tools/hex2rom.py build/$v/rom.hex build/synth/rom_case_$v.v 1024
  if [ $v = base ]; then TOP=top; SRC="rtl/top.v $COMMON"; else TOP=top_plus; SRC="rtl/top_plus.v $COMMON $PWM"; fi
  echo "=== synth $TOP  (SRAM_WORDS=$SW)"
  yosys -q -l build/synth/$TOP.log -p "read_verilog -DSYNTHESIS -DSRAM_WORDS_DEF=$SW -sv $SRC build/synth/rom_case_$v.v; hierarchy -check -top $TOP; synth -flatten -top $TOP; check -assert; stat" >/dev/null
  grep -E 'Number of cells' build/synth/$TOP.log | tail -1
  awk '/Number of cells/ {s=0} /\$_[A-Z]*DFF[A-Z0-9_]* +[0-9]+/ {s+=$2} END {print "   flip-flops:   ", s}' build/synth/$TOP.log
  if awk '/\$_DLATCH/ {f=1} END {exit !f}' build/synth/$TOP.log; then echo "   WARNING: latches inferred"; else echo "   latches:       none"; fi
done
echo "synth check OK"
