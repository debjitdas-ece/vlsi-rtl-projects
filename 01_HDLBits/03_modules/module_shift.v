// HDLBits Problem 23: Three modules
// Author: Debjit Das | JGEC ECE

module top_module (input clk, d, output q);
    wire q1, q2;
    my_dff d1 (.clk(clk), .d(d),  .q(q1));
    my_dff d2 (.clk(clk), .d(q1), .q(q2));
    my_dff d3 (.clk(clk), .d(q2), .q(q));
endmodule
