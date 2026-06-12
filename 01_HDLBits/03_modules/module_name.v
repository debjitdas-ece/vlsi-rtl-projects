// HDLBits Problem 22: Connecting ports by name
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, c, d, output out1, out2);
    mod_a inst (.in1(a), .in2(b), .in3(c), .in4(d), .out1(out1), .out2(out2));
endmodule
