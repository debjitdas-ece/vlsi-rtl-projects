// HDLBits Problem 75: Karnaugh map 3
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, c, d, output out);
    assign out = a | (~b & c);
endmodule
