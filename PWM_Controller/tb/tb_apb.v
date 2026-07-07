`timescale 1ns/1ps
module tb_apb;

localparam P_S = 1;
localparam N = 3;
localparam SAFE = 1'b0;
localparam CLK_T = 10;

reg clk = 0;
reg rst_n;
reg [7:0] paddr;
reg psel, penable, pwrite;
reg [31:0] pwdata;
wire [31:0] prdata;
wire pready, pslverr;
reg sync_in;
wire sync_out;
reg trip_in_ext;
wire [2*N-1:0] pwm_out;
wire adc_trig_a, adc_trig_b;

localparam A_CTRL=8'h00, A_PHASE=8'h04, A_TOP=8'h08;
localparam A_DUTY0=8'h0C, A_DUTY1=8'h10, A_DUTY2=8'h14;
localparam A_POL=8'h18, A_DT=8'h1C, A_TRIP=8'h20;
localparam A_TRIG_CTRL=8'h24, A_TRIG_A=8'h28, A_TRIG_B=8'h2C;
localparam A_STATUS=8'h30, A_LOCK=8'h34;

pwm_apb_wrapper #(.P_S(P_S), .N(N), .SAFE_STATE(SAFE)) u_wrap (
    .clk(clk), .rst_n(rst_n),
    .paddr(paddr), .psel(psel), .penable(penable), .pwrite(pwrite),
    .pwdata(pwdata), .prdata(prdata), .pready(pready), .pslverr(pslverr),
    .sync_in(sync_in), .sync_out(sync_out),
    .trip_in_ext(trip_in_ext),
    .pwm_out(pwm_out),
    .adc_trig_a(adc_trig_a), .adc_trig_b(adc_trig_b)
);

always #(CLK_T/2) clk = ~clk;

integer pass_cnt = 0;
integer fail_cnt = 0;

task automatic chk(input cond, input [8*100-1:0] name);
begin
    if (cond) pass_cnt = pass_cnt + 1;
    else begin
        fail_cnt = fail_cnt + 1;
        $display("FAIL @%0t : %0s", $time, name);
    end
end
endtask

task automatic apb_write(input [7:0] addr, input [31:0] data);
begin
    @(negedge clk); paddr = addr; pwdata = data; pwrite = 1; psel = 1; penable = 0;
    @(negedge clk); penable = 1;
    @(negedge clk); psel = 0; penable = 0; pwrite = 0;
end
endtask

task automatic apb_read(input [7:0] addr, output [31:0] data);
begin
    @(negedge clk); paddr = addr; pwrite = 0; psel = 1; penable = 0;
    @(negedge clk); penable = 1;
    data = prdata;
    @(negedge clk); psel = 0; penable = 0;
end
endtask

reg [31:0] rdata;

task automatic chk_reg(input [7:0] addr, input [31:0] expected, input [8*48-1:0] name);
begin
    apb_read(addr, rdata);
    chk(rdata === expected, name);
end
endtask

wire tick_w = u_wrap.dut.tick;
reg [10:0] ref_cnt;
reg ref_dir;
wire ref_flip_c = (!ref_dir && ref_cnt == u_wrap.dut.top_active) || (ref_dir && ref_cnt == 0);
wire ref_flip_e = (ref_cnt == u_wrap.dut.top_active);
wire mode_sel_w = u_wrap.ctrl_reg[0];
wire sync_en_w  = u_wrap.ctrl_reg[1];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ref_cnt <= 11'd0; ref_dir <= 1'b0;
    end else if (sync_en_w && sync_in) begin
        ref_cnt <= u_wrap.phase_reg; ref_dir <= 1'b0;
    end else if (tick_w) begin
        if (mode_sel_w) begin
            ref_dir <= 1'b0;
            ref_cnt <= (u_wrap.dut.top_active == 0) ? ref_cnt : (ref_flip_e ? 11'd0 : ref_cnt + 1'b1);
        end else begin
            ref_dir <= ref_flip_c ? ~ref_dir : ref_dir;
            ref_cnt <= (u_wrap.dut.top_active == 0) ? ref_cnt :
                       (ref_flip_c ? (ref_dir ? ref_cnt + 1'b1 : ref_cnt - 1'b1)
                                   : (ref_dir ? ref_cnt - 1'b1 : ref_cnt + 1'b1));
        end
    end
end

always @(posedge clk) if (rst_n) begin
    chk(u_wrap.dut.cnt === ref_cnt, "counter: cnt matches ref (via apb path)");
    chk(u_wrap.dut.dir === ref_dir, "counter: dir matches ref (via apb path)");
    chk(u_wrap.dut.z_f === (ref_cnt == 11'd0), "counter: z_f matches ref (via apb path)");
end

reg [10:0] ref_top_shadow, ref_top_active;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin ref_top_shadow <= 0; ref_top_active <= 0; end
    else begin
        ref_top_shadow <= u_wrap.top_id_d ? u_wrap.top_reg : ref_top_shadow;
        ref_top_active <= u_wrap.dut.z_f ? ref_top_shadow : ref_top_active;
    end
end
always @(posedge clk) if (rst_n)
    chk(u_wrap.dut.top_active === ref_top_active, "dbuf: top_active matches ref (apb write path)");

reg [10:0] ref_d_shadow0, ref_d_active0;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin ref_d_shadow0 <= 0; ref_d_active0 <= 0; end
    else begin
        ref_d_shadow0 <= u_wrap.duty_id_d[0] ? u_wrap.duty_reg[0] : ref_d_shadow0;
        ref_d_active0 <= u_wrap.dut.z_f ? ref_d_shadow0 : ref_d_active0;
    end
end
always @(posedge clk) if (rst_n)
    chk(u_wrap.dut.ch[0].duty_active_i === ref_d_active0, "dbuf: ch0 duty_active matches ref (apb write path)");

genvar gi;
generate
    for (gi = 0; gi < N; gi = gi + 1) begin : ovl
        always @(posedge clk) if (rst_n)
            chk(!(pwm_out[2*gi] && pwm_out[2*gi+1]), "no shoot-through on channel (apb wrapper)");
    end
endgenerate



integer pwm_toggle_cnt = 0;
reg [2*N-1:0] pwm_out_d;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) pwm_out_d <= 0;
    else begin
        if (pwm_out != pwm_out_d) pwm_toggle_cnt = pwm_toggle_cnt + 1;
        pwm_out_d <= pwm_out;
    end
end

initial begin
    $dumpfile("tb_apb.vcd");
    $dumpvars(0, tb_apb);
end

task automatic reset_dut;
begin
    rst_n = 0; psel = 0; penable = 0; pwrite = 0; paddr = 0; pwdata = 0;
    sync_in = 0; trip_in_ext = 0;
    repeat (4) @(negedge clk);
    rst_n = 1;
    @(negedge clk);
end
endtask

task automatic wait_z_f;
begin
    @(posedge clk);
    while (!u_wrap.dut.z_f) @(posedge clk);
end
endtask

task automatic test_register_roundtrip;
begin
    $display("---- register writeback/readback ----");
    apb_write(A_CTRL, 32'h3);          chk_reg(A_CTRL, 32'h3, "ctrl readback");
    apb_write(A_PHASE, 32'd7);         chk_reg(A_PHASE, 32'd7, "phase readback");
    apb_write(A_TOP, 32'd40);          chk_reg(A_TOP, 32'd40, "top readback");
    apb_write(A_DUTY0, 32'd12);        chk_reg(A_DUTY0, 32'd12, "duty0 readback");
    apb_write(A_DUTY1, 32'd28);        chk_reg(A_DUTY1, 32'd28, "duty1 readback");
    apb_write(A_DUTY2, 32'd6);         chk_reg(A_DUTY2, 32'd6, "duty2 readback");
    apb_write(A_POL, 32'h2);           chk_reg(A_POL, 32'h2, "polarity readback");
    apb_write(A_DT, 32'h0203);         chk_reg(A_DT, 32'h0203, "deadtime readback");
    apb_write(A_TRIG_CTRL, 32'hA);     chk_reg(A_TRIG_CTRL, 32'hA, "trig_ctrl readback");
    apb_write(A_TRIG_A, 32'd20);       chk_reg(A_TRIG_A, 32'd20, "trig_point_a readback");
    apb_write(A_TRIG_B, 32'd10);       chk_reg(A_TRIG_B, 32'd10, "trig_point_b readback");
    apb_write(A_TRIP, 32'h3);          chk_reg(A_TRIP, 32'h1, "trip_ctrl readback drops clear bit");
    apb_write(A_TRIP, 32'h0);
end
endtask

task automatic test_lock;
    reg [31:0] dt_before, trip_before;
begin
    $display("---- lock enforcement ----");
    apb_read(A_DT, dt_before);
    apb_read(A_TRIP, trip_before);
    apb_write(A_LOCK, 32'h1);
    chk_reg(A_LOCK, 32'h1, "lock readback set");
    apb_write(A_DT, 32'hFFFF);
    chk_reg(A_DT, dt_before, "deadtime write blocked while locked");
    apb_write(A_TRIP, 32'h1);
    chk_reg(A_TRIP, trip_before, "trip_ctrl write blocked while locked");
    apb_write(A_POL, 32'h5);
    chk_reg(A_POL, 32'h5, "non-locked register still writable while locked");
    apb_write(A_LOCK, 32'h0);
    chk_reg(A_LOCK, 32'h0, "lock readback cleared");
    apb_write(A_DT, 32'h0203);
    chk_reg(A_DT, 32'h0203, "deadtime writable again after unlock");
end
endtask

task automatic test_double_buffer_apb;
    reg [10:0] before_val;
begin
    $display("---- double buffer hold check via apb (ch0) ----");
    before_val = u_wrap.dut.ch[0].duty_active_i;
    apb_write(A_DUTY0, before_val + 11'd2);
    chk(u_wrap.dut.ch[0].duty_active_i === before_val, "dbuf: active unchanged right after apb write");
    wait_z_f;
    @(posedge clk);
    chk(u_wrap.dut.ch[0].duty_active_i === (before_val + 11'd2), "dbuf: active updated after next z_f");
end
endtask

task automatic test_trip_soft;
    integer cyc;
begin
    $display("---- trip via apb soft_trip bit (no sync latency) ----");
    apb_write(A_TRIP, 32'h4);
    cyc = 0;
    while (u_wrap.trip_active_w !== 1'b1 && cyc < 10) begin @(posedge clk); cyc = cyc + 1; end
    chk(cyc == 2, "soft_trip: trip_active asserts 2 cycles after write completes");
    apb_read(A_STATUS, rdata);
    chk(rdata[0] === 1'b1, "status: trip_active bit visible after soft trip");
    apb_write(A_TRIP, 32'h0);
    wait_z_f; @(posedge clk); #1;
    chk(u_wrap.trip_active_w === 1'b0, "soft_trip: auto-clears at next z_f once soft_trip bit dropped");
end
endtask

task automatic test_trip_ext;
    integer cyc;
    reg prev;
begin
    $display("---- trip via external pin (2-stage synchronizer) ----");
    apb_write(A_TRIP, 32'h0);
    @(negedge clk); trip_in_ext = 1;
    prev = u_wrap.trip_active_w;
    cyc = 0;
    while (u_wrap.trip_active_w !== 1'b1 && cyc < 10) begin @(posedge clk); cyc = cyc + 1; end
    chk(cyc == 4, "trip_ext: trip_active asserts 4 cycles after pin assert (2-stage sync + dut reg latency)");
    @(negedge clk); trip_in_ext = 0;
    wait_z_f; @(posedge clk); #1;
    chk(u_wrap.trip_active_w === 1'b0, "trip_ext: auto-clears at next z_f");
end
endtask

integer adc_a_fire_cnt = 0;
always @(posedge clk) if (adc_trig_a) adc_a_fire_cnt = adc_a_fire_cnt + 1;

initial begin
    $display("==== pwm_apb_wrapper self-checking testbench ====");
    reset_dut;
    chk(pwm_out === {2*N{SAFE}}, "reset: pwm_out is safe state");
    apb_read(A_STATUS, rdata);
    chk(rdata === 32'd0, "reset: status register all zero");

    test_register_roundtrip;
    test_lock;

    $display("---- run pwm for several periods through apb-configured regs ----");
    repeat (400) @(posedge clk);

    test_double_buffer_apb;

    $display("---- adc trigger check ----");
    apb_write(A_TRIG_CTRL, 32'h1);
    apb_write(A_TRIG_A, u_wrap.top_reg >> 1);
    repeat (2 * 40 * 2) @(posedge clk);
    chk(adc_a_fire_cnt > 0, "adc: trig_a fired at least once via apb config");
    apb_write(A_TRIG_CTRL, 32'h0);
    repeat (4) @(posedge clk);
    chk_reg(A_STATUS, 32'd0, "status: adc bits clear once trig disabled");
    apb_write(A_TRIG_CTRL, 32'h0);

    test_trip_soft;
    test_trip_ext;

    repeat (200) @(posedge clk);

    chk(pwm_toggle_cnt > 50, "sanity: pwm_out toggled many times over the run");

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
