`timescale 1ns/1ps
module pwm_top #(
    parameter integer P_S = 2,
    parameter integer N   = 3,
    parameter SAFE_STATE  = 1'b0
) (
    input  clk, rst_n, mode_sel,
    input  sync_in, sync_en,
    output sync_out,
    input  [10:0] phase_offset, top_val,
    input  top_id,
    input  [N*11-1:0] duty_in,
    input  [N-1:0] duty_id, polarity,
    input  [7:0] rising_dt_cycles, falling_dt_cycles,
    input  trip_in, trip_mode, trip_clear,
    output trip_active,
    input  trig_en_a, trig_en_b, dir_qual_a, dir_qual_b,
    input  [10:0] trig_point_a, trig_point_b,
    output adc_trig_a, adc_trig_b,
    output [2*N-1:0] pwm_out
);
    wire [10:0] cnt, top_active;
    wire tick, dir, z_f;
    wire z_f_pulse = z_f & tick;
    assign sync_out = z_f_pulse;

    pwm_prescaler #(.PRESCALER(P_S)) p_s_inst (.clk(clk), .rst_n(rst_n), .tick(tick));

    pwm_updown_counter updown_cnt_inst (
        .clk(clk), .rst_n(rst_n), .tick(tick), .mode_sel(mode_sel),
        .top_val(top_active), .cnt(cnt), .dir(dir), .z_f(z_f),
        .sync_in(sync_in), .sync_en(sync_en), .phase_offset(phase_offset)
    );

    pwm_dbuf top_dbuf_inst (
        .clk(clk), .rst_n(rst_n), .duty_id(1'b0), .top_id(top_id), .z_f(z_f),
        .duty_in(11'b0), .top_in(top_val), .duty_active(), .top_active(top_active)
    );

    pwm_adc #(.dir_sel(1'b0)) adctrig_a_inst (
        .clk(clk), .rst_n(rst_n), .trig_en(trig_en_a), .dir(dir), .dir_qual(dir_qual_a),
        .cnt(cnt), .trig_point(trig_point_a), .adc_trig(adc_trig_a)
    );

    pwm_adc #(.dir_sel(1'b0)) adctrig_b_inst (
        .clk(clk), .rst_n(rst_n), .trig_en(trig_en_b), .dir(dir), .dir_qual(dir_qual_b),
        .cnt(cnt), .trig_point(trig_point_b), .adc_trig(adc_trig_b)
    );

    wire [2*N-1:0] pre_trip;
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : ch
            wire [10:0] duty_active_i;
            wire cmp_out_i, pol_out_i, dt_hs_i, dt_ls_i;

            pwm_dbuf dbuf_inst (
                .clk(clk), .rst_n(rst_n), .duty_id(duty_id[i]), .top_id(1'b0), .z_f(z_f),
                .duty_in(duty_in[i*11 +: 11]), .top_in(11'b0), .duty_active(duty_active_i), .top_active()
            );
            pwm_compare cmp_inst (.clk(clk), .rst_n(rst_n), .cnt(cnt), .duty_val(duty_active_i), .pwm_out(cmp_out_i));
            assign pol_out_i = cmp_out_i ^ polarity[i];
            pwm_deadtime deadtime_inst (
                .clk(clk), .rst_n(rst_n), .pwm_in(pol_out_i),
                .rising_dt_cycles(rising_dt_cycles), .falling_dt_cycles(falling_dt_cycles),
                .pwm_hs_out(dt_hs_i), .pwm_ls_out(dt_ls_i)
            );
            assign pre_trip[2*i]   = dt_hs_i;
            assign pre_trip[2*i+1] = dt_ls_i;
        end
    endgenerate

    pwm_trip #(.N(2*N), .SAFE_STATE(SAFE_STATE)) trip_inst (
        .clk(clk), .rst_n(rst_n), .t_i(trip_in), .t_m(trip_mode), .t_c(trip_clear), .z_f(z_f),
        .pwm_in(pre_trip), .pwm_out(pwm_out), .trip_active(trip_active)
    );
endmodule
