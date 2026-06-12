// HDLBits Problem 96: Detect both edges
// Author: Debjit Das | JGEC ECE

module top_module (input clk, input [7:0] in, output reg [7:0] anyedge);
    reg [7:0] i;
    always @(posedge clk) {anyedge, i} <= {in ^ i, in};
endmodule
