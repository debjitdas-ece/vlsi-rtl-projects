// HDLBits Problem 97: Edge capture register
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, input [31:0] in, output reg [31:0] out);
    reg [31:0] i;
    always @(posedge clk) begin
        out <= reset ? 32'd0 : (out | (~in & i));
        i   <= in;
    end
endmodule
