// HDLBits Problem 178: Count-down timer
// Author: Debjit Das | JGEC ECE

module top_module (input clk, load, input [9:0] data, output tc);
    reg [9:0] counter;
    always @(posedge clk) begin
        if (load) counter <= data;
        else if (counter > 0) counter <= counter - 1'b1;
    end
    assign tc = (counter == 10'd0);
endmodule
