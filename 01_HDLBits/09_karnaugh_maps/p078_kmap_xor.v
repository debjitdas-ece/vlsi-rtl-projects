// HDLBits Problem 78: XOR K-map
// Author: Debjit Das | JGEC ECE

module top_module (input [4:1] x, output f);
    assign f = (x[2] & x[4]) | (~x[1] & x[3]);
endmodule
