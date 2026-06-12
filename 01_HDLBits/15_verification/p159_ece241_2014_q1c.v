// HDLBits Problem 159: NAND using andgate
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, c, output out);
    wire f;
    andgate inst1(.out(f),.a(a),.b(b),.c(c),.d(1'b1),.e(1'b1));
    assign out = ~f;
endmodule
