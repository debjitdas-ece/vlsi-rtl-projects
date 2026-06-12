// HDLBits Problem 156: FSM+datapath: full timer
// Author: Debjit Das | JGEC ECE

module top_module (input clk, reset, data, output [3:0] count,
    output counting, done, input ack);
    wire shift_ena, done_counting, tick, count_ena;
    assign tick          = (q_mod==10'd999);
    assign done_counting = counting & tick & (count==4'd0);
    assign count_ena     = counting & tick & (count!=4'd0);
    wire [9:0] q_mod;
    mod1000     u0(.clk(clk),.reset(reset|~counting),.q(q_mod));
    shift_count u1(.clk(clk),.shift_ena(shift_ena),.count_ena(count_ena),.data(data),.q(count));
    fsm_control u2(.clk(clk),.reset(reset),.data(data),.done_counting(done_counting),
                   .ack(ack),.shift_ena(shift_ena),.counting(counting),.done(done));
endmodule
module mod1000 (input clk, reset, output [9:0] q);
    reg [9:0] r;
    always @(posedge clk) r <= reset?10'd0:(r==10'd999?10'd0:r+1'b1);
    assign q = r;
endmodule
module shift_count (input clk, shift_ena, count_ena, data, output reg [3:0] q);
    always @(posedge clk) q <= shift_ena?{q[2:0],data}:count_ena?(q-1'b1):q;
endmodule
module fsm_control (input clk, reset, data, done_counting, ack,
    output shift_ena, counting, done);
    localparam S=0,S1=1,S11=2,S110=3,B0=4,B1=5,B2=6,B3=7,COUNT=8,WAIT=9;
    reg [3:0] s,ns;
    always @(posedge clk) s<=reset?S:ns;
    always @(*) case(s)
        S:ns=data?S1:S; S1:ns=data?S11:S; S11:ns=data?S11:S110;
        S110:ns=data?B0:S; B0:ns=B1; B1:ns=B2; B2:ns=B3; B3:ns=COUNT;
        COUNT:ns=done_counting?WAIT:COUNT; WAIT:ns=ack?S:WAIT; default:ns=S;
    endcase
    assign shift_ena=(s==B0)|(s==B1)|(s==B2)|(s==B3);
    assign counting=(s==COUNT); assign done=(s==WAIT);
endmodule
