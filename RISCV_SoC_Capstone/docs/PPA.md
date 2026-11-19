# PPA results (sky130A hd, LibreLane 3.0.17)

All numbers are copied from the flow's own `metrics.json` (kept per run in `docs/physical/`). Power is the flow's reported figure; I did not verify its switching-activity assumption.

## Final results (full flow, CLOCK_PERIOD = 16 ns = 62.5 MHz)

| | **Plus variant** (`fix16C`) | **Base variant** (`base16`) | Plus, original-spec floorplan (`fix16D`) |
|---|---|---|---|
| Setup worst slack (all corners) | **+1.741 ns** | **+1.616 ns** | +0.858 ns |
| Hold worst slack | +0.361 ns | +0.365 ns | +0.353 ns |
| Setup / hold violations | 0 / 0 | 0 / 0 | 0 / 0 |
| Magic DRC / KLayout DRC | 0 / 0 | 0 / 0 | 0 / 0 |
| LVS errors | 0 | 0 | 0 |
| Antenna violations | 0 | 0 | 0 |
| Router DRC markers | 0 | 0 | 0 |
| Slew / cap violations, typical corner (`nom_tt`) | 0 / 0 | 0 / 0 | 0 / 0 |
| Slew / cap violations, fast corner (`max_ff`) | 0 / 0 | 0 / 0 | 0 / 0 |
| **Slew / cap violations, slow corner (`max_ss_100C_1v60`)** | **1571 / 171** | **1006 / 107** | **3014 / 185** |
| Die area | 678,181 um^2 (about 823 x 823 um) | 594,651 um^2 | 1,000,000 um^2 (1000 x 1000 um) |
| Utilisation | 52.1 % | 52.7 % | 43.3 % |
| Std-cell count / area | 41,681 / 338,493 um^2 | 36,266 / 299,820 um^2 | 75,428 / 418,215 um^2 |
| Flip-flops / hold buffers / clock buffers | 4,181 / 5,093 / 416 | 3,902 / 4,690 / 405 | 4,181 / 4,960 / 460 |
| Total power (flow-reported) | 22.8 mW | 21.6 mW | 24.7 mW |
| Worst clock skew, typical / slow / fast corner | 391 / 496 / 354 ps | 332 / 405 / 310 ps | 417 / 559 / 367 ps |

GDS files are attached to the GitHub Release `riscv-soc-16ns` (SHA-256 below).

| File | SHA-256 of the .gz | SHA-256 of the unpacked .gds |
|---|---|---|
| `riscv_soc_plus_16ns.gds.gz` | `9b3258229b6259ec36b3a0c0ce16b0514cce4774c3546f70cabf01313d1580a4` | `f67e3e3587fd23a0a9247bb7abbf91ef211f273f22aefb9aa63f73a9e6bb29ab` |
| `riscv_soc_base_16ns.gds.gz` | `3fa8efcb253f5773a233114648bb28a2d35f1a8b269aa7a2fdbf19b813537d22` | `1a7953396a2944c09858184c0e2de65b20313bd01a1f4e8ab9cd00e9f985a890` |

## Final configuration (what `openlane/*/config.json` contains)
16 ns clock, relative floorplan (utilisation setting 40), placement density 55 %, `EXTRA_EXCLUDED_CELLS = [sky130_fd_sc_hd__buf_1, sky130_fd_sc_hd__clkbuf_1]`, `DESIGN_REPAIR_MAX_SLEW_PCT = DESIGN_REPAIR_MAX_CAP_PCT = 50`, `DRT_ANTENNA_REPAIR_ITERS = 10`, `DRT_ANTENNA_REPAIR_MARGIN = 30`. Async inputs (`uart_rx`, `fault_in`, `gpio_in`, `reset`) are false-pathed in the SDC because they pass through 2-FF synchronisers.

## Requirements: original course constraints vs result

| Original requirement | Result | Status |
|---|---|---|
| 20 ns clock | 16 ns closes with +1.74 ns (plus) / +1.62 ns (base) | exceeded |
| sky130A hd, routing up to met4 | same | met |
| DRC / LVS / antenna clean | 0 / clean / 0 | met |
| Fixed 1000 x 1000 um die, density 0.65, padding 4, root buffer clkbuf_16, max cap 0.35, diodes on ports | run `fix16D`: sign-off clean, timing closes, but worse quality (see below) | met by `fix16D`; optimised result uses a smaller die |
| CTS skew 150 ps | **not met**: 391 ps typical corner (plus), 332 ps (base). LibreLane 3.0.17 has no skew target | **not met** |
| Max slew / cap | clean at typical and fast corners; slow corner has mild residual violations | partly (slow corner only) |

## Run history (plus unless stated; all sign-off DRC/LVS clean)

| Run | Clock (ns) | Change vs previous | Setup WS | Hold WS | Antenna | Router DRC | Slew | Cap | Std-cell area (um^2) |
|---|---|---|---|---|---|---|---|---|---|
| run 1 | 20 | first complete flow | +3.086 | +0.362 | 2 | - | 6391 | 786 | 332,401 |
| antenna knobs | 20 | `DRT_ANTENNA_REPAIR_*`, resumed from routing | +3.086 | +0.362 | 0 | - | 6388 | 786 | 332,406 |
| `final18` | 18 | full flow, RTL fix, repair margins 30 | +2.214 | +0.368 | 0 | 1 | 3661 | 479 | 335,015 |
| `fixA` | 18 | exclude `buf_1`, `clkbuf_1` | +3.447 | +0.364 | 0 | 0 | 2366 | 269 | 337,449 |
| `fixAB` | 18 | + post-routing repair (experimental) | +3.749 | +0.364 | 0 | 0 | 2299 | 264 | 337,406 |
| `fix16` | 16 | `fixA` at 16 ns | +1.749 | +0.364 | 0 | 0 | 2299 | 264 | 337,406 |
| **`fix16C`** | 16 | repair margins 30 -> 50 | +1.741 | +0.361 | 0 | 0 | **1571** | **171** | 338,493 |
| `fix16D` | 16 | original floorplan and CTS settings | +0.858 | +0.353 | 0 | 0 | 3014 | 185 | 418,215 |
| `fix16E` | 16 | `fix16C` + CTS clusters size 10 / diameter 30 | +1.124 | +0.349 | 0 | 0 | 1700 | 183 | 368,139 |
| `fix16F` | 16 | `fix16C` + CTS clusters size 30 / diameter 80 | +2.049 | +0.368 | 0 | 0 | 1591 | 175 | 339,807 |
| **`base16`** (base variant) | 16 | `fix16C` settings | +1.616 | +0.365 | 0 | 0 | 1006 | 107 | 299,820 |

Clock skew (worst setup-path skew) by CTS setting, typical / slow / fast corner: `fix16C` 391 / 496 / 354 ps (416 clock buffers), `fix16E` 588 / 838 / 501 ps (1613 buffers), `fix16F` 430 / 564 / 380 ps (353 buffers). Default clustering gave the lowest skew; none of the three settings approached 150 ps.

## What was learned
* Slew/cap violations came from weak `buf_1` / `clkbuf_1` cells driving 10-15 sinks (`MAX_FANOUT_CONSTRAINT` only applies in synthesis and CTS). Excluding those cells, plus larger repair margins, cut slow-corner violations from 6391 / 786 to 1571 / 171.
* The post-routing repair step gave about 3 % on top and ran on incomplete routing estimates (LibreLane marks it experimental): not adopted.
* The original fixed 1000 x 1000 um floorplan costs 24 % more cell area and about 0.9 ns of slack, with twice the slow-corner slew violations.
* A single router DRC marker (met1 short, net `_18451_` vs VPWR) appeared in `final18` (evidence in `docs/physical/final18/`); it did not recur in any later run. Sign-off DRC and LVS were clean even in `final18`. I did not establish what removed it, so it is not claimed as fixed by a specific setting.
* `fix16` and `fixAB` produced identical slew/cap/area numbers despite different settings; not explained.
* Not investigated: the `base16` run directory numbers its steps up to 163, while the plus runs end at 75.

## Not done
Gate-level simulation of the final netlist; equivalence check (flow default skips it); riscv-arch-test; OpenRAM SRAM macro; skew target (see above); slow-corner slew/cap to zero.
