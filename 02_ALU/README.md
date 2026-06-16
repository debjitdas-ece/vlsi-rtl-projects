# 8-Bit ALU — Verilog RTL Design

## Overview
A fully synthesizable 8-bit Arithmetic Logic Unit (ALU) implemented in Verilog,
supporting 20 operations across arithmetic, logic, shift, rotate, and comparison categories.
Verified with a self-checking testbench — **67/67 tests pass**.

---

## Operations Supported (op[4:0])

| op | Mnemonic | Operation              |
|----|----------|------------------------|
| 0  | ADD      | a + b (with carry & overflow) |
| 1  | SUB      | a - b (with borrow & overflow) |
| 2  | INC      | a + 1                  |
| 3  | DEC      | a - 1                  |
| 4  | NEG      | Two's complement of a  |
| 5  | AND      | a & b                  |
| 6  | OR       | a \| b                 |
| 7  | XOR      | a ^ b                  |
| 8  | NOT      | ~a                     |
| 9  | LSL      | Logical shift left     |
| 10 | LSR      | Logical shift right    |
| 11 | ASL      | Arithmetic shift left  |
| 12 | ASR      | Arithmetic shift right |
| 13 | RL       | Rotate left            |
| 14 | RR       | Rotate right           |
| 15 | RLC      | Rotate left through carry |
| 16 | RRC      | Rotate right through carry |
| 17 | EQ       | a == b (result = 1 or 0) |
| 18 | GT       | a > b  (unsigned)      |
| 19 | LT       | a < b  (unsigned)      |

---

## Port Description

| Port | Width | Direction | Description              |
|------|-------|-----------|--------------------------|
| clk  | 1     | Input     | Clock                    |
| rst  | 1     | Input     | Synchronous reset        |
| a    | 8     | Input     | Operand A                |
| b    | 8     | Input     | Operand B                |
| op   | 5     | Input     | Opcode select            |
| res  | 8     | Output    | Combinational result     |
| z    | 1     | Output    | Zero flag (registered)   |
| c    | 1     | Output    | Carry flag (registered)  |
| o    | 1     | Output    | Overflow flag (registered) |
| n    | 1     | Output    | Negative flag (registered) |
| p    | 1     | Output    | Parity flag (registered) |

---

## Simulation

### Tools
- **Simulator:** Icarus Verilog (iverilog)
- **Waveform:** GTKWave (`alu_tb.vcd`)

### Run

```bash
iverilog -o sim alu.v alu_tb.v
./sim
```

### Result
RESULTS: 67 passed,  0 failed  /  67 total

*** ALL TESTS PASSED ***

---
## Design Notes
- `res` is **combinational** (zero latency); flags `z,c,o,n,p` are **registered** (1-cycle latency).
- `c_reg` internally latches the carry bit each clock, enabling correct RLC/RRC chained behavior.
- Signed overflow detection: ADD checks same-sign inputs producing opposite-sign output; SUB checks different-sign inputs producing opposite-sign output.
```

### Result
