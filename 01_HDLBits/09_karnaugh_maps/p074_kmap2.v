// HDLBits Problem 74: Karnaugh map 2
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, c, d, output out);
    assign out = (~a & ~d) | (~b & ~c) | (~a & b & c) | (a & c & d);
endmodule
