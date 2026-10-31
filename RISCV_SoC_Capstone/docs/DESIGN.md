# Design notes
* **Bridge** (`axi_bridge.v`): PicoRV32 native memory interface -> AXI4-Lite master FSM, one outstanding transaction.
* **Decoder** (`axi_decoder.v`): one-hot select with windows that equal the real memory sizes (parameters `ROM_BYTES`, `SRAM_BYTES`). No select -> default responder.
* **Interconnect** (`axi_lite_interconnect.v`): broadcast address/data, gated valids, muxed responses. Unmapped -> DECERR (`0xDEADBEEF` read data); write to ROM -> SLVERR.
* **Slaves** share `axil_reg_if.v` (AW and W accepted together, OKAY response); UART has its own slave for TX back-pressure.
* **Reset**: `rst_sync` (async assert, sync de-assert). **Inputs**: `sync2` 2-FF synchronisers (CDC), declared false paths in the SDC.
* **PWM**: prescaler, up/down counter, double-buffered duty, dead-time, trip (fault_in synchronised, latched until firmware clears and fault is gone), ADC trigger.
* **Verification**: `tb_pwm`, `tb_bus` (directed + random vs model), `tb_top` (full firmware), `axil_checker` on CPU/ROM/SRAM buses, Verilator coverage.
