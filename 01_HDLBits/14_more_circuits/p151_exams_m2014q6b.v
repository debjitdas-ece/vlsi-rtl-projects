// HDLBits Problem 151: Modulo-1000 counter
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, output [9:0] q);
    reg [9:0] r;
    always @(posedge clk)
        r <= reset ? 10'd0 : (r==10'd999) ? 10'd0 : r+1'b1;
    assign q = r;
endmodule
