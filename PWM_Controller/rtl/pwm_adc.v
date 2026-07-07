`timescale 1ns/1ps
module pwm_adc #(
    parameter dir_sel = 1'b0
) (
    input clk, rst_n, trig_en, dir, dir_qual,
    input  [10:0] cnt, trig_point,
    output reg adc_trig
);
    wire match = trig_en && (cnt == trig_point) && (!dir_qual || dir == dir_sel);
    always @(posedge clk or negedge rst_n)
        adc_trig <= !rst_n ? 1'b0 : match;
endmodule
