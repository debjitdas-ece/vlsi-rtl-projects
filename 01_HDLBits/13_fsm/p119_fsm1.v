// HDLBits Problem 119: Simple FSM 1 (async reset)
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, in, output out);
    parameter B=0, A=1; reg state, next_state;
    always @(*) begin
        case(state)
            B: next_state = in ? B : A;
            A: next_state = in ? A : B;
        endcase
    end
    always @(posedge clk or posedge areset)
        if (areset) state <= B; else state <= next_state;
    assign out = (state == B);
endmodule
