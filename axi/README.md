# AMBA AXI4 Full System

A complete AMBA AXI4 interconnect system written in pure **Verilog-2001** (no SystemVerilog constructs), built as a portfolio project targeting VLSI/RTL semiconductor roles.

**Status: ✅ Complete — all testbenches passing.**

## Architecture

- **2 Masters, 2 Slaves**
- **Round-robin arbitration** at the interconnect
- **Depth-4 outstanding transactions** per master, tracked via ID
- Full burst support (INCR/WRAP handling via `axi_burst_calc.v`)
- Address decode and response generation on the slave side
- Write-strobe merging for partial-word writes

## Module Overview

| Module | Role |
|---|---|
| `rtl/common/axi_pkg.v` | Shared parameters/definitions |
| `rtl/common/axi_burst_calc.v` | Burst address/length calculation |
| `rtl/common/axi_id_tracker.v` | Per-master outstanding-transaction ID tracking (parameterized `OUTSTANDING_DEPTH`) |
| `rtl/Master/axi4_master_top.v` | Master top-level wrapper |
| `rtl/Master/axi_master_cmd_fsm.v` | Master command/address-phase FSM |
| `rtl/Master/axi_master_rd_fsm.v` | Master read-data FSM |
| `rtl/Master/axi_master_wr_fsm.v` | Master write-data FSM |
| `rtl/Master/axi_master_pending_fifo.v` | Outstanding-request tracking FIFO |
| `rtl/Master/axi_master_resp_check.v` | Response checking logic |
| `rtl/interconnect/axi4_interconnect_top.v` | Interconnect top-level |
| `rtl/interconnect/axi_ic_arbiter.v` | Round-robin arbiter |
| `rtl/interconnect/axi_ic_addr_map.v` | Address-to-slave mapping |
| `rtl/interconnect/axi_ic_mux_rd.v` / `axi_ic_mux_wr.v` | Read/write channel muxing |
| `rtl/Slave/axi4_slave_top.v` | Slave top-level wrapper |
| `rtl/Slave/axi_addr_decode.v` | Slave-local address decoding |
| `rtl/Slave/axi_regmap.v` | Register map / memory model |
| `rtl/Slave/axi_wr_fsm.v` | Slave write FSM |
| `rtl/Slave/axi_rd_fsm.v` | Slave read FSM |
| `rtl/Slave/axi_resp_gen.v` | Slave response generation |
| `rtl/Slave/axi_wstrb_merge.v` | Write-strobe merge logic |
| `rtl/axi4_system_top.v` | Full system top (masters + interconnect + slaves) |

## Testbenches (`tb/`)
- `tb_axi_common.v` — shared TB utilities/tasks
- `tb_axi4_master_top.v` — master-level verification
- `tb_axi4_slave_top.v` — slave-level verification
- `tb_axi4_system_top.v` — full-system integration test

### System-level test results (`tb_axi4_system_top.v`)
```
--- Test 1: single master/slave sanity ---
--- Test 2: two masters contending for one shared slave ---
--- Test 3: two masters, two independent slaves, concurrent ---
=================================================
TOTAL: 6 passed, 0 failed
=================================================
```
Covers single-master sanity checks, arbitration correctness under contention (two masters, one shared slave), and concurrent independent-slave access (two masters, two slaves).

## Running Simulation

Compilation uses a filelist (`rtl/axi4_system.f`) with iverilog (`-g2001`). See `sim/run.sh` for the exact build/run commands.

```bash
cd axi/sim
./run.sh
gtkwave dump.vcd
```

## Design Decisions
- `NUM_MASTERS` / `NUM_SLAVES` are `generate`-parameterized on the interconnect.
- `OUTSTANDING_DEPTH` is a parameter on `axi_id_tracker`, deliberately kept out of `axi_pkg.v` so it can vary per-instance if needed.
- Strict Verilog-2001 syntax throughout — no SystemVerilog interfaces, no `always_ff`/`always_comb`.

## Status Summary
- [x] `axi_pkg.v`, `axi_burst_calc.v`, `axi_id_tracker.v`, `axi_addr_decode.v`
- [x] Master-side FSMs and top
- [x] Interconnect (arbiter, address map, muxes)
- [x] Slave-side write FSM (`axi_wr_fsm.v`)
- [x] Slave-side read FSM
- [x] Full-system integration testing — all tests passed
