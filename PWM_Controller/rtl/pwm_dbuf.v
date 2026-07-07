`timescale 1ns/1ps
module pwm_dbuf (
    input clk, rst_n, duty_id, top_id, z_f,
    input [10:0] duty_in, top_in,
    output reg [10:0] duty_active, top_active
);
    reg [10:0] duty_shadow, top_shadow;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            duty_shadow <= 11'b0; top_shadow <= 11'b0;
            duty_active <= 11'b0; top_active <= 11'b0;
        end else begin
            duty_shadow <= duty_id ? duty_in : duty_shadow;
            top_shadow  <= top_id  ? top_in  : top_shadow;
            duty_active <= z_f ? duty_shadow : duty_active;
            top_active  <= z_f ? top_shadow  : top_active;
        end
    end
endmodule
