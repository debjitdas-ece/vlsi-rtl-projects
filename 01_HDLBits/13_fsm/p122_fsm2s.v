// HDLBits Problem 122: Simple FSM 2 (sync reset)
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, j, k, output reg out);
    parameter OFF=0, ON=1; reg state;
    always @(posedge clk) begin
        if (reset) {state,out} <= {OFF,1'b0};
        else case(state)
            OFF: {state,out} <= j ? {ON,1'b1}  : {OFF,1'b0};
            ON:  {state,out} <= k ? {OFF,1'b0} : {ON,1'b1};
        endcase
    end
endmodule
