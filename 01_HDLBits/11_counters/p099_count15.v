// HDLBits Problem 99: 4-bit binary counter
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, output reg [3:0] q);
    always @(posedge clk) q <= reset ? 4'd0 : q + 1'b1;
endmodule
