# VLSI & RTL Design Portfolio — Debjit Das
ECE @ JGEC · Samsung ISWDP @ IISc (3 Levels)
Verilog · SystemVerilog · GTKWave · iVerilog · OpenLANE · EDAPlayground
Daily GitHub push habit maintained — Jun to Aug 2026

## 🧠 About This Repo
This repository tracks my complete VLSI and RTL design journey — from HDLBits problem solving to real RTL project builds, SystemVerilog testbenches, OpenLANE synthesis, and interview-focused ChipDev problems. Built alongside Samsung ISWDP training at IISc Bangalore.

## 🗂️ Project Roadmap
| # | Project | Tools | Timeline | Status |
|---|---|---|---|---|
| 0 | HDLBits — All Sections | Verilog | Jun 4–11 | ✅ Complete |
| 1 | 8-bit ALU (20 operations) | Verilog, iVerilog, GTKWave | Jun 11–16 | ✅ Complete |
| 2 | UART Tx/Rx (16× oversample, 286/286) | Verilog, iVerilog | Jun 17–20 | ✅ Complete |
| 3 | SPI Master (All 4 Modes, timing-verified) | Verilog, iVerilog | Jun 21–22 | ✅ Complete |
| 4 | Multi-Channel PWM IP Core (APB3, dead-time, trip protection, ASIC-targeted) | Verilog, iVerilog, GTKWave | Jun 23–Jul 7 | ✅ Complete |
| 5 | OpenLANE RTL→GDSII Flow | OpenLANE, Magic, Yosys | ISWDP phase | ⏳ Upcoming |

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
│   ├── alu_tb.vcd
│   └── README.md
│
├── 03_UART/                    ← UART Tx/Rx full duplex: 16× oversample, self-checking TB, 286/286 tests pass ✅
│   ├── uart_tx.v
│   ├── uart_rx.v
│   ├── uart_tb.v
│   ├── Baud_rate.v
│   ├── wave.vcd
│   ├── baud_gen.vcd
│   └── README.md
│
├── 04_SPI/                     ← SPI Master: all 4 modes (CPOL/CPHA), slave BFM, timing-verified ✅
│   ├── spi_master.v
│   ├── spi_slave.v
│   ├── spi_tb.v
│   ├── spi_tb.vcd
│   └── README.md
│
├── PWM_Controller/              ← Multi-channel PWM IP: APB3 register interface, double-buffered
│   │                              updates, dead-time insertion, trip/fault protection, multi-instance
│   │                              sync, dual ADC trigger generation. Self-checking TBs, 58/58 checks pass ✅
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
├── 06_OpenLANE/                 ← RTL→GDSII full synthesis flow
│   ├── config.json
│   ├── src/
│   └── results/
│
├── 07_ChipDev/                  ← ChipDev.io interview-style RTL problems
│
├── 08_SystemVerilog_TB/         ← SV testbenches (EDAPlayground)
│
├── .gitattributes               ← Forces GitHub to recognize .v as Verilog
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
| Magic VLSI | Layout viewer |
| Yosys | Logic synthesis |
| HDLBits | Structured Verilog problem set |
| ChipDev.io | Interview-focused RTL problems |
| nandland.com | RTL design reference and tutorials |

## 🏅 Certifications & Training
| Certification | Date | Status |
|---|---|---|
| HDLBits — 100% All Sections | Jun 11, 2026 | ✅ Complete |
| Samsung ISWDP @ IISc — Level 1 | Jul 2026 | ⏳ Upcoming |
| Samsung ISWDP @ IISc — Level 2 | Aug 2026 | ⏳ Upcoming |
| Samsung ISWDP @ IISc — Level 3 Advance | Aug 15–23, 2026 | ⏳ Upcoming |
| NPTEL | 2026 | 🔄 Ongoing |

## 📬 Contact
Debjit Das · B.Tech ECE @ JGEC
📧 debjitdas.intern@gmail.com
🔗 LinkedIn
