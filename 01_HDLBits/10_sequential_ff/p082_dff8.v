// HDLBits Problem 82: 8 D flip-flops
// Author: Debjit Das | JGEC ECE

module top_module (input clk, input [7:0] d, output reg [7:0] q);
    always @(posedge clk) q <= d;
endmodule
