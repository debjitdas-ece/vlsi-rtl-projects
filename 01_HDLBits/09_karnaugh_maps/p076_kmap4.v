// HDLBits Problem 76: Karnaugh map 4
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, c, d, output out);
    assign out = ((a^b) & ~(c^d)) | (~(a^b) & (c^d));
endmodule
