// HDLBits Problem 84: 8 DFFs with negedge reset
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, input [7:0] d, output reg [7:0] q);
    always @(negedge clk) q <= reset ? 8'h34 : d;
endmodule
