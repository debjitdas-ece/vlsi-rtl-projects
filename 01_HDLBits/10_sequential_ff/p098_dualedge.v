// HDLBits Problem 98: Dual-edge triggered FF
// Author: Debjit Das | JGEC ECE

module top_module (input clk, d, output q);
    reg p, n;
    always @(posedge clk) p <= d ^ n;
    always @(negedge clk) n <= d ^ p;
    assign q = p ^ n;
endmodule
