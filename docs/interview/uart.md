# UART: interview sheet

## What I built
A runtime-configurable UART (data width 5-8, parity, 1 or 2 stop bits) in three layers: a Tx/Rx pair with a 16x-oversampling receiver (286 checks), a core with 16-deep TX/RX FIFOs, RTS/CTS pins and an overrun flag (44 checks), and an APB3 register wrapper (11 checks).

## Three design decisions
1. **16x oversampling with a 3-tap majority vote.** The receiver samples at ticks 6, 7 and 8 of each bit and takes 2-of-3, so a single-sample glitch is corrected with no added latency. A glitch-injection test group covers it.
2. **Configuration as runtime inputs, not parameters.** `dbit`, `p_en`, `psel` and `sp_t` behave like control registers, the way a 16550-style peripheral is reconfigured by software, so the same hardware serves every frame format.
3. **`CTRL.EN` gates the core through its reset.** In `uart_top`, while EN=0 the FIFOs stay empty and both FSMs sit in IDLE, which matches how a real peripheral's enable bit behaves.

## A bug I hit
The majority vote always returned 0. I found it by looking at the waveform values of `mv_cnt` rather than reading the code: the counter was being reset on every `rx_tick` instead of only when entering a data or parity bit window, so it never accumulated. Fix: reset it only on entry to DATA/PARITY.
Others from the bug log: RX stuck in START (start sampled a tick too late), `rx_done` high for two cycles in 2-stop mode, `parity_err` leaking into the next frame.

## What I'd improve
A UVM environment with functional coverage (baud, width, parity, error injection), SVA on the FIFO invariants and the APB handshake, and a runtime baud divider (the baud rate is compile-time only today).
