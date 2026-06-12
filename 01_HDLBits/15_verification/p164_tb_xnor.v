// HDLBits Problem 164: Testbench for XNOR gate
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, c, d, output q);
    assign q = ((a^b)&(c^d)) | (~(a^b)&~(c^d));
endmodule
