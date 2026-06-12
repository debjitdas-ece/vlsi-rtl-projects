// HDLBits Problem 51: Truth tables
// Author: Debjit Das | JGEC ECE

module top_module (input x3, input x2, input x1, output f);
    assign f = (x3 & x1) | (~x3 & x2);
endmodule
