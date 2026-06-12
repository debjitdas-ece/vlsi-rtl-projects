// HDLBits Problem 107: 4-bit shift register
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, load, ena, input [3:0] data, output reg [3:0] q);
    always @(posedge clk or posedge areset) begin
        if (areset)    q <= 4'b0;
        else if (load) q <= data;
        else if (ena)  q <= {1'b0, q[3:1]};
    end
endmodule
