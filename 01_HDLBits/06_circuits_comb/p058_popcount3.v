// HDLBits Problem 58: 3-bit population count
// Author: Debjit Das | JGEC ECE

// Method 1: + operator
module top_module (input [2:0] in, output [1:0] out);
    assign out = in[0] + in[1] + in[2];
endmodule
