// HDLBits Problem 77: K-map implemented with muxes
// Author: Debjit Das | JGEC ECE

module top_module (input a, b, c, d, output out_sop, out_pos);
    assign out_sop = (c & d) | (~a & ~b & c);
    assign out_pos = c & (~a | b) & (~b | d);
endmodule
