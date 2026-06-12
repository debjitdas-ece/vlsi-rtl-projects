// HDLBits Problem 30: Always blocks (clocked)
// Author: Debjit Das | JGEC ECE

module top_module (input clk, a, b,
    output reg out_always_comb, output reg out_always_ff);
    always @(*)        out_always_comb = a ^ b;
    always @(posedge clk) out_always_ff   = a ^ b;
endmodule
