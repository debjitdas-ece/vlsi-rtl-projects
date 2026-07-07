`timescale 1ns/1ps
module tb_pwm_top;

localparam N = 3;
localparam P_S = 1;
localparam SAFE = 1'b0;
localparam CLK_T = 10;

reg clk = 0;
reg rst_n, mode_sel, sync_in, sync_en;
wire sync_out;
reg [10:0] phase_offset, top_val;
reg top_id;
reg [N*11-1:0] duty_in;
reg [N-1:0] duty_id, polarity;
reg [7:0] rising_dt_cycles, falling_dt_cycles;
reg trip_in, trip_mode, trip_clear;
wire trip_active;
reg trig_en_a, trig_en_b, dir_qual_a, dir_qual_b;
reg [10:0] trig_point_a, trig_point_b;
wire adc_trig_a, adc_trig_b;
wire [2*N-1:0] pwm_out;

pwm_top #(.P_S(P_S), .N(N), .SAFE_STATE(SAFE)) u_dut (
    .clk(clk), .rst_n(rst_n), .mode_sel(mode_sel),
    .sync_in(sync_in), .sync_en(sync_en), .sync_out(sync_out),
    .phase_offset(phase_offset), .top_val(top_val), .top_id(top_id),
    .duty_in(duty_in), .duty_id(duty_id), .polarity(polarity),
    .rising_dt_cycles(rising_dt_cycles), .falling_dt_cycles(falling_dt_cycles),
    .trip_in(trip_in), .trip_mode(trip_mode), .trip_clear(trip_clear), .trip_active(trip_active),
    .trig_en_a(trig_en_a), .trig_en_b(trig_en_b), .dir_qual_a(dir_qual_a), .dir_qual_b(dir_qual_b),
    .trig_point_a(trig_point_a), .trig_point_b(trig_point_b),
    .adc_trig_a(adc_trig_a), .adc_trig_b(adc_trig_b),
    .pwm_out(pwm_out)
);

always #(CLK_T/2) clk = ~clk;

integer pass_cnt = 0;
integer fail_cnt = 0;

task automatic chk(input cond, input [8*64-1:0] name);
begin
    if (cond) pass_cnt = pass_cnt + 1;
    else begin
        fail_cnt = fail_cnt + 1;
        $display("FAIL @%0t : %0s", $time, name);
    end
end
endtask

wire tick_w = u_dut.tick;

reg [10:0] ref_cnt;
reg ref_dir;
wire ref_flip_c = (!ref_dir && ref_cnt == u_dut.top_active) || (ref_dir && ref_cnt == 0);
wire ref_flip_e = (ref_cnt == u_dut.top_active);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ref_cnt <= 11'd0; ref_dir <= 1'b0;
    end else if (sync_en && sync_in) begin
        ref_cnt <= phase_offset; ref_dir <= 1'b0;
    end else if (tick_w) begin
        if (mode_sel) begin
            ref_dir <= 1'b0;
            ref_cnt <= (u_dut.top_active == 0) ? ref_cnt : (ref_flip_e ? 11'd0 : ref_cnt + 1'b1);
        end else begin
            ref_dir <= ref_flip_c ? ~ref_dir : ref_dir;
            ref_cnt <= (u_dut.top_active == 0) ? ref_cnt :
                       (ref_flip_c ? (ref_dir ? ref_cnt + 1'b1 : ref_cnt - 1'b1)
                                   : (ref_dir ? ref_cnt - 1'b1 : ref_cnt + 1'b1));
        end
    end
end

always @(posedge clk) if (rst_n) begin
    chk(u_dut.cnt === ref_cnt, "counter: cnt matches ref model");
    chk(u_dut.dir === ref_dir, "counter: dir matches ref model");
    chk(u_dut.z_f === (ref_cnt == 11'd0), "counter: z_f matches ref model");
end

reg [10:0] ref_top_shadow, ref_top_active;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin ref_top_shadow <= 0; ref_top_active <= 0; end
    else begin
        ref_top_shadow <= top_id ? top_val : ref_top_shadow;
        ref_top_active <= u_dut.z_f ? ref_top_shadow : ref_top_active;
    end
end

reg [10:0] ref_d_shadow [0:N-1];
reg [10:0] ref_d_active [0:N-1];
genvar gi;
generate
    for (gi = 0; gi < N; gi = gi + 1) begin : refbuf
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin ref_d_shadow[gi] <= 0; ref_d_active[gi] <= 0; end
            else begin
                ref_d_shadow[gi] <= duty_id[gi] ? duty_in[gi*11 +: 11] : ref_d_shadow[gi];
                ref_d_active[gi] <= u_dut.z_f ? ref_d_shadow[gi] : ref_d_active[gi];
            end
        end
    end
endgenerate

always @(posedge clk) if (rst_n) begin
    chk(u_dut.top_active === ref_top_active, "dbuf: top_active matches ref (double buffer)");
    chk(u_dut.ch[0].duty_active_i === ref_d_active[0], "dbuf: ch0 duty_active matches ref");
    chk(u_dut.ch[1].duty_active_i === ref_d_active[1], "dbuf: ch1 duty_active matches ref");
    chk(u_dut.ch[2].duty_active_i === ref_d_active[2], "dbuf: ch2 duty_active matches ref");
end

reg [10:0] cnt_q, dact0_q, dact1_q, dact2_q;
reg primed;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) primed <= 1'b0;
    else primed <= 1'b1;
end
always @(posedge clk) begin
    cnt_q <= u_dut.cnt;
    dact0_q <= u_dut.ch[0].duty_active_i;
    dact1_q <= u_dut.ch[1].duty_active_i;
    dact2_q <= u_dut.ch[2].duty_active_i;
end

always @(posedge clk) if (rst_n && primed) begin
    chk(u_dut.ch[0].cmp_out_i === (cnt_q < dact0_q), "compare: ch0 matches cnt<duty");
    chk(u_dut.ch[1].cmp_out_i === (cnt_q < dact1_q), "compare: ch1 matches cnt<duty");
    chk(u_dut.ch[2].cmp_out_i === (cnt_q < dact2_q), "compare: ch2 matches cnt<duty");
    chk(u_dut.ch[0].pol_out_i === (u_dut.ch[0].cmp_out_i ^ polarity[0]), "polarity: ch0 xor correct");
    chk(u_dut.ch[1].pol_out_i === (u_dut.ch[1].cmp_out_i ^ polarity[1]), "polarity: ch1 xor correct");
    chk(u_dut.ch[2].pol_out_i === (u_dut.ch[2].cmp_out_i ^ polarity[2]), "polarity: ch2 xor correct");
end

reg ref_pin_d, ref_rcnt_en, ref_fcnt_en, ref_hs, ref_ls;
reg [7:0] ref_R, ref_F;
wire pol0 = u_dut.ch[0].pol_out_i;
wire rise0 = pol0 & ~ref_pin_d;
wire fall0 = ~pol0 & ref_pin_d;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ref_pin_d <= 0; ref_rcnt_en <= 0; ref_fcnt_en <= 0;
        ref_R <= 0; ref_F <= 0; ref_hs <= 0; ref_ls <= 0;
    end else begin
        ref_pin_d <= pol0;
        ref_R <= rise0 ? 8'd0 : (ref_rcnt_en && ref_R != rising_dt_cycles-1) ? ref_R+1'b1 : ref_R;
        ref_F <= fall0 ? 8'd0 : (ref_fcnt_en && ref_F != falling_dt_cycles-1) ? ref_F+1'b1 : ref_F;
        ref_rcnt_en <= rise0 ? (rising_dt_cycles != 0) : fall0 ? 1'b0 : (ref_rcnt_en && ref_R == rising_dt_cycles-1) ? 1'b0 : ref_rcnt_en;
        ref_fcnt_en <= fall0 ? (falling_dt_cycles != 0) : rise0 ? 1'b0 : (ref_fcnt_en && ref_F == falling_dt_cycles-1) ? 1'b0 : ref_fcnt_en;
        ref_hs <= fall0 ? 1'b0 : rise0 ? (rising_dt_cycles == 0) : (ref_rcnt_en && ref_R == rising_dt_cycles-1) ? 1'b1 : ref_hs;
        ref_ls <= rise0 ? 1'b0 : fall0 ? (falling_dt_cycles == 0) : (ref_fcnt_en && ref_F == falling_dt_cycles-1) ? 1'b1 : ref_ls;
    end
end
always @(posedge clk) if (rst_n) begin
    chk(u_dut.ch[0].dt_hs_i === ref_hs, "deadtime: ch0 hs matches ref model");
    chk(u_dut.ch[0].dt_ls_i === ref_ls, "deadtime: ch0 ls matches ref model");
end

generate
    for (gi = 0; gi < N; gi = gi + 1) begin : ovl
        always @(posedge clk) if (rst_n)
            chk(!(pwm_out[2*gi] && pwm_out[2*gi+1]), "no shoot-through on channel");
    end
endgenerate

reg ref_adc_a, ref_adc_b;
wire match_a = trig_en_a && (u_dut.cnt == trig_point_a) && (!dir_qual_a || u_dut.dir == 1'b0);
wire match_b = trig_en_b && (u_dut.cnt == trig_point_b) && (!dir_qual_b || u_dut.dir == 1'b0);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin ref_adc_a <= 0; ref_adc_b <= 0; end
    else begin ref_adc_a <= match_a; ref_adc_b <= match_b; end
end
always @(posedge clk) if (rst_n) begin
    chk(adc_trig_a === ref_adc_a, "adc: trig_a matches ref model");
    chk(adc_trig_b === ref_adc_b, "adc: trig_b matches ref model");
end

integer pwm_toggle_cnt = 0, trip_fire_cnt = 0, adc_a_fire_cnt = 0, dt_hs_toggle_cnt = 0, sync_out_cnt = 0;
always @(posedge clk) if (rst_n && sync_out) sync_out_cnt = sync_out_cnt + 1;
reg [2*N-1:0] pwm_out_d;
reg trip_active_d, dt_hs0_d;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pwm_out_d <= 0; trip_active_d <= 0; dt_hs0_d <= 0;
    end else begin
        if (pwm_out != pwm_out_d) pwm_toggle_cnt = pwm_toggle_cnt + 1;
        if (trip_active && !trip_active_d) trip_fire_cnt = trip_fire_cnt + 1;
        if (adc_trig_a) adc_a_fire_cnt = adc_a_fire_cnt + 1;
        if (u_dut.ch[0].dt_hs_i != dt_hs0_d) dt_hs_toggle_cnt = dt_hs_toggle_cnt + 1;
        pwm_out_d <= pwm_out; trip_active_d <= trip_active; dt_hs0_d <= u_dut.ch[0].dt_hs_i;
    end
end

initial begin
    $dumpfile("tb_pwm_top.vcd");
    $dumpvars(0, tb_pwm_top);
end

task automatic reset_dut;
begin
    rst_n = 0; mode_sel = 0; sync_in = 0; sync_en = 0;
    phase_offset = 0; top_val = 0; top_id = 0;
    duty_in = 0; duty_id = 0; polarity = 0;
    rising_dt_cycles = 0; falling_dt_cycles = 0;
    trip_in = 0; trip_mode = 0; trip_clear = 0;
    trig_en_a = 0; trig_en_b = 0; dir_qual_a = 0; dir_qual_b = 0;
    trig_point_a = 0; trig_point_b = 0;
    repeat (4) @(negedge clk);
    rst_n = 1;
    @(negedge clk);
end
endtask

task automatic load_top(input [10:0] val);
begin
    @(negedge clk); top_val = val; top_id = 1;
    @(negedge clk); top_id = 0;
end
endtask

task automatic load_duty(input integer ch, input [10:0] val);
begin
    @(negedge clk);
    duty_in[ch*11 +: 11] = val;
    duty_id[ch] = 1'b1;
    @(negedge clk);
    duty_id[ch] = 1'b0;
end
endtask

task automatic wait_z_f;
begin
    @(posedge clk);
    while (!u_dut.z_f) @(posedge clk);
end
endtask

task automatic test_double_buffer;
    reg [10:0] before_val;
begin
    $display("---- double buffer hold check (ch0) ----");
    before_val = u_dut.ch[0].duty_active_i;
    load_duty(0, before_val + 11'd2);
    chk(u_dut.ch[0].duty_active_i === before_val, "dbuf: active unchanged right after id pulse");
    repeat (3) begin
        @(posedge clk);
        if (!u_dut.z_f) chk(u_dut.ch[0].duty_active_i === before_val, "dbuf: active still held pre z_f");
    end
    wait_z_f;
    @(posedge clk);
    chk(u_dut.ch[0].duty_active_i === (before_val + 11'd2), "dbuf: active updated after z_f");
end
endtask

task automatic test_deadtime_timing;
    reg pol0_prev;
    integer cyc_to_ls0, cyc_to_hs1, exp_delay;
    reg found_edge;
begin
    $display("---- deadtime independent timing check (ch0) ----");
    load_duty(0, 11'd0);
    wait_z_f; wait_z_f;
    load_duty(0, 11'd200);
    pol0_prev = pol0;
    found_edge = 1'b0;
    while (!found_edge) begin
        @(posedge clk); #1;
        if (pol0 && !pol0_prev) found_edge = 1'b1;
        pol0_prev = pol0;
    end
    cyc_to_ls0 = 0;
    while (u_dut.ch[0].dt_ls_i !== 1'b0 && cyc_to_ls0 < 20) begin
        @(posedge clk); #1; cyc_to_ls0 = cyc_to_ls0 + 1;
    end
    chk(cyc_to_ls0 <= 1, "deadtime: ls drops within 1 cycle of edge");
    cyc_to_hs1 = 0;
    while (u_dut.ch[0].dt_hs_i !== 1'b1 && cyc_to_hs1 < 20) begin
        @(posedge clk); #1; cyc_to_hs1 = cyc_to_hs1 + 1;
    end
    exp_delay = {24'd0, rising_dt_cycles};
    chk(cyc_to_hs1 == exp_delay, "deadtime: hs asserted rising_dt_cycles after edge");
end
endtask

task automatic test_trip;
begin
    $display("---- trip: auto-clear mode ----");
    trip_mode = 0;
    @(negedge clk); trip_in = 1;
    @(posedge clk); #1;
    chk(trip_active === 1'b1, "trip: trip_active asserts on trip_in");
    chk(pwm_out === {2*N{SAFE}}, "trip: pwm_out forced to safe state");
    @(negedge clk); trip_in = 0;
    wait_z_f; @(posedge clk); #1;
    chk(trip_active === 1'b0, "trip: auto-clears at next z_f after trip_in low");

    $display("---- trip: latched mode ----");
    trip_mode = 1;
    @(negedge clk); trip_in = 1;
    @(posedge clk); #1;
    chk(trip_active === 1'b1, "trip: latched trip_active asserts");
    @(negedge clk); trip_in = 0;
    wait_z_f; wait_z_f; @(posedge clk); #1;
    chk(trip_active === 1'b1, "trip: stays latched across z_f without clear");
    @(negedge clk); trip_clear = 1;
    @(negedge clk); trip_clear = 0;
    @(posedge clk); #1;
    chk(trip_active === 1'b0, "trip: trip_clear releases latched trip");
    trip_mode = 0;
end
endtask

task automatic test_adc_trigger;
begin
    $display("---- adc trigger dir-qualified check ----");
    trig_en_a = 1; dir_qual_a = 1; trig_point_a = top_val >> 1;
    repeat (2*top_val*2) @(posedge clk);
    chk(adc_a_fire_cnt > 0, "adc: trig_a fired at least once with dir qualifier on");
    trig_en_a = 0; dir_qual_a = 0;
end
endtask

initial begin
    $display("==== pwm_top self-checking testbench ====");
    reset_dut;
    chk(pwm_out === {2*N{SAFE}}, "reset: pwm_out is safe state");
    chk(trip_active === 1'b0, "reset: trip_active low");
    chk(adc_trig_a === 1'b0 && adc_trig_b === 1'b0, "reset: adc outputs low");

    $display("---- center-aligned baseline run ----");
    mode_sel = 0;
    load_top(11'd40);
    load_duty(0, 11'd12);
    load_duty(1, 11'd28);
    load_duty(2, 11'd6);
    polarity = 3'b010;
    rising_dt_cycles = 8'd3;
    falling_dt_cycles = 8'd2;
    repeat (400) @(posedge clk);

    test_double_buffer;
    test_deadtime_timing;

    $display("---- edge-aligned mode run ----");
    mode_sel = 1;
    repeat (300) @(posedge clk);
    chk(u_dut.dir === 1'b0, "edge-aligned: dir stays 0");
    mode_sel = 0;

    $display("---- sync/phase-offset load check ----");
    phase_offset = 11'd7;
    sync_en = 1;
    @(negedge clk); sync_in = 1;
    @(negedge clk); sync_in = 0;
    repeat (100) @(posedge clk);
    sync_en = 0;

    test_adc_trigger;
    test_trip;

    repeat (200) @(posedge clk);

    chk(pwm_toggle_cnt > 50, "sanity: pwm_out toggled many times over the run");
    chk(trip_fire_cnt > 0, "sanity: trip_active fired during trip tests");
    chk(dt_hs_toggle_cnt > 0, "sanity: deadtime hs output toggled");
    chk(sync_out_cnt > 0, "sanity: sync_out pulsed at least once");

    $display("==============================================");
    $display("PASS = %0d  FAIL = %0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("RESULT: ALL CHECKS PASSED");
    else $display("RESULT: %0d CHECK(S) FAILED", fail_cnt);
    $display("==============================================");
    $finish;
end

initial begin
    #2_000_000;
    $display("TIMEOUT - simulation did not finish");
    $finish;
end

endmodule
