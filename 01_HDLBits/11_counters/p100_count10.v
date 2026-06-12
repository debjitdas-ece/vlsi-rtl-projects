// HDLBits Problem 100: Decade counter
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, output reg [3:0] q);
    always @(posedge clk)
        q <= (reset || q == 4'd9) ? 4'd0 : q + 1'b1;
endmodule
