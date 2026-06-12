// HDLBits Problem 165: Testbench for mux
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, c, d, output q);
    assign q = (a|b) & (c|d);
endmodule
