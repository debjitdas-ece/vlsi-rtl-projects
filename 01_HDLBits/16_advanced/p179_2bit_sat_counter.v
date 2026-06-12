// HDLBits Problem 179: 2-bit saturating counter
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, train_valid, train_taken, output reg [1:0] state);
    always @(posedge clk or posedge areset) begin
        if (areset) state <= 2'b01;
        else if (train_valid) begin
            if (train_taken && state < 2'b11) state <= state+1'b1;
            else if (!train_taken && state > 2'b00) state <= state-1'b1;
        end
    end
endmodule
