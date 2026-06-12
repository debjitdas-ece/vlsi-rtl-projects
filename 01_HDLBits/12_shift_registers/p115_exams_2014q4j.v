// HDLBits Problem 115: Serial in parallel out
// Author: Debjit Das | JGEC ECE

module top_module (input clk, enable, S, A, B, C, output Z);
    reg [7:0] q;
    always @(posedge clk) if (enable) q <= {q[6:0], S};
    assign Z = q[{A,B,C}];
endmodule
