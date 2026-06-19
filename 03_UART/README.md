# UART Transceiver — Parameterized RTL (Verilog)

> **Part of [`vlsi-rtl-projects`](https://github.com/debjitdas-ece/vlsi-rtl-projects) — Project #2 of 6**

A fully parameterized, industrial-style UART transmitter/receiver pair designed and
verified with Icarus Verilog + GTKWave (no physical FPGA target required).

---

## Table of Contents

- [Overview](#overview)
- [File Structure](#file-structure)
- [Module Descriptions](#module-descriptions)
- [Configurability](#configurability)
- [Architecture & Key Design Decisions](#architecture--key-design-decisions)
- [Verification — 286 / 286 Passing](#verification--286--286-passing)
- [Bug Log — Simulation-Driven Debugging](#bug-log--simulation-driven-debugging)
- [How to Run](#how-to-run)
- [Waveform Guide](#waveform-guide)
- [Known Scope / Deliberately Deferred](#known-scope--deliberately-deferred)
- [What's Next](#whats-next)

---

## Overview

This project implements a complete UART transceiver capable of runtime reconfiguration —
data width, parity mode, and stop-bit count are all selectable via input ports, not
compile-time parameters. This mirrors how real 16550-style UART peripherals allow
software to reconfigure the same hardware on the fly.

The receiver uses **16× oversampling with a 3-tap majority-vote** instead of single-point
center sampling, making it resilient to single-sample noise glitches.

---

## File Structure

```
03_UART/
├── Baud_rate.v       — Baud generator (rx_tick: 16× oversample, tx_tick: 1× baud)
├── Uart_tx.v         — Transmitter FSM: IDLE → START → DATA → PARITY → STOP
├── Uart_rx.v         — Receiver FSM: IDLE → START → DATA → PARITY → STOP/STOP2
├── Uart_tb.v         — Self-checking testbench, 286 directed + swept test cases
├── wave.vcd          — GTKWave dump from full testbench run
└── baud_gen.vcd      — Baud generator isolated waveform
```

---

## Module Descriptions

### `baud_gen` — Baud Generator

```
Inputs  : clk, rst
Outputs : rx_tick (16× baud rate pulse), tx_tick (1× baud rate pulse)
Params  : CLK_F (default 50 MHz), BAUD_R (default 115200), O=16 (oversample ratio)
```

A two-counter chain: the first counter (`c`) divides the system clock to generate
`rx_tick` at 16× the baud rate. A second counter (`t`) counts 16 rx_ticks and
generates `tx_tick` on every 16th one — exactly one pulse per baud period. Both
counters use `$clog2`-computed widths so they automatically size to the parameters.

---

### `uart_tx` — Transmitter FSM

```
Inputs  : clk, rst, tx_tick, sr (send request), d[7:0] (data byte)
          dbit[3:0] (data width 5–8), sp_t (2-stop-bit), p_en (parity enable), psel (0=even, 1=odd)
Outputs : tx_line (serial out), idle
```

**State machine: IDLE → START → DATA → PARITY → STOP**

| State | Action |
|-------|--------|
| IDLE  | Holds `tx_line` high; captures input byte into `data` register on `sr` pulse |
| START | Drives `tx_line` low for 1 baud period (start bit) |
| DATA  | Shifts out bits LSB-first, advances on each `tx_tick`, for `dbit` bits |
| PARITY| Transmits computed even/odd parity bit (skipped if `p_en=0`) |
| STOP  | Drives `tx_line` high; stays for 2 baud periods if `sp_t=1` |

Key detail: the input byte `d` is **latched into `data` the moment `sr` fires in IDLE**,
so changing the `d` bus mid-frame cannot corrupt the in-flight frame.

---

### `uart_rx` — Receiver FSM

```
Inputs  : clk, rst, rx_tick, rx_line (serial in)
          dbit[3:0], sp_t, p_en, psel
Outputs : q[7:0] (received byte), rx_done, frame_err, parity_err
```

**State machine: IDLE → START → DATA → PARITY → STOP → STOP2**

| State  | Action |
|--------|--------|
| IDLE   | Watches `rx_line`; falling edge triggers START |
| START  | Waits 16 rx_ticks; samples at tick 7 to validate the start bit |
| DATA   | For each bit, collects majority votes at ticks 6, 7, 8 of the 16-tick window; latches bit at tick 15 |
| PARITY | Same majority-vote sampling; compares against expected parity; sets `parity_err` if mismatch |
| STOP   | Validates stop bit; sets `frame_err` if line is low; asserts `rx_done` (if 1-stop mode) |
| STOP2  | Second stop-bit check; asserts `rx_done` and ORs `frame_err` |

**Majority vote logic:**

```
At rx_tick AND (t_counter == 6 or 7 or 8):
    mv_cnt accumulates the number of '1' samples seen
At tick 15:
    sampled bit = (mv_cnt >= 2)   ← 2-of-3 majority
```

This rejects any single-sample glitch in the oversampled window without adding latency.

---

### `tb_uart` — Self-Checking Testbench

The testbench loopbacks `tx_line → rx_line` (with optional injection mux), runs 8 test
groups, and prints `PASS`/`FAIL` with signal values for each case. Final summary line
shows total pass/fail count.

Three internal tasks handle all test patterns:

- `send_and_check` — Sends a byte, waits for `rx_done`, checks `q`, `frame_err`, `parity_err`
- `inject_test` — Forces a bad parity or bad stop bit by flipping the line at the right state
- `noise_glitch_test` — Injects a single-tap glitch into a specific bit/tap and confirms majority vote corrects it

---

## Configurability

All of the following are **runtime inputs**, not compile-time parameters. The same
synthesized hardware can be reconfigured each transfer:

| Port   | Width | Function |
|--------|-------|----------|
| `dbit` | 4-bit | Data width: 5, 6, 7, or 8 bits |
| `p_en` | 1-bit | Parity enable (0 = no parity) |
| `psel` | 1-bit | Parity select: 0 = even, 1 = odd |
| `sp_t` | 1-bit | Stop bits: 0 = 1 stop bit, 1 = 2 stop bits |

Clock/baud defaults (compile-time parameters in `baud_gen`):

| Parameter | Default | Notes |
|-----------|---------|-------|
| `CLK_F`   | 50 MHz  | System clock frequency |
| `BAUD_R`  | 115200  | Baud rate |
| `O`       | 16      | Oversample ratio |

---

## Architecture & Key Design Decisions

### 1. 16× Oversampling with 3-Tap Majority Vote

Instead of sampling at the center of each bit period once, the RX samples at ticks
6, 7, and 8 (of 16), and takes a majority decision. A single glitch on any one of the
three taps is corrected without any additional latency. This is the same technique used
in industrial UART controllers like the 16550A.

### 2. Start-Bit Re-synchronization

When the RX detects a falling edge in IDLE, it immediately resets its tick counter to 0
and re-references all subsequent timing to that edge. This eliminates clock drift
accumulation across long frames.

### 3. Latched TX Data Register

The transmitter captures `d[7:0]` into an internal register `data` the moment `sr` fires.
This means the caller is free to change the `d` bus immediately after pulsing `sr` —
there is no hold-time requirement beyond the single-cycle capture.

### 4. Runtime Register-Style Configuration

`dbit`, `p_en`, `psel`, and `sp_t` behave like control registers in a real peripheral.
This is a deliberate architectural choice: it matches 16550-style UART behavior and is
more interesting as a portfolio item than a static-parameter design.

### 5. Compact RTL Density

The entire design (excluding testbench) is 99 lines of Verilog across 3 modules. The
area footprint is dominated by the data register and state flip-flops. No vendor IPs
or macros are used.

---

## Verification — 286 / 286 Passing

All 286 test cases pass with zero failures on Icarus Verilog v12.

| Group | Cases | Coverage |
|-------|-------|----------|
| G1 | 6  | Basic 8N1: 0x00, 0xFF, 0xA5, 0x5A, 0x01, 0x80 |
| G2 | 256| Full byte sweep 0x00–0xFF with 8E1 (even parity) |
| G3 | 6  | 8O1 (odd parity): same 6 corner-case bytes |
| G4 | 4  | 7E1 (7-bit data width): 0x7F, 0x55, 0x00, 0x41 |
| G5 | 3  | Fault injection: clean, forced parity error, forced frame error |
| G6 | 1  | Spurious `sr` while TX busy — confirms no mid-frame corruption |
| G7 | 5  | Single-tap glitch injection at various bits and taps — majority vote correction confirmed |
| G8 | 5  | 2-stop-bit mode (8N2) and combined 8E2 |

**Test infrastructure highlights:**

The testbench includes a hardware injection mux (`inject_en` / `inject_val`) that
overrides the loopback line at the RX input. This lets the testbench precisely corrupt
specific bits during specific receiver states — no software trickery, pure RTL signal
manipulation — making the error-injection tests as realistic as possible.

---

## Bug Log — Simulation-Driven Debugging

All bugs were found by running the simulator, observing actual waveform values, and
tracing causality — not by inspection.

| # | Symptom | Root Cause | Fix |
|---|---------|------------|-----|
| 1 | RX stuck in START state | `start_ok` sampled on tick 15 but `ns` already evaluated one tick earlier | Moved `start_ok` sampling to tick 7, matching FSM transition timing |
| 2 | Majority vote always 0 | `mv_cnt` reset every rx_tick instead of only at start of bit window | Changed reset condition to reset only when entering DATA/PARITY state |
| 3 | `rx_done` asserted for 2 cycles in 2-stop mode | STOP2 transition to IDLE left `rx_done` high one extra cycle | Added explicit `rx_done <= 0` in the `else` branch of the stop-state block |
| 4 | `parity_err` persisted into next frame | Flag was latched but never cleared before a new frame started | Added `parity_err <= 0` in the IDLE→START transition |

---

## How to Run

Requires: [Icarus Verilog](https://bleyer.org/icarus/) (`iverilog` / `vvp`) and optionally [GTKWave](https://gtkwave.sourceforge.net/).

```bash
# Compile
iverilog -o sim_uart Baud_rate.v Uart_tx.v Uart_rx.v Uart_tb.v

# Simulate (prints PASS/FAIL log to stdout)
vvp sim_uart

# View waveforms
gtkwave wave.vcd
```

Expected final line from the simulator:

```
=== TOTAL: 286 PASS  0 FAIL — CLEAN ===
```

---

## Waveform Guide

Load `wave.vcd` in GTKWave. Suggested signal groups:

**Clocks & Ticks**
```
clk  rx_tick  tx_tick
```

**TX Path**
```
sr  d[7:0]  tx_line  idle
uart_tx.s[2:0]  uart_tx.data[7:0]  uart_tx.bit_idx[3:0]
```

**RX Path**
```
rx_in  rx_done  q[7:0]  frame_err  parity_err
uart_rx.s[2:0]  uart_rx.t_counter[3:0]  uart_rx.mv_cnt[1:0]
```

Zoom into a single frame to see the 16-tick bit windows and majority vote accumulation.
A full 8N1 frame at 115200 baud takes ~8.68 µs; at 50 MHz simulation time each baud
period is 434 clock cycles (27.1 µs simulation time at 1 ns/clock).

---

## Known Scope / Deliberately Deferred

These are architectural omissions, not bugs. They are listed here because a real
production UART controller would require them.

| Feature | Status | Notes |
|---------|--------|-------|
| TX/RX FIFO | Deferred | Caller must poll `idle` before `sr`; read `q` before next `rx_done` |
| Flow control (RTS/CTS) | Deferred | No handshaking pins |
| Top-level register-mapped wrapper (`uart_top.v`) | Deferred | No AXI-Lite or APB bus interface |
| SystemVerilog constrained-random testbench | Future | Current TB is directed; SV TB is Layer 6 in the roadmap |

---

## What's Next

- **Layer 4 — TX/RX FIFO:** 16-deep synchronous FIFO with full/empty flags; connects
  to TX and RX to remove the polling requirement
- **Layer 5 — `uart_top.v`:** Memory-mapped register file wrapping all four modules
  behind a standardized bus interface (AXI4-Lite or simple APB)
- **Project #3 — SPI Master** (Mode 0 + Mode 3)
