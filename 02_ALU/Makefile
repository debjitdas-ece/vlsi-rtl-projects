.RECIPEPREFIX = >
SRCS = alu.v
PASS = ALL TESTS PASSED
.PHONY: test lint clean

test:
> iverilog -g2012 -s alu_tb -o sim.vvp $(SRCS) alu_tb.v
> vvp sim.vvp | tee sim.log
> grep -q '$(PASS)' sim.log

lint:
> verilator --lint-only -Wall -Wno-fatal $(SRCS)

clean:
> rm -f sim.vvp sim.log *.vcd
