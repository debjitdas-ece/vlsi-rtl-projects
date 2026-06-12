// HDLBits Problem 47: Another gate
// Author: Debjit Das | JGEC ECE

module top_module (input in1, input in2, output out);
    assign out = in1 & (~in2);
endmodule
