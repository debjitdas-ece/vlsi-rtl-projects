// HDLBits Problem 90: DFF + gate
// Author: Debjit Das | JGEC ECE

module top_module (input clk, in, output reg out);
    wire d;
    assign d = out ^ in;
    always @(posedge clk) out <= d;
endmodule
