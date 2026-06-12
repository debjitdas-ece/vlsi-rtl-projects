// HDLBits Problem 127: Lemmings 1
// Author: Debjit Das | JGEC ECE

module top_module (input clk, areset, bump_left, bump_right,
    output walk_left, walk_right);
    parameter L=0, R=1; reg state;
    always @(posedge clk or posedge areset) begin
        if (areset) state <= L;
        else case(state)
            L: state <= bump_left  ? R : L;
            R: state <= bump_right ? L : R;
        endcase
    end
    assign {walk_left, walk_right} = {~state, state};
endmodule
