# PPA results (SoC-plus, sky130A hd, LibreLane 3.0.17)

## Final run: `final18` (CLOCK_PERIOD = 18 ns, full flow, 2 h 23 min in WSL2)

| Metric | Value |
|---|---|
| Setup worst slack (all corners) | **+2.214 ns** |
| Hold worst slack (all corners) | **+0.368 ns** |
| Setup / hold violations | 0 / 0 |
| Magic DRC / KLayout DRC | 0 / 0 |
| LVS (netgen) | match, 0 errors |
| Antenna violations | 0 |
| **Router (TritonRoute) DRC markers** | **1** (see Known issues) |
| **Max slew violations (worst corner `max_ss_100C_1v60`)** | **3661** (not clean) |
| **Max cap violations (worst corner)** | **479** (not clean) |
| Std-cell area | 335,015 um^2 (41k cells incl. tap/antenna/hold/repair buffers) |
| Total power | not yet recorded |

Config deltas vs the first run: `CLOCK_PERIOD` 20 -> 18, `DESIGN_REPAIR_MAX_SLEW_PCT` / `_CAP_PCT` 10 -> 30, `DRT_ANTENNA_REPAIR_ITERS=10`, `DRT_ANTENNA_REPAIR_MARGIN=30`, plus the `pwm_axi` RTL fix (Yosys "conflicting drivers" 32 -> 0).

## Known issues (not hidden)
1. **1 router DRC marker**: a met1 "Short" between net `_18451_` (signal, driven by a `clkbuf_1`) and VPWR at about (560.5, 601.1) um, on the power-rail row boundary. Magic DRC, KLayout DRC, LVS and the antenna check are all clean, so it is probably a router-internal false marker, but this has **not been verified by inspecting the layout**. LibreLane exits with an error status because of it.
2. **Max slew / max cap violations remain at the slow corners** (`ss_100C_1v60`, also `tt`). The typical-corner / fast-corner (`ff`) results are clean for setup/hold. They come from weak `buf_1` / `clkbuf_1` cells driving 10-15 sinks. Raising the repair margins from 10 to 30 reduced slew violations 6391 -> 3661 and cap 786 -> 479, but did not eliminate them.

## Progression
| Run | Clock (ns) | Setup WS | Hold WS | Antenna | Slew | Cap | Notes |
|---|---|---|---|---|---|---|---|
| run 1 | 20 | +3.086 | +0.362 | 2 | 6391 | 786 | first complete flow |
| + antenna knobs | 20 | +3.086 | +0.362 | 0 | 6388 | 786 | resumed from detailed routing |
| **final18** | **18** | **+2.214** | **+0.368** | **0** | **3661** | **479** | **full flow, final RTL** |

## Clock sweep: re-timed from the 20 ns layout (NOT independent full flows)
These rows reuse run 1's placement/CTS/routing and only re-run STA with a tighter clock, so they say "this layout fails at that period", not "the flow cannot close it".

| Clock (ns) | Setup WS | Pass? |
|---|---|---|
| 16 | -0.914 | no |
| 14 | -2.914 | no |
| 12 | -4.914 | no |

A full flow at 16 ns has not been run. `final18` having +2.2 ns of margin suggests it may close, but that is a guess.

Not run: base variant through LibreLane.
