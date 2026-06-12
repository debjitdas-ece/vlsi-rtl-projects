// HDLBits Problem 102: Slow decade counter
// Author: Debjit Das | JGEC ECE

module top_module (input clk, slowena, reset, output reg [3:0] q);
    always @(posedge clk)
        q <= reset ? 4'd0 : slowena ? (q == 4'd9 ? 4'd0 : q + 1'b1) : q;
endmodule
