`timescale 1ns/1ns
module alu (
    input clk, rst,
    input [7:0] a, b,
    input [4:0] op,
    output[7:0] res,
    output reg z, c, o, n, p
);
 parameter add = 5'd0, sub = 5'd1, inc = 5'd2, dec = 5'd3, neg = 5'd4,
           AND = 5'd5, OR = 5'd6, XOR = 5'd7, NOT = 5'd8, 
           LSL = 5'd9, LSR = 5'd10, ASL = 5'd11, ASR = 5'd12, 
           RL = 5'd13, RR = 5'd14, RLC = 5'd15, RRC = 5'd16,
           equal = 5'd17, GT = 5'd18, LT = 5'd19;
reg carry, overflow, c_reg;
reg [7:0] result;        
 always @(*) begin
    {carry, overflow, result} = 10'd0;
    case (op)
       add  : begin                                       
             {carry,result} = a + b;
              overflow = (a[7]==b[7]) & (result[7]!=a[7]);
        end
        sub  : begin                                       
             {carry,result} = a - b;
              overflow = (a[7]!=b[7]) & (result[7]!=a[7]);
                   end
       inc : {carry, result} = a + 8'd1;
       dec : {carry, result} = a - 8'd1;
       neg :  result = (~a) + 8'd1;
       AND :  result = a & b;
       OR :   result = a | b;
       XOR :  result = a ^ b;
       NOT :  result = ~a;
       LSL :  {carry, result} = {a, 1'b0};
       LSR :  {result, carry} = {1'b0, a};
       ASL :  {carry, result} = {a, 1'b0};
       ASR :  {result, carry} = {a[7], a};
       RL :    result = {a[6:0], a[7]};
       RR :    result = {a[0], a[7:1]};
       RLC :  {carry, result} = {a, c_reg};
       RRC :  {result, carry} = {c_reg, a};
       equal : result = {7'd0, (a == b)};
       GT :    result = {7'd0, (a > b)};
       LT :    result = {7'd0, (a < b)};
        default: result = 8'd0;
    endcase
 end
 always @(posedge clk or posedge rst) begin
    if (rst) {z, c, o, n, p} <= 5'd0;
    else {z, c, o, n, p, c_reg} <= {(result == 8'd0), carry, overflow, result[7], (~^result), carry};
 end
 assign res = result;
endmodule