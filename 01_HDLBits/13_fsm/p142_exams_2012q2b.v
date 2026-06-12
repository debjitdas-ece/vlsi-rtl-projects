// HDLBits Problem 142: FSM: 5 states
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, x, output z);
    reg [2:0] s,ns;
    always @(*) case(s)
        3'd0: ns = x ? 3'd1 : 3'd0;
        3'd1: ns = x ? 3'd4 : 3'd1;
        3'd2: ns = x ? 3'd1 : 3'd2;
        3'd3: ns = x ? 3'd2 : 3'd1;
        3'd4: ns = x ? 3'd4 : 3'd3;
        default: ns = 3'd0;
    endcase
    always @(posedge clk) if(reset) s<=3'd0; else s<=ns;
    assign z = (s==3'd3||s==3'd4);
endmodule
