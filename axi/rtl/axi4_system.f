# axi4_system.f
# Compile-order filelist for axi4-full-system.
# axi_pkg.v MUST come first -- every other file relies on its `define`s
# being active at compile time, with no explicit `include in the RTL files.
#
# Usage:
#   iverilog -f rtl/axi4_system.f -o sim/build.out
#
# Grow this list as each new module is written.

# --- common ---
rtl/common/axi_pkg.v
rtl/common/axi_burst_calc.v
rtl/common/axi_id_tracker.v

# --- slave ---
rtl/slave/axi_addr_decode.v
rtl/slave/axi_wr_fsm.v
rtl/slave/axi_rd_fsm.v
rtl/slave/axi_wstrb_merge.v
rtl/slave/axi_resp_gen.v
rtl/slave/axi_regmap.v
rtl/slave/axi4_slave_top.v

# --- master ---
rtl/master/axi_master_pending_fifo.v
rtl/master/axi_master_cmd_fsm.v
rtl/master/axi_master_wr_fsm.v
rtl/master/axi_master_rd_fsm.v
rtl/master/axi_master_resp_check.v
rtl/master/axi4_master_top.v
# --- interconnect ---
rtl/interconnect/axi_ic_addr_map.v
rtl/interconnect/axi_ic_arbiter.v
rtl/interconnect/axi_ic_mux_wr.v
rtl/interconnect/axi_ic_mux_rd.v
rtl/interconnect/axi4_interconnect_top.v
# --- top ---         
rtl/axi4_system_top.v
