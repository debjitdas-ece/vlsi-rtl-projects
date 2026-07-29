# axi4-full-system

A complete AMBA AXI4 system — master, slave, and a basic interconnect —
built entirely in Verilog-2001 (no SystemVerilog, no SVA). Where SVA would
normally be used for protocol checking, this project uses plain Verilog
procedural checker tasks (`tb/checkers/`) instead — `always @(posedge clk)`
blocks with `$display`/`$finish` on violation. This is a deliberate
single-language scope decision, not a missing feature:

> "Verification uses procedural Verilog checkers rather than SVA, by
> design, to keep the stack single-language."

This is a step up from every prior project in this portfolio (UART / SPI /
PWM were all single-role peripherals) — here both ends of the bus, plus
the fabric connecting them, are built from scratch, which is what makes it
read as system design rather than peripheral design.

---

## Build status

Staged bottom-up: common building blocks first, proven standalone via
self-checking testbenches, before any FSM or integration work depends
on them.

| Module | Status | Notes |
|---|---|---|
| `rtl/common/axi_pkg.v` | Done | Shared macros — resp codes, burst types, address map. |
| `rtl/common/axi_burst_calc.v` | **Done + verified** | FIXED/INCR/WRAP next-address generator. Passes `tb_axi_common.v` (all burst types, all beat counts, reserved-encoding fallback). |
| `rtl/common/axi_id_tracker.v` | **Done + verified** | Outstanding-transaction depth-cap-per-ID. Passes `tb_axi_common.v` (depth cap, cross-ID independence, same-cycle collision, reset clear). Not yet wired into the master side at time of writing this line — see Master architecture below, where it finally gets a consumer. |
| `rtl/slave/axi_addr_decode.v` | **Done + verified** | Region + 4KB boundary check. |
| `rtl/slave/axi_wr_fsm.v` | **Done + verified** | AW/W/B sequencing. |
| `rtl/slave/axi_rd_fsm.v` | **Done + verified** | AR/R sequencing. |
| `rtl/slave/axi_wstrb_merge.v` | **Done + verified** | Byte-lane masked write-data merge. |
| `rtl/slave/axi_resp_gen.v` | Done, unused | Correct standalone, but `axi_wr_fsm`/`axi_rd_fsm` currently compute `bresp`/`rresp` inline rather than instantiating this — open item, not a bug. |
| `rtl/slave/axi_regmap.v` | **Done + verified** | 4KB (1024-word) storage, dual read port (real reads + wstrb-merge context). |
| `rtl/slave/axi4_slave_top.v` | **Done + verified** | All 7 slave modules wired together. Passes `tb_axi4_slave_top.v` — single/multi-beat writes+reads, partial WSTRB, out-of-region DECERR, boundary-crossing DECERR, WRAP burst end-to-end, back-to-back bursts. |
| **Slave side: complete.** | | |
| `rtl/master/axi_master_pending_fifo.v` | **Done + verified logic** (standalone TB not yet written) | Depth-4 circular FIFO, instantiated twice (write + read) per the symmetric design below. |
| `rtl/master/axi_master_cmd_fsm.v` | **Done** | Dispatches AW/AR, gated by two separate `axi_id_tracker` instances, pushes onto the matching direction's FIFO on every accepted dispatch. |
| `rtl/master/axi_master_wr_fsm.v` | **Done** | Pops from the write FIFO when idle, drives W beats via `axi_burst_calc`, waits for B. |
| `rtl/master/axi_master_rd_fsm.v` | Not started | Pops from the read FIFO when idle, accepts R beats. No `axi_burst_calc` needed (receiver only). |
| `rtl/master/axi_master_resp_check.v` | Not started | |
| `rtl/master/axi4_master_top.v` | Not started | |
| Interconnect (5 modules) | Not started | `NUM_MASTERS`/`NUM_SLAVES` become `parameter`s here — see policy table. |
| System integration + checkers | Not started | |

---

## System architecture

```
Stage 1: axi4_master.v  <-- point to point -->  axi4_slave.v
Stage 2: 2x axi4_master.v -- axi4_interconnect.v -- 2x axi4_slave.v
Stage 3: full regression + checker tasks + coverage counters across both
```

**Confirmed system parameters (Stage 2):**
- 2 masters, 2 slaves
- Round-robin arbitration
- Outstanding transaction depth: 4 per master
- AxSIZE: fixed 32-bit (4 bytes/beat) for v1
- 4KB boundary violation response: DECERR

---

## Master architecture: outstanding-transaction support (revised)

The original plan's single-FSM-per-channel master ("front door" dispatches
one command, blocks until it fully completes) was reconsidered in favor of
genuinely supporting multiple outstanding transactions, matching what
`axi_id_tracker` was already built to gate.

**Symmetric FIFO design (both directions):** `axi_master_pending_fifo.v`
(depth-4 circular FIFO, storing `addr/len/size/burst/id`) is instantiated
*twice* — once for the write path, once for the read path. `cmd_fsm`
dispatches AW or AR, and on acceptance pushes that burst's parameters onto
the matching FIFO. `axi_master_wr_fsm`/`axi_master_rd_fsm` each pop from
their own FIFO whenever idle, independent of how far ahead `cmd_fsm` has
already dispatched. This is a genuine architectural mirror, not a
write-only special case — reads get the same depth-4 outstanding dispatch
throughput as writes.

Two separate `axi_id_tracker` instances (one per direction) gate
`cmd_ready`, avoiding a same-cycle write-complete/read-complete collision
that a single shared tracker's one-completion-per-cycle interface
couldn't have handled cleanly.

**One honest scope line, worth stating plainly:** this fixes *dispatch*
throughput — up to 4 reads (or writes) can have their address phase
accepted without `cmd_fsm` stalling. It does not add true interleaved
R-beat reception across multiple in-flight bursts simultaneously; that
would require per-ID R-channel demuxing inside `axi_master_rd_fsm`, a
separate and larger feature not currently planned. `axi_master_rd_fsm`
still services one popped burst's R beats fully before starting the next,
same as `axi_master_wr_fsm` does for W beats — the FIFO buys queuing
depth at the front door, not parallel data-phase servicing.

**Revised module responsibilities:**

| Module | Role |
|---|---|
| `axi_master_pending_fifo` | Depth-4 circular FIFO. Instantiated twice — once per direction. Stores `addr/len/size/burst/id` per accepted AW or AR. |
| `axi_master_cmd_fsm` | Dispatches AW or AR. `cmd_ready` gated by the matching direction's `axi_id_tracker.issue_ready`, which itself factors in that direction's FIFO having room. Pushes onto the matching FIFO on every accepted dispatch. Calls `complete_valid`/`complete_id` on the matching tracker when B (write) or final R (read) arrives. |
| `axi_master_wr_fsm` | Pops from the write FIFO whenever idle, drives W beats (via `axi_burst_calc`, same pattern as the slave-side FSMs), waits for B. |
| `axi_master_rd_fsm` | Pops from the read FIFO whenever idle, accepts R beats. No `axi_burst_calc` needed here — AR only carries the starting address, the slave walks the burst on its own end. |
| `axi_master_resp_check` | Inspects BRESP/RRESP, flags `resp_err` with the failing ID. Unaffected by the pipelining change. |

Documented here as a deliberate, honestly-scoped v1 decision, same pattern
as the AxSIZE and Verilog-only calls elsewhere in this project: *"the
master supports genuinely pipelined outstanding transaction dispatch on
both read and write paths via matched pending-command FIFOs, so
`axi_id_tracker`'s depth-4 outstanding capability is exercised
symmetrically from the master interface — with the explicit caveat that
data-phase servicing (W-beat driving, R-beat receiving) remains serialized
per direction, not per-ID interleaved."*

---

## Flexibility & parameterization policy

This project is not a general-purpose, drop-in AXI4 IP block — several
values are fixed for this specific build rather than left runtime- or
instantiation-configurable. This table is the single source of truth for
what's flexible today, what's fixed by deliberate scope decision, and
where the fix point is if a dimension needs to become configurable later.

| Dimension | Status | Why | Fix point (if ever needed) |
|---|---|---|---|
| Burst length (`len`) | **Flexible today** | `axi_burst_calc` computes `extra_bits`/`mask_width` live from `len` every call — no recompile needed, handles 2/4/8/16-beat WRAP in the same simulation | — |
| Beat size (`size`) | **Flexible today** | Shift-based math (`1<<size`) is value-agnostic | — |
| Backpressure / stall duration | **Flexible today** | Every FSM (slave and, going forward, master) only advances state on real handshake conditions, never assumes bounded stall time | — |
| Data width (32-bit) | Fixed, cheaply fixable | `AXI_DATA_WIDTH` is a macro in `axi_pkg.v`; slave-side modules built so far use literal `[31:0]` rather than the macro | Retroactive cleanup: replace `[31:0]` with `[`AXI_DATA_WIDTH-1:0]` across slave modules if width is ever revisited. Not urgent while width stays 32-bit. |
| Outstanding transactions, master-side | **Flexible, both directions** | `axi_master_pending_fifo` (instantiated per-direction) + two `axi_id_tracker` instances gate genuine multi-outstanding dispatch on both read and write paths, depth set by `DEPTH`/`OUTSTANDING_DEPTH` parameters | — |
| `NUM_MASTERS` / `NUM_SLAVES` | Fixed, genuinely rigid | Currently global `` `define ``s — one value for the whole compile, can't have two differently-sized interconnects in one build | Convert to `parameter #(NUM_MASTERS=2, NUM_SLAVES=2)` with `generate`/`genvar`-sized arbiter/mux arrays. Apply in `axi_ic_arbiter.v`, `axi_ic_mux_wr.v`, `axi_ic_mux_rd.v`, `axi4_interconnect_top.v` at Stage 2 |
| `OUTSTANDING_DEPTH` | **Fixed correctly, per-module** | Already a `parameter` (`DEPTH`) on `axi_id_tracker.v`; `axi_master_pending_fifo.v` will use the same pattern | — |
| Address map (Slave0/1 base+limit) | Fixed, `parameter`ized per-instance | `axi_addr_decode.v` takes `REGION_BASE`/`REGION_LIMIT` as parameters, defaulted from the pkg macros — `axi4_slave_top.v` inherits the same parameters, so Slave 0 vs Slave 1 is just an instantiation-time override | — |
| 4KB boundary / DECERR policy | Fixed by spec | Hard AXI4 requirement, not a project choice | Correctly rigid — no fix needed |
| Arbitration policy | Fixed, round-robin only | `axi_ic_arbiter` as planned implements one policy | If a second policy (fixed-priority) is ever wanted: `ARB_POLICY` parameter + `generate if`, decided before the arbiter FSM is written, not after |
| AxSIZE (32-bit only) | Fixed, documented scope cut | Deliberate v1 scope decision (plan Section 8), not an oversight | Would need real narrow-transfer byte-lane logic in `axi_wstrb_merge`/`axi_regmap` — not currently planned |
| EXOKAY / exclusive access | Fixed — unsupported | Requires a dedicated exclusive-monitor module tracking locked address+ID pairs, plus FSM changes in both master and slave; no macro touches this | New module (`axi_excl_monitor.v`, not in current plan) + `axi_wr_fsm`/`axi_rd_fsm` changes — v2 scope, own design session |
| `AXI_ID_WIDTH` (4 bits) | Fixed, moderately rigid | Sized by hand for 2 masters × depth-4 outstanding | Once `NUM_MASTERS` is a parameter, derive as `$clog2(NUM_MASTERS * OUTSTANDING_DEPTH)` instead of a fixed macro |
| Reserved `burst_type = 2'b11` | Handled, not spec-mandated | `axi_burst_calc` falls back to FIXED-like behavior (`addr_in`) — a deliberate design choice, not required by spec | Documented here so it doesn't read as an oversight |
| `axi_resp_gen.v` wiring | Built, not consumed | FSMs compute `bresp`/`rresp` inline instead of instantiating it | Could refactor FSMs to instantiate it instead, at any point — purely a code-organization choice, no functional difference today |

---

## Verified test coverage

| Testbench | Covers | Result |
|---|---|---|
| `tb_axi_common.v` | `axi_burst_calc` (all burst types, all beat counts, reserved-encoding fallback) + `axi_id_tracker` (depth cap, cross-ID independence, same-cycle collision, reset clear) | **23/23 passing** |
| `tb_axi4_slave_top.v` | Full slave integration — single/multi-beat R/W, partial WSTRB merge, out-of-region DECERR, 4KB-boundary-crossing DECERR, WRAP burst end-to-end, back-to-back bursts | **All passing** |

Both use the same self-checking `check`/`check32` task pattern (pass/fail
tally, `$display` on mismatch) — the same idiom will carry forward into
the master-side and interconnect testbenches.

---

## Directory layout

```
axi4-full-system/
├── rtl/
│   ├── common/        axi_pkg.v, axi_burst_calc.v, axi_id_tracker.v
│   ├── master/        pending_fifo, cmd_fsm, wr_fsm, rd_fsm, resp_check, top
│   ├── slave/         addr_decode, wr_fsm, rd_fsm, wstrb_merge, resp_gen, regmap, top
│   ├── interconnect/  addr_map, arbiter, mux_wr, mux_rd, top
│   ├── axi4_system_top.v
│   └── axi4_system.f
├── tb/
│   ├── checkers/       chk_handshake, chk_wlast, chk_rresp_per_beat, chk_id_ordering, chk_4kb_boundary
│   ├── tb_axi_common.v
│   ├── tb_axi4_slave_top.v
│   └── tb_*.v           remaining per-module + integration + negative + mutation testbenches
├── sim/run.sh
├── docs/               README.md (this file), regmap.md, coverage_plan.md
└── Makefile
```

---

## Reference

"Introduction to AXI Protocol | AXI Channels Explained | In-Order vs
Out-of-Order Transactions" — https://www.youtube.com/watch?v=XNzC6FJvloI