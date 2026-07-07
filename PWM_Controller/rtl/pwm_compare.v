`timescale 1ns/1ps
module pwm_compare (
    input clk, rst_n,
    input [10:0] cnt, duty_val,
    output reg pwm_out
);
    always @(posedge clk or negedge rst_n)
        pwm_out <= (~rst_n) ? 1'b0 : (cnt < duty_val) ? 1'b1 : 1'b0;
endmodule
