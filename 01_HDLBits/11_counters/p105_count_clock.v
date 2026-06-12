// HDLBits Problem 105: 4-digit decimal counter
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, output [3:1] ena, output [15:0] q);
    assign ena = {q[11:8]==4'd9 && q[7:4]==4'd9 && q[3:0]==4'd9,
                  q[7:4]==4'd9 && q[3:0]==4'd9,
                  q[3:0]==4'd9};
    onedigit o1(.clk(clk),.reset(reset),.ena(1'b1),   .q(q[3:0]));
    onedigit o2(.clk(clk),.reset(reset),.ena(ena[1]), .q(q[7:4]));
    onedigit o3(.clk(clk),.reset(reset),.ena(ena[2]), .q(q[11:8]));
    onedigit o4(.clk(clk),.reset(reset),.ena(ena[3]), .q(q[15:12]));
endmodule
module onedigit (input clk, ena, reset, output reg [3:0] q);
    always @(posedge clk) q <= reset ? 4'd0 : ena ? (q==4'd9 ? 4'd0 : q+1'b1) : q;
endmodule
