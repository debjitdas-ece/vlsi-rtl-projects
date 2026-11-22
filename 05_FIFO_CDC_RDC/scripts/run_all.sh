#!/usr/bin/env bash
# One-command regression for the FIFO / CDC project. Run from the project root.
set -u
cd "$(dirname "$0")/.."
mkdir -p sim; cd sim
RES=$(mktemp)
check () {  # $1 = name, stdin = simulator output
  out=$(cat); echo "$out" | grep -E "^(sync_fifo|async_fifo|handshake|reset_sync|BUG)" 
  if echo "$out" | grep -q "^PASS"; then echo "  [PASS] $1"; echo P >> "$RES"; else echo "  [FAIL] $1"; echo F >> "$RES"; fi
}
echo "== lint =="
for m in sync_fifo pulse_sync reset_sync; do
  verilator --lint-only -Wall --top-module $m ../rtl/$m.v && echo "  lint ok: $m"
done
verilator --lint-only -Wall --top-module async_fifo     ../rtl/sync_2ff.v ../rtl/async_fifo.v     && echo "  lint ok: async_fifo"
verilator --lint-only -Wall --top-module handshake_sync ../rtl/sync_2ff.v ../rtl/handshake_sync.v && echo "  lint ok: handshake_sync"

echo "== sync FIFO =="
iverilog -g2005 -o sync.vvp ../rtl/sync_fifo.v ../tb/tb_sync_fifo.v && vvp sync.vvp | check sync_fifo

echo "== async FIFO: 6 clock ratios (WHALF RHALF WPROB RPROB), plain and with bus-skew model =="
for skew in 0 900; do
  iverilog -g2005 -P tb_async_fifo.SKEW=$skew -o async_$skew.vvp ../rtl/sync_2ff.v ../rtl/async_fifo.v ../tb/tb_async_fifo.v
  for r in "5000 5000 70 70" "5000 7300 70 40" "5000 13000 90 90" "13000 5000 90 90" "3100 11000 60 80" "7000 7100 50 50"; do
    set -- $r
    vvp async_$skew.vvp +WHALF=$1 +RHALF=$2 +WPROB=$3 +RPROB=$4 +NUM=20000 | check "async_fifo ratio $1:$2 skew=$skew"
  done
done

echo "== crossings =="
iverilog -g2005 -o hs.vvp ../rtl/sync_2ff.v ../rtl/handshake_sync.v ../tb/tb_handshake_sync.v && vvp hs.vvp | check handshake_sync
iverilog -g2005 -o rs.vvp ../rtl/reset_sync.v ../tb/tb_reset_sync.v && vvp rs.vvp | check reset_sync
iverilog -g2005 -o bugs.vvp ../rtl/sync_2ff.v ../rtl/pulse_sync.v ../cdc_bugs/tb_cdc_bugs.v && vvp bugs.vvp | check cdc_bug_gallery

echo "== SVA (Verilator --assert) =="
verilator --binary --assert --timing -Wno-fatal -Wno-lint -Wno-style --top-module tb_sync_fifo -Mdir obj_sva_sync \
  ../rtl/sync_fifo.v ../sva/fifo_sva.sv ../tb/tb_sync_fifo.v >/dev/null 2>&1 && ./obj_sva_sync/Vtb_sync_fifo | check "sync_fifo + SVA"
verilator --binary --assert --timing -Wno-fatal -Wno-lint -Wno-style --top-module tb_async_fifo -Mdir obj_sva_async \
  ../rtl/sync_2ff.v ../rtl/async_fifo.v ../sva/async_fifo_sva.sv ../tb/tb_async_fifo.v >/dev/null 2>&1 && ./obj_sva_async/Vtb_async_fifo +NUM=5000 | check "async_fifo + SVA"

pass=$(grep -c P "$RES"); fail=$(grep -c F "$RES"); rm -f "$RES"
echo; echo "SUMMARY: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && [ "$pass" -gt 0 ]
