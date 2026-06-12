// HDLBits Problem 113: Shift register
// Author: Debjit Das | JGEC ECE

module top_module (input clk, resetn, in, output reg out);
    reg [3:0] sr;
    always @(posedge clk) begin
        if (~resetn) sr <= 4'b0; else sr <= {sr[2:0], in};
    end
    assign out = sr[3];
endmodule
