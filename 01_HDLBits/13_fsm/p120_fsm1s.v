// HDLBits Problem 120: Simple FSM 1 (sync reset)
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, in, output reg out);
    parameter B=0, A=1; reg state;
    always @(posedge clk) begin
        if (reset) {state,out} <= {B,1'b1};
        else case(state)
            B: {state,out} <= in ? {B,1'b1} : {A,1'b0};
            A: {state,out} <= in ? {A,1'b0} : {B,1'b1};
        endcase
    end
endmodule
