// Gray-code pointers must change by at most one bit per clock, and flags must be sane.
module async_fifo_sva #(parameter AW = 4)(
    input wclk, wrst_n, input [AW:0] wgray, input wfull,
    input rclk, rrst_n, input [AW:0] rgray, input rempty
);
    a_wgray_1bit : assert property (@(posedge wclk) disable iff (!wrst_n) $countones(wgray ^ $past(wgray)) <= 1);
    a_rgray_1bit : assert property (@(posedge rclk) disable iff (!rrst_n) $countones(rgray ^ $past(rgray)) <= 1);
    c_wfull      : cover  property (@(posedge wclk) disable iff (!wrst_n) wfull);
    c_rempty     : cover  property (@(posedge rclk) disable iff (!rrst_n) rempty);
endmodule
bind async_fifo async_fifo_sva #(.AW(AW)) u_sva (.*);
