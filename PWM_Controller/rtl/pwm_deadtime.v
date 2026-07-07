`timescale 1ns/1ps
module pwm_deadtime (
    input clk, rst_n, pwm_in,
    input [7:0] rising_dt_cycles, falling_dt_cycles,
    output reg pwm_hs_out, pwm_ls_out
);
    reg pwm_in_d, r_counting, f_counting;
    reg [7:0] R_dt_cyc, F_dt_cyc;
    wire rising_edge  = pwm_in & ~pwm_in_d;
    wire falling_edge = ~pwm_in & pwm_in_d;
    always @(posedge clk or negedge rst_n) begin
        pwm_in_d   <= !rst_n ? 1'b0 : pwm_in;
        R_dt_cyc   <= !rst_n ? 8'd0 : rising_edge ? 8'd0 : (r_counting && R_dt_cyc != rising_dt_cycles - 1) ? R_dt_cyc + 1'b1 : R_dt_cyc;
        F_dt_cyc   <= !rst_n ? 8'd0 : falling_edge ? 8'd0 : (f_counting && F_dt_cyc != falling_dt_cycles - 1) ? F_dt_cyc + 1'b1 : F_dt_cyc;
        r_counting <= !rst_n ? 1'b0 : rising_edge  ? (rising_dt_cycles != 8'd0) : falling_edge ? 1'b0 : (r_counting && R_dt_cyc == rising_dt_cycles - 1) ? 1'b0 : r_counting;
        f_counting <= !rst_n ? 1'b0 : falling_edge ? (falling_dt_cycles != 8'd0) : rising_edge  ? 1'b0 : (f_counting && F_dt_cyc == falling_dt_cycles - 1) ? 1'b0 : f_counting;
        pwm_hs_out <= !rst_n ? 1'b0 : falling_edge ? 1'b0 : rising_edge  ? (rising_dt_cycles == 8'd0) : (r_counting && R_dt_cyc == rising_dt_cycles - 1) ? 1'b1 : pwm_hs_out;
        pwm_ls_out <= !rst_n ? 1'b0 : rising_edge  ? 1'b0 : falling_edge ? (falling_dt_cycles == 8'd0) : (f_counting && F_dt_cyc == falling_dt_cycles - 1) ? 1'b1 : pwm_ls_out;
    end
endmodule
