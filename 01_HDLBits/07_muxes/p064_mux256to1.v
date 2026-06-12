// HDLBits Problem 64: 256-to-1 mux
// Author: Debjit Das | JGEC ECE

module top_module (input [255:0] in, input [7:0] sel, output out);
    assign out = in[sel];
endmodule
