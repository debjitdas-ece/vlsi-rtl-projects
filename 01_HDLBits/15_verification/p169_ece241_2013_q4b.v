// HDLBits Problem 169: DFF
// Author: Debjit Das | JGEC ECE

module top_module (input clk, a, output reg q);
    always @(posedge clk) q <= ~a;
endmodule
