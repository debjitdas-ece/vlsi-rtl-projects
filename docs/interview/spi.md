# SPI master: interview sheet

## What I built
An SPI master supporting all four modes with parametric chip-select setup and hold timing, checked by a 531-check testbench that also verifies SCLK edge timing to the clock cycle. On top of it, `spi_master_core`: continuous-SS bursts, 8 slave selects and 1-16 bit words (39 checks).

## Three design decisions
1. **A new core instead of changing the verified master.** `spi_master` stays frozen with its 531 checks, and the new core is diffed against it cycle by cycle at burst length 1 and 8 bits, in all four modes. If the new module disturbed the verified single-word path, the diff would catch it.
2. **`cpol ^ cpha` picks the sample and shift edges.** Modes 0 and 3 sample on the rising edge, modes 1 and 2 on the falling edge, so one XOR replaces four mode decoders. In CPHA=1 modes the first shift is suppressed.
3. **Timestamp-based checks.** The testbench records every SCLK edge time and checks that each gap equals N system clocks, including across word boundaries, which is where the CPHA=1 sample/reload coincidence would break first.

## A bug I hit
In a 4-word burst, words 2 to 4 read back with garbage in the upper byte. The first symptom was `5500, 8000, 0000`, which turned out to be two stacked problems. The slave BFM only reloaded its TX register when SS fell, so it sent zeros after word 1; I wrote a burst-aware BFM. With that fixed, the failures became `55aa, d5aa`: the master never cleared `rx_shift` after capturing a word, so old bits survived. The original check compared only `rx_data[7:0]`, and it passed. I found it by tightening the check to the full 16-bit value. Fix: clear `rx_shift` at the last sample of each word.
Related: I replaced a check that was hard-wired to always pass (`burst_done reached idle`) with a real once-per-burst check, and proved it can fail by editing the expected count and watching it fail.

## What I'd improve
A UVM environment (all four modes, burst, multi-SS, variable width) with functional coverage, and SVA bind modules for `ss_n`/`sclk` timing and the `tx_load` handshake.
