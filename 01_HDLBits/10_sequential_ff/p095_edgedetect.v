// HDLBits Problem 95: Detect posedge
// Author: Debjit Das | JGEC ECE

module top_module (input clk, input [7:0] in, output reg [7:0] pedge);
    reg [7:0] i;
    always @(posedge clk) {pedge, i} <= {in & ~i, in};
endmodule
