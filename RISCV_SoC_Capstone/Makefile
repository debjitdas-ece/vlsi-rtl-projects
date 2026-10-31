# RISC-V SoC capstone - top-level Makefile
# Primary flow: Verilator (fast).  Fallback flow: Icarus Verilog (make test-iverilog) - works with only iverilog+gtkwave+riscv gcc.
RTL_COMMON = rtl/picorv32.v rtl/axi_bridge.v rtl/axi_decoder.v rtl/axi_lite_interconnect.v rtl/axil_reg_if.v \
             rtl/rom.v rtl/sram.v rtl/uart_axi.v rtl/uart_tx.v rtl/uart_rx.v rtl/sync2.v rtl/rst_sync.v
RTL_PWM    = $(wildcard rtl/pwm/*.v) rtl/pwm_axi.v rtl/gpio_axi.v
TB_BUS_SRC = tb/tb_bus.v tb/axil_checker.v rtl/axi_decoder.v rtl/axi_lite_interconnect.v rtl/axil_reg_if.v rtl/rom.v rtl/sram.v
VFLAGS     = --binary --timing --trace-fst -Wno-fatal -Wno-lint -Wno-style -Wno-TIMESCALEMOD --x-initial 0 -Irtl
CROSS     ?= riscv64-unknown-elf-
SRAM_WORDS ?= 256        # 256 = 1 KB (sim default); 64 = 256 B (ASIC size)
VFLAGS    += -DSRAM_WORDS_DEF=$(SRAM_WORDS)
IVFLAGS    = -g2012 -Wno-timescale -Irtl -DSRAM_WORDS_DEF=$(SRAM_WORDS)

.PHONY: all test test-pwm test-bus test-asic-rom test-iverilog test-bus-iv test-pwm-iv sim-base-iv sim-plus-iv \
        fw-base fw-plus sim-base sim-plus wave wave-iv lint cov synth dash clean openlane-prep
all: test

fw-base: ; $(MAKE) -C fw APP=base CROSS=$(CROSS) RAM_LEN=$$(($(SRAM_WORDS)*4))
fw-plus: ; $(MAKE) -C fw APP=plus CROSS=$(CROSS) RAM_LEN=$$(($(SRAM_WORDS)*4))

# ------------------------------------------------------------------ Verilator flow
build/sim_base/Vtb_top: $(RTL_COMMON) rtl/top.v tb/tb_top.v tb/axil_checker.v
	verilator $(VFLAGS) --Mdir build/sim_base --top-module tb_top tb/tb_top.v tb/axil_checker.v rtl/top.v $(RTL_COMMON)
build/sim_plus/Vtb_top: $(RTL_COMMON) $(RTL_PWM) rtl/top_plus.v tb/tb_top.v tb/axil_checker.v
	verilator $(VFLAGS) -DPLUS --Mdir build/sim_plus --top-module tb_top tb/tb_top.v tb/axil_checker.v rtl/top_plus.v $(RTL_COMMON) $(RTL_PWM)

sim-base: fw-base build/sim_base/Vtb_top
	build/sim_base/Vtb_top +romhex=build/base/rom.hex $(SIMARGS) | tee build/base.log
sim-plus: fw-plus build/sim_plus/Vtb_top
	build/sim_plus/Vtb_top +romhex=build/plus/rom.hex $(SIMARGS) | tee build/plus.log

# boots SoC-plus from the synthesizable case-ROM (what LibreLane builds) at the ASIC SRAM size
test-asic-rom:
	$(MAKE) fw-plus SRAM_WORDS=64
	python3 tools/hex2rom.py build/plus/rom.hex build/rom_case_plus.v 1024
	verilator $(filter-out -DSRAM_WORDS_DEF=%,$(VFLAGS)) -DSRAM_WORDS_DEF=64 -DPLUS --Mdir build/sim_asicrom --top-module tb_top tb/tb_top.v tb/axil_checker.v rtl/top_plus.v $(filter-out rtl/rom.v,$(RTL_COMMON)) $(RTL_PWM) build/rom_case_plus.v
	build/sim_asicrom/Vtb_top | tee build/asicrom.log
	@grep -q "TEST PASSED" build/asicrom.log && echo "=== ASIC-ROM TEST PASSED ==="

test-pwm:
	verilator $(VFLAGS) --Mdir build/sim_pwm --top-module tb_pwm tb/tb_pwm.v $(wildcard rtl/pwm/*.v)
	build/sim_pwm/Vtb_pwm | tee build/pwm.log
	@grep -q "TEST PASSED" build/pwm.log
# bus-level test: interconnect + decoder + real ROM/SRAM, directed + 3000 random ops, protocol checkers
test-bus:
	verilator $(VFLAGS) --Mdir build/sim_bus --top-module tb_bus $(TB_BUS_SRC)
	build/sim_bus/Vtb_bus | tee build/bus.log
	@grep -q "TEST PASSED" build/bus.log
test: test-pwm test-bus sim-base sim-plus
	@grep -q "TEST PASSED" build/base.log && grep -q "TEST PASSED" build/plus.log && echo "=== ALL TESTS PASSED ===" || (echo "=== TEST FAILURE ==="; exit 1)

# ------------------------------------------------------------------ Icarus Verilog flow (iverilog + vvp + GTKWave only)
build/iv_base.vvp: $(RTL_COMMON) rtl/top.v tb/tb_top.v tb/axil_checker.v
	@mkdir -p build; iverilog $(IVFLAGS) -o $@ tb/tb_top.v tb/axil_checker.v rtl/top.v $(RTL_COMMON)
build/iv_plus.vvp: $(RTL_COMMON) $(RTL_PWM) rtl/top_plus.v tb/tb_top.v tb/axil_checker.v
	@mkdir -p build; iverilog $(IVFLAGS) -DPLUS -o $@ tb/tb_top.v tb/axil_checker.v rtl/top_plus.v $(RTL_COMMON) $(RTL_PWM)
sim-base-iv: fw-base build/iv_base.vvp
	vvp build/iv_base.vvp +romhex=build/base/rom.hex $(SIMARGS) | tee build/base_iv.log
sim-plus-iv: fw-plus build/iv_plus.vvp
	vvp build/iv_plus.vvp +romhex=build/plus/rom.hex $(SIMARGS) | tee build/plus_iv.log
test-pwm-iv:
	@mkdir -p build; iverilog $(IVFLAGS) -o build/iv_pwm.vvp tb/tb_pwm.v $(wildcard rtl/pwm/*.v)
	vvp build/iv_pwm.vvp | tee build/pwm_iv.log
	@grep -q "TEST PASSED" build/pwm_iv.log
test-bus-iv:
	@mkdir -p build; iverilog $(IVFLAGS) -o build/iv_bus.vvp $(TB_BUS_SRC)
	vvp build/iv_bus.vvp | tee build/bus_iv.log
	@grep -q "TEST PASSED" build/bus_iv.log
test-iverilog: test-pwm-iv test-bus-iv sim-base-iv sim-plus-iv
	@grep -q "TEST PASSED" build/base_iv.log && grep -q "TEST PASSED" build/plus_iv.log && echo "=== ALL IVERILOG TESTS PASSED ===" || (echo "=== TEST FAILURE ==="; exit 1)

# ------------------------------------------------------------------ waves
wave: ; $(MAKE) sim-plus SIMARGS=+wave && gtkwave build/tb_top.fst -a docs/soc_plus.gtkw &
wave-iv: ; $(MAKE) sim-plus-iv SIMARGS="-fst +wave" && gtkwave build/tb_top.fst -a docs/soc_plus.gtkw &

# ------------------------------------------------------------------ quality gates
LINT_RTL = rtl/picorv32.v rtl/axi_bridge.v rtl/axi_decoder.v rtl/axi_lite_interconnect.v rtl/axil_reg_if.v rtl/rom.v rtl/sram.v \
           rtl/uart_axi.v rtl/uart_tx.v rtl/uart_rx.v rtl/sync2.v rtl/rst_sync.v
# FAILS on any warning not waived in tools/lint.vlt
lint:
	verilator --lint-only -Wall tools/lint.vlt --top-module top rtl/top.v $(LINT_RTL)
	verilator --lint-only -Wall tools/lint.vlt --top-module top_plus rtl/top_plus.v $(LINT_RTL) $(RTL_PWM)
	@echo "=== LINT CLEAN ==="
cov: fw-plus
	rm -rf build/cov_sim build/cov; mkdir -p build/cov
	verilator --cc --exe --build --timing --coverage -Wno-fatal -Wno-lint -Wno-style -Wno-TIMESCALEMOD --x-initial 0 -Irtl \
	  -DSRAM_WORDS_DEF=$(SRAM_WORDS) -DPLUS --Mdir build/cov_sim --top-module tb_top \
	  tb/tb_top.v tb/axil_checker.v rtl/top_plus.v $(RTL_COMMON) $(RTL_PWM) $(CURDIR)/tools/cov_main.cpp
	build/cov_sim/Vtb_top +romhex=build/plus/rom.hex | tail -3
	python3 tools/cov_summary.py build/cov/coverage.dat docs/coverage.md

dash: ; python3 tools/dashboard.py build/uart_log.txt docs/telemetry.png
synth: ; bash tools/synth_check.sh
openlane-prep: ; bash tools/openlane_prep.sh
clean: ; rm -rf build/sim_* build/cov* build/*.log build/*.fst build/*.vvp
