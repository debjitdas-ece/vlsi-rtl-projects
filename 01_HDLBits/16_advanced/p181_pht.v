// HDLBits Problem 181: Branch predictor with PHT
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset,
    input predict_valid, input [6:0] predict_pc, output predict_taken,
    output [6:0] predict_history,
    input train_valid, train_taken, train_mispredicted,
    input [6:0] train_history, train_pc);
    reg [1:0] pht[127:0]; reg [6:0] ghr; integer i;
    wire [6:0] pi = predict_pc ^ ghr;
    wire [6:0] ti = train_pc ^ train_history;
    assign predict_history = ghr;
    assign predict_taken   = pht[pi][1];
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            ghr<=7'b0;
            for(i=0;i<128;i=i+1) pht[i]<=2'b01;
        end else begin
            if (train_valid && train_mispredicted) ghr<={train_history[5:0],train_taken};
            else if (predict_valid) ghr<={ghr[5:0],predict_taken};
            if (train_valid) begin
                if (train_taken && pht[ti]<2'b11) pht[ti]<=pht[ti]+1'b1;
                else if (!train_taken && pht[ti]>2'b00) pht[ti]<=pht[ti]-1'b1;
            end
        end
    end
endmodule
