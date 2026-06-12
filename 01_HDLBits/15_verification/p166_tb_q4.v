// HDLBits Problem 166: Testbench Q4
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, c, d, output q);
    assign q = (a|b|c) & (~a|b|c);
endmodule
