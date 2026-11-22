`timescale 1ps/1ps
// BUG GALLERY
//  #1 multi-bit bus through a plain 2FF  -> destination sees values that never existed
//     fix: Gray-code the bus (if it counts by 1), or use handshake_sync
//  #2 1-cycle pulse from fast to slow clock through a plain 2FF -> pulses lost
//     fix: pulse_sync (toggle + edge detect)
module tb_cdc_bugs;
    reg sclk = 0, dclk = 0, srst_n = 0, drst_n = 0;
    always #5000  sclk = ~sclk;      // 100 MHz
    always #11500 dclk = ~dclk;      // ~43 MHz
    initial begin #30000 srst_n = 1; drst_n = 1; end

    // ---------- bug #1 : bus crossing ----------
    reg [7:0] cnt;
    always @(posedge sclk or negedge srst_n) if (!srst_n) cnt <= 0; else cnt <= cnt + 1;
    wire [7:0] gray = cnt ^ (cnt >> 1);

    wire [7:0] bad_q, gray_q;
    sync_2ff #(.W(8), .SKEW(1000)) u_bad  (.clk(dclk), .rst_n(drst_n), .d(cnt),  .q(bad_q));
    sync_2ff #(.W(8), .SKEW(1000)) u_good (.clk(dclk), .rst_n(drst_n), .d(gray), .q(gray_q));

    function [7:0] g2b(input [7:0] g);
        integer k; begin g2b[7] = g[7]; for (k = 6; k >= 0; k = k - 1) g2b[k] = g2b[k+1] ^ g[k]; end
    endfunction
    wire [7:0] good_q = g2b(gray_q);

    reg [7:0] bad_prev = 0, good_prev = 0;
    integer bad_jumps = 0, good_jumps = 0, n1 = 0;
    always @(posedge dclk) if (drst_n) begin
        n1 = n1 + 1;
        if (n1 > 4) begin          // skip start-up
            if (((bad_q  - bad_prev ) & 8'hFF) > 8) bad_jumps  = bad_jumps  + 1;
            if (((good_q - good_prev) & 8'hFF) > 8) good_jumps = good_jumps + 1;
        end
        bad_prev = bad_q; good_prev = good_q;
    end

    // ---------- bug #2 : lost pulses ----------
    reg [3:0] div = 0; reg pulse = 0;
    always @(posedge sclk) begin div <= (div == 11) ? 0 : div + 1; pulse <= (div == 0); end

    wire naive_q;  reg naive_d = 0;
    sync_2ff #(.W(1)) u_naive (.clk(dclk), .rst_n(drst_n), .d(pulse), .q(naive_q));
    always @(posedge dclk) naive_d <= naive_q;
    wire pulse_ok;
    pulse_sync u_ps (.src_clk(sclk), .src_rst_n(srst_n), .pulse_in(pulse),
                     .dst_clk(dclk), .dst_rst_n(drst_n), .pulse_out(pulse_ok));

    integer sent = 0, naive_cnt = 0, ps_cnt = 0;
    always @(posedge sclk) if (srst_n && pulse) sent = sent + 1;
    always @(posedge dclk) begin
        if (naive_q && !naive_d) naive_cnt = naive_cnt + 1;
        if (pulse_ok)            ps_cnt    = ps_cnt + 1;
    end

    initial begin
        #10000000;                                  // 10 us
        $display("BUG1 bus crossing : plain-binary bad jumps=%0d | gray good jumps=%0d (of %0d samples)", bad_jumps, good_jumps, n1);
        $display("BUG2 pulse        : sent=%0d naive_2ff_received=%0d pulse_sync_received=%0d", sent, naive_cnt, ps_cnt);
        if (bad_jumps > 0 && good_jumps == 0 && naive_cnt < sent && (ps_cnt == sent || ps_cnt == sent-1)) $display("PASS (bugs reproduced, fixes verified)");
        else $display("FAIL");
        $finish;
    end
endmodule
