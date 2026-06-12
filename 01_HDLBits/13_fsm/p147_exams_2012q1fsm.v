// HDLBits Problem 147: 6-state FSM
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, w, output z);
    reg [2:0] s,ns;
    always @(posedge clk) s <= reset ? 3'd0 : ns;
    always @(*) case(s)
        3'd0: ns = w ? 3'd1 : 3'd0;
        3'd1: ns = w ? 3'd2 : 3'd3;
        3'd2: ns = w ? 3'd4 : 3'd3;
        3'd3: ns = w ? 3'd5 : 3'd0;
        3'd4: ns = w ? 3'd4 : 3'd3;
        3'd5: ns = w ? 3'd2 : 3'd3;
        default: ns = 3'd0;
    endcase
    assign z = s[2] & ~s[1];
endmodule
