// HDLBits Problem 93: 3 DFFs
// Author: Debjit Das | JGEC ECE

module top_module (input clk, x, output z);
    reg [2:0] q;
    always @(posedge clk) q <= {x|~q[2], x&~q[1], x^q[0]};
    assign z = ~|q;
endmodule
