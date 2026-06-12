// HDLBits Problem 154: 4-cycle shift enable
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, output shift_ena);
    reg [2:0] count;
    always @(posedge clk) begin
        if (reset) count <= 3'd4;
        else if (count > 0) count <= count - 1'b1;
    end
    assign shift_ena = (count > 0);
endmodule
