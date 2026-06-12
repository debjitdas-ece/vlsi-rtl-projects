// HDLBits Problem 65: 256-to-1 4-bit mux
// Author: Debjit Das | JGEC ECE

module top_module (input [1023:0] in, input [7:0] sel, output [3:0] out);
    assign out = in[sel*4 +: 4];
endmodule
