#!/bin/bash
# Usage (run from project root): ./sim/run.sh tb/tb_axi_common.v
set -e
cd "$(dirname "$0")/.."
if [ -z "$1" ]; then
    echo "Usage: ./sim/run.sh <testbench_file_relative_to_project_root>"
    exit 1
fi
iverilog -g2001 -f rtl/axi4_system.f "$@" -o sim/build.out
vvp sim/build.out
