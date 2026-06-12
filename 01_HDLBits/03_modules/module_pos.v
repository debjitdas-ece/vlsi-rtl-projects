// HDLBits Problem 21: Connecting ports by position
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, c, d, output out1, out2);
    mod_a inst (out1, out2, a, b, c, d);
endmodule
