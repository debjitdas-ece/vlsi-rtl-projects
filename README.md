# VLSI & RTL Design Portfolio — Debjit Das

[![regression](https://github.com/debjitdas-ece/vlsi-rtl-projects/actions/workflows/regression.yml/badge.svg)](https://github.com/debjitdas-ece/vlsi-rtl-projects/actions/workflows/regression.yml)
[![capstone](https://github.com/debjitdas-ece/vlsi-rtl-projects/actions/workflows/riscv-soc-capstone-ci.yml/badge.svg)](https://github.com/debjitdas-ece/vlsi-rtl-projects/actions/workflows/riscv-soc-capstone-ci.yml)

ECE @ JGEC · Samsung ISWDP @ IISc (3 Levels)
Verilog · SystemVerilog · GTKWave · iVerilog · OpenLANE · EDAPlayground
Daily GitHub push habit maintained — since Jun 2026

## 🧠 About This Repo
This repository tracks my complete VLSI and RTL design journey — from HDLBits problem solving to real RTL project builds, SystemVerilog testbenches, OpenLANE synthesis, and interview-focused ChipDev problems. Built alongside Samsung ISWDP training at IISc Bangalore.

## 🗂️ Project Roadmap
| # | Project | Tools | Timeline | Status |
|---|---|---|---|---|
| 0 | HDLBits — All Sections | Verilog | Jun 4–11 | ✅ Complete |
| 1 | 8-bit ALU (20 operations) | Verilog, iVerilog, GTKWave | Jun 11–16 | ✅ Complete |
| 2 | UART Tx/Rx (16× oversample, 286/286) | Verilog, iVerilog | Jun 17–20 | ✅ Complete |
| 3 | SPI Master (all 4 modes, 531/531) + burst, multi-SS, variable-width core (39/39) | Verilog, iVerilog | Jun 21–22 | ✅ Complete |
| 4 | Multi-Channel PWM IP Core (APB3, dead-time, trip protection, ASIC-targeted) | Verilog, iVerilog, GTKWave | Jun 23–Jul 7 | ✅ Complete |
| 5 | AMBA AXI4 Full System (2 master / 2 slave interconnect, round-robin arbitration, depth-4 outstanding tx) | Verilog-2001, iVerilog, GTKWave | Jul 2026 | ✅ Complete |
| 6 | RISC-V SoC Capstone (PicoRV32, AXI4-Lite bus, PWM IP, RTL→GDS with LibreLane/sky130) | Verilog, Verilator, iVerilog, Yosys, LibreLane | Oct 2026 | ✅ Simulation + RTL→GDS flow complete (16 ns); limitations documented |
| 7 |	FIFO, CDC & RDC (sync + async Gray-pointer FIFO, 2FF / pulse / handshake / reset synchronizers, CDC bug gallery, SVA)	Verilog, SystemVerilog assertions, iVerilog, Verilator	Nov 2026	✅ Complete (18/18 regression checks) |

## 📁 Repo Structure
```
vlsi-rtl-projects/
│
├── 01_HDLBits/                 ← All problems solved section by section ✅
│   ├── getting_started/
│   ├── vectors/
│   ├── modules/
│   ├── procedures/
│   └── circuits/
│
├── 02_ALU/                     ← 8-bit ALU: 20 ops, self-checking TB, 67/67 tests pass ✅
│   ├── alu.v
│   ├── alu_tb.v
│   ├── Makefile
│   └── README.md
│
├── 03_UART/                    ← UART Tx/Rx full duplex: 16× oversample, self-checking TB, 286/286 tests pass; FIFO core + register wrapper, 44 + 11 checks ✅
│   ├── Baud_rate.v  Uart_tx.v  Uart_rx.v  Uart_tb.v         ← Tx/Rx + 286-check TB
│   ├── fifo_sync.v  uart_core.v  uart_top.v                  ← FIFO core + register wrapper
│   ├── tb_uart_core.v  tb_uart_top.v                         ← 44 + 11 checks
│   ├── Makefile
│   └── README.md
│
├── 04_SPI/                     ← SPI Master: all 4 modes (CPOL/CPHA), slave BFM, timing-verified + burst / multi-SS / variable-width core ✅
│   ├── spi_master.v  spi_slave.v  spi_tb.v                   ← frozen single-word master, 531 checks
│   ├── spi_master_core.v  spi_slave_bfm_burst.v  tb_spi_master_core.v   ← burst, multi-SS, variable width, 39 checks
│   ├── Makefile
│   └── README.md
│
├── PWM_Controller/              ← Multi-channel PWM IP: APB3 register interface, double-buffered
│   │                              updates, dead-time insertion, trip/fault protection, multi-instance
│   │                              sync, dual ADC trigger generation. Self-checking TBs, 34,156 (top) + 8,038 (APB) checks pass ✅
│   ├── rtl/
│   │   ├── pwm_prescaler.v
│   │   ├── pwm_updown_counter.v
│   │   ├── pwm_dbuf.v
│   │   ├── pwm_compare.v
│   │   ├── pwm_deadtime.v
│   │   ├── pwm_trip.v
│   │   ├── pwm_adc.v
│   │   ├── pwm_top.v
│   │   └── pwm_apb_wrapper.v
│   ├── tb/
│   │   ├── tb_pwm_top.v
│   │   └── tb_apb.v
│   ├── docs/
│   │   └── MODULE_HIERARCHY.md
│   ├── filelist.f
│   └── README.md
│
├── axi/                         ← AMBA AXI4 full system: 2 masters, 2 slaves, round-robin
│   │                              interconnect, ID-tracked outstanding transactions (depth 4),
│   │                              burst support. Verilog-2001 only. All tests passing ✅
│   ├── rtl/
│   │   ├── Master/
│   │   │   ├── axi4_master_top.v
│   │   │   ├── axi_master_cmd_fsm.v
│   │   │   ├── axi_master_pending_fifo.v
│   │   │   ├── axi_master_rd_fsm.v
│   │   │   ├── axi_master_resp_check.v
│   │   │   └── axi_master_wr_fsm.v
│   │   ├── Slave/
│   │   │   ├── axi4_slave_top.v
│   │   │   ├── axi_addr_decode.v
│   │   │   ├── axi_rd_fsm.v
│   │   │   ├── axi_regmap.v
│   │   │   ├── axi_resp_gen.v
│   │   │   └── axi_wstrb_merge.v
│   │   ├── common/
│   │   │   ├── axi_burst_calc.v
│   │   │   ├── axi_id_tracker.v
│   │   │   └── axi_pkg.v
│   │   ├── interconnect/
│   │   │   ├── axi4_interconnect_top.v
│   │   │   ├── axi_ic_addr_map.v
│   │   │   ├── axi_ic_arbiter.v
│   │   │   ├── axi_ic_mux_rd.v
│   │   │   └── axi_ic_mux_wr.v
│   │   ├── axi4_system.f
│   │   └── axi4_system_top.v
│   ├── tb/
│   │   ├── tb_axi4_master_top.v
│   │   ├── tb_axi4_slave_top.v
│   │   ├── tb_axi4_system_top.v
│   │   └── tb_axi_common.v
│   ├── sim/
│   │   └── run.sh
│   └── README.md
│
├── RISCV_SoC_Capstone/          ← PicoRV32 SoC: AXI4-Lite bus + DECERR/SLVERR decoder, UART, PWM + GPIO,
│   │                              bus testbench + AXI4-Lite protocol checker, LibreLane sky130 run (metrics in docs/)
│   ├── rtl/  tb/  fw/  tools/  openlane/
│   ├── docs/  (PPA.md, coverage.md, physical/)
│   └── README.md
│
├── 05_FIFO_CDC_RDC/             ← Sync + async FIFO, CDC synchronizers, bug gallery, SVA bind files; 18/18 regression checks ✅
│   ├── rtl/  tb/  sva/  cdc_bugs/  scripts/
│   ├── Makefile
│   └── README.md
├── .gitattributes               ← Forces GitHub to recognize .v as Verilog
├── .gitignore                   ← Excludes sim build artifacts (*.out, *.vcd, *.vvp, *.o)
└── README.md
```

## 🛠️ Tools & Environment
| Tool | Purpose |
|---|---|
| Verilog | RTL Design language |
| SystemVerilog | Testbench writing |
| iVerilog | Open-source Verilog simulator |
| GTKWave | Waveform viewer for simulation output |
| EDAPlayground | Online SystemVerilog simulation |
| OpenLANE | Open-source RTL→GDSII flow |
| LibreLane | Open-source RTL→GDSII flow (used for the RISC-V SoC) |
| Verilator | Fast RTL simulation, lint and coverage |
| Magic VLSI | Layout viewer |
| Yosys | Logic synthesis |
| HDLBits | Structured Verilog problem set |
| ChipDev.io | Interview-focused RTL problems |
| nandland.com | RTL design reference and tutorials |

## 🏅 Certifications & Training
| Certification | Date | Status |
|---|---|---|
| HDLBits — 100% All Sections | Jun 11, 2026 | ✅ Complete |
| Samsung ISWDP @ IISc — Level 1 | Jul 2026 | ✅ Complete |
| Samsung ISWDP @ IISc — Level 2 | Aug 2026 | ✅ Complete |
| Samsung ISWDP @ IISc — Level 3 Advance | Aug 15–23, 2026 | ✅ Complete |
| NPTEL | 2026 | 🔄 Ongoing |

## 📬 Contact
Debjit Das · B.Tech ECE @ JGEC
📧 debjitdas.intern@gmail.com
🔗 LinkedIn
