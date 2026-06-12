// HDLBits Problem 141: FSM: count ones
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, s, w, output z);
    parameter A=0,B=1,C0=2,C1=3,D0=4,D1=5,D2=6; reg [2:0] state,ns;
    always @(*) case(state)
        A:  ns = s ? B : A;
        B:  ns = w ? C1 : C0;
        C0: ns = w ? D1 : D0;
        C1: ns = w ? D2 : D1;
        D0,D1,D2: ns = B;
        default: ns = A;
    endcase
    always @(posedge clk) if (reset) state<=A; else state<=ns;
    reg z_reg;
    always @(posedge clk) begin
        if (reset) z_reg<=0;
        else z_reg<=((state==D1&&w)||(state==D2&&!w));
    end
    assign z = z_reg;
endmodule
