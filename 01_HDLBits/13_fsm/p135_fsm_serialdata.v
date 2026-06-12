// HDLBits Problem 135: Serial receiver with datapath
// Author: Debjit Das | JGEC ECE

module top_module (input clk, in, reset, output [7:0] out_byte, output done);
    parameter IDLE=0,START=1,D0=2,D1=3,D2=4,D3=5,D4=6,D5=7,D6=8,D7=9,STOP=10,ERROR=11;
    reg [3:0] state,ns; reg [7:0] rb;
    always @(*) case(state)
        IDLE:  ns=~in?START:IDLE; START:ns=D0;
        D0:ns=D1; D1:ns=D2; D2:ns=D3; D3:ns=D4;
        D4:ns=D5; D5:ns=D6; D6:ns=D7;
        D7:  ns=in?STOP:ERROR;
        STOP: ns=~in?START:IDLE;
        ERROR:ns=in?IDLE:ERROR;
        default:ns=IDLE;
    endcase
    always @(posedge clk) begin
        if (reset) begin state<=IDLE; rb<=8'b0; end
        else begin
            state<=ns;
            if (ns>=D0 && ns<=D7) rb<={in,rb[7:1]};
        end
    end
    assign done     = (state==STOP);
    assign out_byte = rb;
endmodule
