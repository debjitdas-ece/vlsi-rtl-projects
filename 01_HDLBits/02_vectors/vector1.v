// HDLBits Problem 12: Vectors in more detail
// Author: Debjit Das | JGEC ECE

module top_module (input [15:0] in, output [7:0] out_hi, output [7:0] out_lo);
    assign out_hi = in[15:8];
    assign out_lo = in[7:0];
endmodule
