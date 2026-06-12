// HDLBits Problem 83: 8 DFFs with synchronous reset
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, input [7:0] d, output reg [7:0] q);
    always @(posedge clk) q <= reset ? 8'd0 : d;
endmodule
