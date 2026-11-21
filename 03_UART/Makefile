.RECIPEPREFIX = >
SRCS = Baud_rate.v Uart_tx.v Uart_rx.v fifo_sync.v uart_core.v uart_top.v
PASS = TOTAL: [0-9]+ PASS +0 FAIL
.PHONY: test test_core test_top lint clean

test: test_core test_top

test_core:
> iverilog -g2012 -s tb_uart_core -o sim_core.vvp $(SRCS) tb_uart_core.v
> vvp sim_core.vvp | tee sim_core.log
> grep -Eq '$(PASS)' sim_core.log

test_top:
> iverilog -g2012 -s tb_uart_top -o sim_top.vvp $(SRCS) tb_uart_top.v
> vvp sim_top.vvp | tee sim_top.log
> grep -Eq '$(PASS)' sim_top.log

lint:
> verilator --lint-only -Wall -Wno-fatal --top-module uart_top $(SRCS)

clean:
> rm -f sim_*.vvp sim_*.log *.vcd
