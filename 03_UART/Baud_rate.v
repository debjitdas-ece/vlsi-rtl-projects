`timescale 1ns/1ps
module baud_gen #(parameter CLK_F=50_000_000, BAUD_R=115_200, O=16)(
    input wire clk, rst, output wire rx_tick, output reg tx_tick
);
    localparam T_C=(CLK_F/BAUD_R)/O, C_RW=$clog2(T_C), C_TW=$clog2(O);
    reg [C_RW-1:0] c; reg [C_TW-1:0] t;
    wire rx_tick_w = (c==T_C-1);
    always @(posedge clk or posedge rst) begin
        if (rst) {c,t,tx_tick} <= 0;
        else if (rx_tick_w) begin c<=0; t<=t+1'b1; tx_tick<=(t==O-1); end
        else begin c<=c+1'b1; tx_tick<=1'b0; end
    end
    assign rx_tick = rx_tick_w;
endmodule
