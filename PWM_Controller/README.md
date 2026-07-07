# Multi-Channel PWM IP Core

A synthesizable, multi-channel PWM controller written in Verilog, built for ASIC/FPGA motor-control and power-electronics applications. It integrates an APB3 register interface, double-buffered register updates, programmable dead-time insertion, trip/fault protection, multi-instance phase sync, and dual ADC trigger generation — all behind a single register-mapped wrapper.

## Features

- **N configurable channels** (default `N = 3`), each with independent duty cycle and polarity control
- **Edge-aligned and center-aligned counting modes**, selectable at runtime via `mode_sel`
- **Double-buffered (shadow) registers** for `TOP_VAL` and per-channel duty — new values are latched on write but only committed to the active counter at the next counter trough (`z_f`), preventing mid-cycle glitches
- **Programmable dead-time insertion** per channel, with independent rising-edge and falling-edge dead-time cycle counts, generating non-overlapping high-side/low-side outputs
- **Trip/fault protection**: external trip input and software-triggered soft-trip, with both latched (manual-clear) and auto-clear (cycle-by-cycle, cleared at `z_f`) trip modes, forcing all outputs to a configurable safe state
- **Multi-instance phase synchronization**: `sync_in`/`sync_en` let one instance phase-align its counter to another via `phase_offset`; `sync_out` pulses once per cycle for daisy-chaining
- **Dual ADC trigger generation**: two independent trigger-point comparators (`trig_point_a/b`) with optional counting-direction qualification, for sampling current/voltage at a specific point in the switching cycle
- **APB3 slave register interface** wrapping the whole core, with a register-write lock bit that protects `TRIP_CTRL` and `DEADTIME` from accidental writes
- **Self-checking testbenches** with pass/fail counters suitable for CI regression (no waveform inspection required to confirm correctness)

## Architecture

```
pwm_apb_wrapper                          (APB3 slave, params: P_S, N, SAFE_STATE)
└─ pwm_top                                (params: P_S, N, SAFE_STATE)
   ├─ pwm_prescaler                       tick generation from clk
   ├─ pwm_updown_counter                  edge/center-aligned counter, dir, trough marker (z_f)
   ├─ pwm_dbuf (top_val)                  double-buffered TOP_VAL, committed at z_f
   ├─ pwm_adc  x2                         independent ADC trigger comparators (A/B)
   ├─ per channel (xN):
   │    ├─ pwm_dbuf                       double-buffered duty cycle, committed at z_f
   │    ├─ pwm_compare                    duty vs. counter comparator
   │    └─ pwm_deadtime                   rising/falling dead-time insertion → hs/ls pair
   └─ pwm_trip (shared, N_bits = 2*N)     trip/fault gating → safe-state output
```

`pwm_out` is `2*N` bits wide: `pwm_out[2*i]` = channel *i* high-side, `pwm_out[2*i+1]` = channel *i* low-side.

Full signal-level walkthrough and generate-block instance naming: [`docs/MODULE_HIERARCHY.md`](docs/MODULE_HIERARCHY.md).

## Register Map (`pwm_apb_wrapper.v`)

| Offset | Register     | Bits                                              |
|--------|--------------|----------------------------------------------------|
| 0x00   | CTRL         | [0] mode_sel, [1] sync_en                          |
| 0x04   | PHASE_OFFSET | [10:0]                                             |
| 0x08   | TOP_VAL      | [10:0], write pulses `top_id` next cycle           |
| 0x0C   | DUTY0        | [10:0], write pulses `duty_id[0]` next cycle        |
| 0x10   | DUTY1        | [10:0], write pulses `duty_id[1]` next cycle        |
| 0x14   | DUTY2        | [10:0], write pulses `duty_id[2]` next cycle        |
| 0x18   | POLARITY     | [2:0]                                              |
| 0x1C   | DEADTIME     | [7:0] rising cycles, [15:8] falling cycles         |
| 0x20   | TRIP_CTRL    | [0] trip_mode, [1] trip_clear (W1 pulse), [2] soft_trip |
| 0x24   | TRIG_CTRL    | [0]/[2] trig_en_a/b, [1]/[3] dir_qual_a/b          |
| 0x28   | TRIG_POINT_A | [10:0]                                             |
| 0x2C   | TRIG_POINT_B | [10:0]                                             |
| 0x30   | STATUS (RO)  | [0] trip_active, [1] adc_trig_a, [2] adc_trig_b    |
| 0x34   | LOCK         | [0] — blocks writes to TRIP_CTRL and DEADTIME while set |

`DUTY0..2` currently scale with the default `N = 3`; instantiating with a different `N` extends/reduces the duty registers accordingly.

## Repository Layout

```
pwm-ip-core/
├── rtl/                     synthesizable RTL, in compile order
│   ├── pwm_prescaler.v
│   ├── pwm_updown_counter.v
│   ├── pwm_dbuf.v
│   ├── pwm_compare.v
│   ├── pwm_deadtime.v
│   ├── pwm_trip.v
│   ├── pwm_adc.v
│   ├── pwm_top.v            (instantiates all of the above)
│   └── pwm_apb_wrapper.v    (instantiates pwm_top, APB3 slave)
├── tb/
│   ├── tb_pwm_top.v         core-level self-checking testbench
│   └── tb_apb.v             APB register-interface self-checking testbench
├── docs/
│   └── MODULE_HIERARCHY.md  full instance tree + signal-flow diagram
└── filelist.f               compile-order file list for iverilog/other tools
```

## Simulation

Tooling used during development: **Icarus Verilog (iverilog v12)** + **GTKWave**, on WSL.

```bash
# Core-level testbench (pwm_top, no APB)
iverilog -o sim -f filelist.f
vvp sim

# APB register interface testbench
iverilog -o sim_apb rtl/pwm_prescaler.v rtl/pwm_updown_counter.v rtl/pwm_dbuf.v \
    rtl/pwm_compare.v rtl/pwm_deadtime.v rtl/pwm_trip.v rtl/pwm_adc.v \
    rtl/pwm_top.v rtl/pwm_apb_wrapper.v tb/tb_apb.v
vvp sim_apb

# Inspect waveforms
gtkwave tb_pwm_top.vcd
```

Both testbenches are self-checking: they run a directed sequence of stimulus, track pass/fail counts internally, and print a summary:

```
==============================================
PASS = <n>  FAIL = 0
RESULT: ALL CHECKS PASSED
==============================================
```

- `tb_pwm_top.v` — 39 checks covering: edge-aligned/center-aligned counter sequencing against a reference model, double-buffer commit timing at `z_f`, dead-time insertion on both edges, ADC trigger generation with direction qualification, trip latch/auto-clear behavior, and sync in/out phase alignment, plus toggle-activity sanity checks.
- `tb_apb.v` — 19 checks covering register write/readback for every offset, commit-pulse timing (`top_id`/`duty_id`) on TOP/DUTY writes, LOCK-bit write-blocking on TRIP_CTRL and DEADTIME, and trip status reflected through STATUS.

## Design Notes

- All internal counters/comparators are 11-bit (`[10:0]`), supporting a PWM resolution up to 2047 counts.
- Dead-time is specified independently for rising and falling edges, in prescaled clock cycles (8-bit, up to 255 cycles each), and is bypassed entirely (zero insertion delay) when the corresponding count is programmed to 0.
- Trip has two modes: **latched** (`trip_mode = 0`, requires an explicit `trip_clear` write) and **cycle-by-cycle** (`trip_mode = 1`, auto-clears at the next counter trough `z_f`) — suited to fast overcurrent protection without CPU intervention.
- `pwm_trip` is shared across all channels (operates on the full `2*N`-bit bus) so a single fault event forces every high-side/low-side pair to the safe state simultaneously.

## Status

RTL complete for all listed modules; both testbenches pass with 0 failures on Icarus Verilog v12. Not yet run through synthesis/timing closure.

## License

MIT (or update to match the rest of the `vlsi-rtl-projects` repo's license).
