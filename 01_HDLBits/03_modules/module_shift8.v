// HDLBits Problem 24: Modules and vectors
// Author: Debjit Das | JGEC ECE

module top_module (input clk, input [7:0] d, input [1:0] sel, output reg [7:0] q);
    wire [7:0] q1, q2, q3;
    my_dff8 d1 (.clk(clk), .d(d),  .q(q1));
    my_dff8 d2 (.clk(clk), .d(q1), .q(q2));
    my_dff8 d3 (.clk(clk), .d(q2), .q(q3));
    always @(*) case (sel)
        2'd0: q = d;  2'd1: q = q1;  2'd2: q = q2;  2'd3: q = q3;
    endcase
endmodule
