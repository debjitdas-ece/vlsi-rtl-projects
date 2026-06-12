// HDLBits Problem 136: Serial receiver with parity
// Author: Debjit Das | JGEC ECE

module top_module (input clk, in, reset,
    output reg [7:0] out_byte, output reg done);
    parameter IDLE=0,START=1,D0=2,D1=3,D2=4,D3=5,D4=6,D5=7,D6=8,D7=9,PARITY=10,STOP=11,ERROR=12;
    reg [3:0] state,ns; reg [7:0] rb; wire odd;
    always @(posedge clk) if(reset) state<=IDLE; else state<=ns;
    always @(*) case(state)
        IDLE:   ns=in?IDLE:START;   START: ns=D0;
        D0:ns=D1;D1:ns=D2;D2:ns=D3;D3:ns=D4;D4:ns=D5;D5:ns=D6;D6:ns=D7;
        D7:     ns=PARITY;
        PARITY: ns=in?STOP:ERROR;
        STOP:   ns=in?IDLE:START;
        ERROR:  ns=in?IDLE:ERROR;
        default:ns=IDLE;
    endcase
    always @(posedge clk) begin
        if (reset) rb<=8'd0;
        else if (ns>=D0 && ns<=D7) rb<={in,rb[7:1]};
    end
    always @(posedge clk) begin
        if (reset) begin done<=0; out_byte<=8'd0; end
        else if (ns==STOP && odd) begin done<=1; out_byte<=rb; end
        else done<=0;
    end
    parity p(.clk(clk),.reset(reset||ns==IDLE||ns==START),.in(in),.odd(odd));
endmodule
