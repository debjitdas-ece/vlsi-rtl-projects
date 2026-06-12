// HDLBits Problem 112: 32-bit LFSR
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, output reg [31:0] q);
    always @(posedge clk) begin
        if (reset) q <= 32'h1;
        else q <= {1'b0^q[0], q[31:23], q[22]^q[0], q[21:3], q[2]^q[0], q[1]^q[0]};
    end
endmodule
