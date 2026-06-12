// HDLBits Problem 108: Left/right rotator
// Author: Debjit Das | JGEC ECE

module top_module (input clk, load, input [1:0] ena, input [99:0] data, output reg [99:0] q);
    always @(posedge clk) begin
        if (load) q <= data;
        else q <= (ena==2'b01) ? {q[0],q[99:1]} : (ena==2'b10) ? {q[98:0],q[99]} : q;
    end
endmodule
