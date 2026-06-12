// HDLBits Problem 172: Mealy FSM
// Author: Debjit Das | JGEC ECE

module top_module (input clk, a, b, output q, output reg state);
    always @(posedge clk) begin
        if (a && b) state <= 1'b1;
        else if (!a && !b) state <= 1'b0;
    end
    assign q = a ^ b ^ state;
endmodule
