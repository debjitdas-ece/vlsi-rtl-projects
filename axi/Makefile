.RECIPEPREFIX = >
PASS = TOTAL: [0-9]+ passed, 0 failed
TBS  = tb_axi_common tb_axi4_slave_top tb_axi4_master_top tb_axi4_system_top
.PHONY: test clean $(TBS)

test: $(TBS)

$(TBS):
> iverilog -g2001 -s $@ -f rtl/axi4_system.f tb/$@.v -o sim_$@.vvp
> vvp sim_$@.vvp | tee sim_$@.log
> grep -Eq '$(PASS)' sim_$@.log

clean:
> rm -f sim_*.vvp sim_*.log *.vcd
