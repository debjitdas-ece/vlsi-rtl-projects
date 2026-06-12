// HDLBits Problem 171: Counter
// Author: Debjit Das | JGEC ECE

module top_module (input clk, a, output reg [2:0] q);
    always @(posedge clk) begin
        if (a) q <= 3'd4;
        else q <= (q==3'd6) ? 3'd0 : q+1'b1;
    end
endmodule
