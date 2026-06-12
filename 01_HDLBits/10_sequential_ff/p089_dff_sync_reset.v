// HDLBits Problem 89: DFF with sync reset
// Author: Debjit Das | JGEC ECE

module top_module (input clk, d, r, output reg q);
    always @(posedge clk) if (r) q <= 1'b0; else q <= d;
endmodule
