// HDLBits Problem 85: 8 DFFs with async reset
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, input [7:0] d, output reg [7:0] q);
    always @(posedge clk or posedge areset)
        if (areset) q <= 8'd0; else q <= d;
endmodule
