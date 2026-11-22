// SVA for sync_fifo, attached with bind (no change to the RTL file).
module sync_fifo_sva #(parameter AW = 4)(
    input clk, rst_n, wr_en, rd_en, full, empty,
    input [AW:0] count
);
    a_not_full_and_empty : assert property (@(posedge clk) disable iff (!rst_n) !(full && empty));
    a_count_in_range     : assert property (@(posedge clk) disable iff (!rst_n) count <= (1 << AW));
    a_full_holds         : assert property (@(posedge clk) disable iff (!rst_n) (full  && !rd_en) |=> full);
    a_empty_holds        : assert property (@(posedge clk) disable iff (!rst_n) (empty && !wr_en) |=> empty);
    a_write_grows        : assert property (@(posedge clk) disable iff (!rst_n)
                               (wr_en && !full && !(rd_en && !empty)) |=> (count == $past(count) + 1'b1));

    c_full_reached       : cover property (@(posedge clk) disable iff (!rst_n) full);
    c_left_full          : cover property (@(posedge clk) disable iff (!rst_n) $fell(full));
    c_became_empty       : cover property (@(posedge clk) disable iff (!rst_n) $rose(empty));
    c_simul_rw           : cover property (@(posedge clk) disable iff (!rst_n) wr_en && rd_en && !full && !empty);
endmodule
bind sync_fifo sync_fifo_sva #(.AW(AW)) u_sva (.*);
