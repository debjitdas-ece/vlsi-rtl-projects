// HDLBits Problem 20: Modules
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, output out);
    mod_a inst (.in1(a), .in2(b), .out(out));
endmodule
