// HDLBits Problem 101: Decade counter again
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, output reg [3:0] q);
    always @(posedge clk)
        q <= (reset || q == 4'd10) ? 4'd1 : q + 1'b1;
endmodule
