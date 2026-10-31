# SDC for LibreLane (used for both place&route and sign-off). Period comes from CLOCK_PERIOD in config.json.
set clk_input $::env(CLOCK_PORT)
create_clock [get_ports $clk_input] -name $clk_input -period $::env(CLOCK_PERIOD)
set_clock_uncertainty   0.25 [get_clocks $clk_input]
set_clock_transition    0.25 [get_clocks $clk_input]
set_driving_cell -lib_cell sky130_fd_sc_hd__clkbuf_16 -pin X [get_ports $clk_input]

# Every non-clock input is ASYNCHRONOUS to clk and enters through a 2-FF synchroniser (sync2) or the
# reset synchroniser (rst_sync, async assert / sync de-assert). They are not timed as synchronous paths.
set_false_path -from [get_ports {reset uart_rx}]
set_input_transition -max 0.50 [get_ports {reset uart_rx}]
set_input_transition -min 0.15 [get_ports {reset uart_rx}]

# Outputs leave the chip: constrain them against clk.
set OUT [get_ports {uart_tx}]
set_output_delay -max 4.0 $OUT -clock clk
set_output_delay -min 0.0 $OUT -clock clk
set_load -pin_load 0.017 $OUT
set_max_transition 1.500 [current_design]
