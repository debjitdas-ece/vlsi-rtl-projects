# SPI Master — Parameterized RTL (Verilog)

> **Part of [`vlsi-rtl-projects`](https://github.com/debjitdas-ece/vlsi-rtl-projects) — Project #3 of 6**

A fully parameterized SPI Master controller supporting all 4 SPI modes (CPOL/CPHA),
verified with a self-checking testbench and a behavioral slave BFM.
Designed and simulated with Icarus Verilog + GTKWave.

---

## Table of Contents

- [Overview](#overview)
- [File Structure](#file-structure)
- [Module Descriptions](#module-descriptions)
- [Configurability](#configurability)
- [Architecture & Key Design Decisions](#architecture--key-design-decisions)
- [Verification — All Checks Passing](#verification--all-checks-passing)
- [How to Run](#how-to-run)
- [Waveform Guide](#waveform-guide)
- [Known Scope / Deliberately Deferred](#known-scope--deliberately-deferred)
- [What's Next](#whats-next)

---

## Overview

This project implements a full-duplex SPI Master capable of operating in any of the
four standard SPI modes. The clock polarity (CPOL) and clock phase (CPHA) are
runtime-selectable inputs, not compile-time parameters, so the same hardware
can talk to different SPI peripherals without re-synthesis.

The design includes parametric setup and hold timing around SS, ensuring
clean chip-select assertion before the first SCLK edge and deassertion
only after the last edge — matching real peripheral timing requirements.

---

## File Structure

```
04_SPI/
├── spi_master.v      — SPI master RTL: IDLE → SETUP → XFER → HOLD FSM
├── spi_slave.v       — Behavioral slave BFM (Bus Functional Model) for verification
├── spi_tb.v          — Self-checking testbench: all 4 modes × 6 patterns + edge cases
├── spi_tb.vcd        — GTKWave waveform dump from full regression run
└── README.md         — This file
```

---

## Module Descriptions

### `spi_master` — SPI Master Controller

```
Parameters : CLK_F (50 MHz), SPI_F (1 MHz), SETUP_CYCLES (8), HOLD_CYCLES (8)
Inputs     : clk, rst, start, tx_data[7:0], cpol, cpha, miso
Outputs    : mosi, sclk, ss, rx_data[7:0], busy, done
```

**State machine: IDLE → SETUP → XFER → HOLD**

| State | Action |
|-------|--------|
| IDLE  | Waits for `start` pulse; captures `tx_data` into shift register |
| SETUP | Asserts SS (`ss=0`), holds for `SETUP_CYCLES` before first SCLK edge |
| XFER  | Generates exactly 16 SCLK edges (8 bits × 2 edges); samples MISO and shifts MOSI on correct edges per mode |
| HOLD  | Keeps SS low for `HOLD_CYCLES` after last SCLK edge, then releases |

Key signals:

| Signal | Description |
|--------|-------------|
| `busy` | High during SETUP, XFER, HOLD — caller must wait before issuing next `start` |
| `done` | Single-cycle pulse when the last MISO bit is captured (asserted inside XFER, one cycle before SS releases) |
| `ss`   | Active-low chip select, derived from `~busy` |
| `sclk` | Idles at `cpol` level; toggles every `N` system clocks during XFER |

---

### `spi_slave_bfm` — Behavioral Slave (Verification Only)

```
Parameters : DW = 8 (data width)
Inputs     : sclk, ss, cpol, cpha, mosi, tx_data[DW-1:0]
Outputs    : miso, rx_data[DW-1:0], rx_valid
```

This is a Bus Functional Model — not synthesizable RTL. It models a real SPI slave
device for testbench purposes only. It handles all 4 SPI modes correctly using the
same `cpol ^ cpha` (mode_xor) trick as the master, and drives `rx_valid` for one
cycle when a full byte has been received.

The BFM resets its shift register and bit counter on every `negedge ss`, which is
how real SPI peripherals behave.

---

### `tb_spi_master` — Self-Checking Testbench

The testbench connects master and slave in a loopback (`mosi → slave`, `miso ← slave`),
runs a structured regression, and prints a final pass/fail count.

**Test coverage:**

| Test | Description |
|------|-------------|
| Mode sweep | All 4 SPI modes (Mode 0/1/2/3) × 6 byte patterns = 24 transactions |
| Full-duplex integrity | Verifies both master-received and slave-received bytes match expected values for every transaction |
| SCLK edge count | Confirms exactly 16 edges generated per byte |
| SCLK uniformity | Checks every half-period equals exactly `N` system clock cycles |
| Setup timing | Verifies SS-to-first-SCLK gap equals `(SETUP_CYCLES + N)` system clocks |
| Hold timing | Verifies last-SCLK-to-SS-release gap equals `HOLD_CYCLES` system clocks |
| Back-to-back | Issues a second `start` immediately after SS releases; checks no data corruption |
| Reset mid-transfer | Asserts `rst` partway through a frame; confirms `busy`, `ss`, `done` all return to idle state |

**Hardware timestamp capture:**

The testbench captures the system-time of every SCLK edge into an array `edge_t[0:31]`
and measures inter-edge intervals arithmetically. This is a cycle-accurate timing check —
not just "did data arrive" but "did each clock edge land at the exact right time."

---

## Configurability

| Parameter | Default | Function |
|-----------|---------|----------|
| `CLK_F` | 50 MHz | System clock frequency |
| `SPI_F` | 1 MHz | Target SPI clock frequency |
| `SETUP_CYCLES` | 8 | SS-assert to first SCLK edge hold time (in system clocks) |
| `HOLD_CYCLES` | 8 | Last SCLK edge to SS-release hold time (in system clocks) |

The divider `N = CLK_F / (2 × SPI_F)` is computed at elaboration, so changing
`CLK_F` or `SPI_F` automatically adjusts the clock generation logic with no manual
counter width tuning needed (handled by `$clog2`).

Runtime inputs (no re-synthesis required):

| Port | Function |
|------|----------|
| `cpol` | Clock polarity: 0 = idle-low, 1 = idle-high |
| `cpha` | Clock phase: 0 = sample on first edge, 1 = sample on second edge |

The four SPI modes map as: Mode 0 = `{cpol=0, cpha=0}`, Mode 1 = `{0,1}`,
Mode 2 = `{1,0}`, Mode 3 = `{1,1}`.

---

## Architecture & Key Design Decisions

### 1. Mode Selection via `cpol ^ cpha` (mode_xor)

The sample and shift edges for all 4 SPI modes reduce to two cases based on
`cpol XOR cpha`:

```
mode_xor = 0  →  sample on rising edge,  shift on falling edge  (Modes 0 and 3)
mode_xor = 1  →  sample on falling edge, shift on rising edge   (Modes 1 and 2)
```

This is the canonical SPI mode encoding. A single XOR gate replaces four
separate mode decoders.

### 2. CPHA=1 First-Edge Suppression

In CPHA=1 modes, the first shift must be suppressed because data is set up
before the first active edge rather than on it. The signal `shift_edge` includes
the guard condition `!(cpha && ecnt == 0)` — `ecnt` counts SCLK edges, so
edge 0 is skipped for shift only when `cpha=1`. This matches the SPI protocol
spec exactly.

### 3. Parametric Setup / Hold Timing

Real SPI peripherals (e.g. flash memories, ADCs) specify a minimum `tCSS`
(chip-select-setup to first clock) and `tCSH` (last-clock to chip-select-hold).
`SETUP_CYCLES` and `HOLD_CYCLES` directly control these, making the master
compatible with strict timing requirements without modifying RTL.

### 4. Timestamp-Based Testbench Checks

Instead of only checking data correctness, the testbench measures actual
SCLK edge timestamps and verifies:
- All 16 edges land at exactly `N` system-clock intervals apart
- Setup and hold windows are exact to the clock cycle

This is the level of verification rigor used in tape-out sign-off environments.

### 5. `done` Pipelining

`done` is asserted on the same cycle as the 8th MISO sample, before SS releases.
This gives the caller one full clock cycle head-start to read `rx_data` before
the master returns to IDLE. The testbench explicitly checks `rx_data` on the
`posedge done` cycle to confirm this timing.

---

## Verification — All Checks Passing

```
SPI master regression: N checks, 0 failed
RESULT: PASS
```

| Group | Checks per transaction | Transactions | Notes |
|-------|----------------------|--------------|-------|
| Data integrity (master RX) | 1 | 24 | All 4 modes × 6 patterns |
| Data integrity (slave RX) | 1 | 24 | Full-duplex verification |
| SCLK idle polarity | 1 | 24 | Returns to `cpol` after transfer |
| SCLK edge count | 1 | 24 | Exactly 16 per byte |
| SCLK uniformity | 15 | 24 | All 15 inter-edge gaps checked |
| Setup timing | 1 | 24 | SS-to-first-edge |
| Hold timing | 1 | 24 | Last-edge-to-SS |
| Back-to-back | 2 | 1 | Both master and slave data correct |
| Reset mid-transfer | 4 | 1 | `busy`, `ss`, `sclk`, `done` checked |

---

## How to Run

Requires: [Icarus Verilog](https://bleyer.org/icarus/) and optionally [GTKWave](https://gtkwave.sourceforge.net/).

```bash
# Compile
iverilog -g2012 -o sim_spi spi_master.v spi_slave.v spi_tb.v

# Simulate
vvp sim_spi

# View waveforms
gtkwave spi_tb.vcd
```

Expected final output:

```
========================================
 SPI master regression: N checks, 0 failed
 RESULT: PASS
========================================
```

> Note: `-g2012` flag is required because the testbench uses `string` type
> in the `check` task (SystemVerilog feature used in an otherwise Verilog-2005 TB).

---

## Waveform Guide

Load `spi_tb.vcd` in GTKWave. Suggested signal groups:

**Control**
```
clk  rst  start  busy  done
```

**SPI Bus**
```
ss  sclk  mosi  miso
cpol  cpha
```

**Data**
```
tx_data[7:0]  rx_data[7:0]
slave_tx[7:0]  slave_rx[7:0]  slave_rx_valid
```

**Internals (for debug)**
```
spi_master.s[1:0]  spi_master.cnt  spi_master.ecnt
spi_master.bit_cnt  spi_master.tx_shift[7:0]  spi_master.rx_shift[7:0]
```

Zoom into a single transfer to see: SS assertion → SETUP gap → 16 SCLK
edges with MOSI/MISO toggling → HOLD gap → SS release → `done` pulse.

---

## Known Scope / Deliberately Deferred

| Feature | Status | Notes |
|---------|--------|-------|
| Multi-byte burst (continuous SS) | Deferred | Current design is one byte per SS assertion |
| Multiple slave selects (SS[N:0]) | Deferred | Single SS output only |
| Variable data width (< 8 or > 8 bit) | Deferred | Fixed at 8 bits |
| AXI4-Lite / APB register wrapper | Future | Planned for top-level integration layer |
| SystemVerilog constrained-random TB | Future | Directed TB only; SV TB in roadmap |

---

## What's Next

- **Project #4 — FPGA PWM Controller:** Multi-channel digital PWM with
  configurable frequency and duty cycle, targeting FPGA implementation
- **Project #5 — AXI4-Lite Slave:** Bus interface wrapper for the UART and
  SPI cores developed in this portfolio
