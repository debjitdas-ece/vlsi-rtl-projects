// HDLBits Problem 88: DFF with async reset
// Author: Debjit Das | JGEC ECE

module top_module (input clk, d, ar, output reg q);
    always @(posedge clk or posedge ar)
        if (ar) q <= 1'b0; else q <= d;
endmodule
