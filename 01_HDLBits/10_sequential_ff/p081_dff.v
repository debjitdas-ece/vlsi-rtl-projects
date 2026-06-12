// HDLBits Problem 81: D flip-flop
// Author: Debjit Das | JGEC ECE

module top_module (input clk, d, output reg q);
    always @(posedge clk) q <= d;
endmodule
