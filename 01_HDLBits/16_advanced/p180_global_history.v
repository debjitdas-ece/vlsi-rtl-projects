// HDLBits Problem 180: Global history shift register
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, predict_valid, predict_taken,
    output reg [31:0] predict_history,
    input train_mispredicted, train_taken, input [31:0] train_history);
    always @(posedge clk or posedge areset) begin
        if (areset) predict_history <= 32'b0;
        else if (train_mispredicted) predict_history <= {train_history[30:0],train_taken};
        else if (predict_valid)      predict_history <= {predict_history[30:0],predict_taken};
    end
endmodule
