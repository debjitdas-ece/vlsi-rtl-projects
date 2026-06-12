// HDLBits Problem 121: Simple FSM 2 (async reset)
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, j, k, output out);
    parameter OFF=0, ON=1; reg state, next_state;
    always @(*) begin
        case(state)
            OFF: next_state = j ? ON  : OFF;
            ON:  next_state = k ? OFF : ON;
        endcase
    end
    always @(posedge clk or posedge areset)
        if (areset) state <= OFF; else state <= next_state;
    assign out = (state == ON);
endmodule
