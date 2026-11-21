.RECIPEPREFIX = >
PASS = TOTAL: [0-9]+ PASS +0 FAIL
.PHONY: test test_legacy test_core lint clean

# test_core only runs once tb_spi_master_core.v is committed in this folder
test: test_legacy $(if $(wildcard tb_spi_master_core.v),test_core)

test_legacy:
> iverilog -g2012 -s tb_spi_master -o sim_spi.vvp spi_master.v spi_slave.v spi_tb.v
> vvp sim_spi.vvp | tee sim_spi.log
> grep -q 'RESULT: PASS' sim_spi.log

test_core:
> iverilog -g2012 -s tb_spi_master_core -o sim_core.vvp spi_master.v spi_master_core.v spi_slave.v spi_slave_bfm_burst.v tb_spi_master_core.v
> vvp sim_core.vvp | tee sim_core.log
> grep -Eq '$(PASS)' sim_core.log

lint:
> verilator --lint-only -Wall -Wno-fatal --top-module spi_master spi_master.v

clean:
> rm -f sim_*.vvp sim_*.log *.vcd
