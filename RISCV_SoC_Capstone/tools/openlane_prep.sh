#!/usr/bin/env bash
# Stage a LibreLane run folder:  bash tools/openlane_prep.sh [base|plus] [OUT_DIR]
# Creates <OUT_DIR>/riscv_soc_<variant>/{src/,config.json,*.sdc,pin_order.cfg}
# with the synthesizable case-ROM (no initial blocks) built from the firmware at the ASIC SRAM size (256 B).
# Then:   cd <OUT_DIR>/riscv_soc_<variant> && librelane config.json      (inside `nix-shell` in the librelane checkout)
set -e
cd "$(dirname "$0")/.."
V=${1:-plus}; D=${2:-$HOME/librelane_runs}/riscv_soc_$V
make -s fw-$V SRAM_WORDS=64
mkdir -p "$D/src"; rm -f "$D"/src/*.v
python3 tools/hex2rom.py build/$V/rom.hex "$D/src/rom_case.v" 1024      # replaces rom.v
for f in rtl/*.v rtl/pwm/*.v; do
  case "$(basename $f)" in rom.v) continue;; esac
  [ $V = base ] && case "$(basename $f)" in top_plus.v|pwm*.v|gpio_axi.v) continue;; esac
  [ $V = plus ] && [ "$(basename $f)" = top.v ] && continue
  cp $f "$D/src/"
done
cp openlane/$V/config.json openlane/$V/pin_order.cfg openlane/$V/*.sdc "$D/"
echo "Staged $D"
echo "Next:  cd $D && librelane config.json     (inside nix-shell from your librelane checkout)"
