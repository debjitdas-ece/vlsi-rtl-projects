.RECIPEPREFIX = >
PASS = RESULT: ALL CHECKS PASSED
.PHONY: test test_top test_apb clean

test: test_top test_apb

test_top:
> iverilog -g2012 -s tb_pwm_top -o sim_top.vvp -f filelist.f tb/tb_pwm_top.v
> vvp sim_top.vvp > sim_top.log
> tail -4 sim_top.log
> grep -q '$(PASS)' sim_top.log

test_apb:
> iverilog -g2012 -s tb_apb -o sim_apb.vvp -f filelist.f tb/tb_apb.v
> vvp sim_apb.vvp > sim_apb.log
> tail -4 sim_apb.log
> grep -q '$(PASS)' sim_apb.log

clean:
> rm -f sim_*.vvp sim_*.log *.vcd
