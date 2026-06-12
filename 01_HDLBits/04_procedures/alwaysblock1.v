// HDLBits Problem 29: Always blocks (combinational)
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, output out_assign, output reg out_alwaysblock);
    assign out_assign = a & b;
    always @(*) out_alwaysblock = a & b;
endmodule
