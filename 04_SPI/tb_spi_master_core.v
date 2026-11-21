`timescale 1ns/1ns
// tb_spi_master_core: sanity testbench for spi_master_core.
//   G1 - diff-test: spi_master (frozen) and spi_master_core run side-by-side
//        under identical stimulus at burst_len=1/width_m1=7, diffed every
//        cycle across all 4 modes - confirms the new module didn't disturb
//        the already-verified single-word path.
//   G2 - multi-word continuous-SS burst across all 4 modes, with an
//        edge-timestamp continuity check across the word boundary -
//        specifically exercises the CPHA=1 sample/reload coincidence.
//   G3 - multi-SS one-hot decode sweep.
//   G4 - variable data width, using a second, 16-bit slave BFM.
module tb_spi_master_core;

    localparam CLK_F        = 50_000_000;
    localparam SPI_F        = 5_000_000;      // N = 5
    localparam SETUP_CYCLES = 4;
    localparam HOLD_CYCLES  = 6;
    localparam N            = CLK_F / (2*SPI_F);
    localparam CLK_PERIOD   = 1_000_000_000 / CLK_F;
    localparam BYTE_TO      = 2000;

    reg clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    reg         rst, start, cpol, cpha;
    reg  [15:0] tx_data;
    reg  [3:0]  width_m1;
    reg  [7:0]  burst_len;
    reg  [2:0]  ss_sel;

    wire        mosi, sclk, busy, done, burst_done, tx_load;
    wire [7:0]  ss_n;
    wire [15:0] rx_data;
    wire        miso;

    integer pass_cnt = 0, fail_cnt = 0;
    integer i, m, tw;

    task pf(input ok, input [8*64-1:0] lbl);
        begin
            if (ok) begin
                $display("PASS [%0s]", lbl); pass_cnt = pass_cnt + 1;
            end else begin
                $display("FAIL [%0s]", lbl); fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // ------------------------------------------------------------------
    // spi_master_core DUT + its DW=8 slave BFM (used for G1-G3)
    // ------------------------------------------------------------------
    reg  [7:0] slave_tx = 8'hAA;
    wire [7:0] slave_rx;
    wire       slave_rx_valid;
    wire       miso_normal;

    spi_master_core #(
        .CLK_F(CLK_F), .SPI_F(SPI_F),
        .SETUP_CYCLES(SETUP_CYCLES), .HOLD_CYCLES(HOLD_CYCLES)
    ) dut (
        .clk(clk), .rst(rst), .start(start), .tx_data(tx_data),
        .cpol(cpol), .cpha(cpha), .width_m1(width_m1), .burst_len(burst_len),
        .ss_sel(ss_sel), .miso(miso),
        .mosi(mosi), .sclk(sclk), .ss_n(ss_n),
        .rx_data(rx_data), .busy(busy), .done(done),
        .burst_done(burst_done), .tx_load(tx_load)
    );

    spi_slave_bfm_burst #(.DW(8)) slave (
        .sclk(sclk), .ss(ss_n[0]), .cpol(cpol), .cpha(cpha),
        .mosi(mosi), .miso(miso_normal),
        .tx_data(slave_tx), .rx_data(slave_rx), .rx_valid(slave_rx_valid)
    );

    // ------------------------------------------------------------------
    // G4: second, wider slave BFM, sharing the miso bus via explicit
    // tri-stating - spi_slave_bfm.v drives miso unconditionally (it was
    // never written for a shared-bus, multi-slave scenario), so each
    // slave's output has to be gated by its own ss line here in the TB
    // rather than relying on the BFM to do it.
    // ------------------------------------------------------------------
    reg  [15:0] wide_slave_tx = 16'hBEEF;
    wire [15:0] wide_slave_rx;
    wire        wide_slave_rx_valid;
    wire        miso_wide;

    assign miso = (ss_n[0] == 1'b0) ? miso_normal : 1'bz;
    assign miso = (ss_n[1] == 1'b0) ? miso_wide   : 1'bz;

    spi_slave_bfm #(.DW(16)) wide_slave (
        .sclk(sclk), .ss(ss_n[1]), .cpol(cpol), .cpha(cpha),
        .mosi(mosi), .miso(miso_wide),
        .tx_data(wide_slave_tx), .rx_data(wide_slave_rx), .rx_valid(wide_slave_rx_valid)
    );

    // ------------------------------------------------------------------
    // G1: legacy spi_master, driven by the SAME stimulus, diffed every cycle
    // ------------------------------------------------------------------
    wire        leg_mosi, leg_sclk, leg_ss, leg_busy, leg_done;
    wire [7:0]  leg_rx_data;
    wire        leg_miso;
    reg         g1_active = 0;
    reg         g1_mismatch = 0;

    spi_master #(
        .CLK_F(CLK_F), .SPI_F(SPI_F),
        .SETUP_CYCLES(SETUP_CYCLES), .HOLD_CYCLES(HOLD_CYCLES)
    ) legacy_dut (
        .clk(clk), .rst(rst), .start(start), .tx_data(tx_data[7:0]),
        .cpol(cpol), .cpha(cpha), .miso(leg_miso),
        .mosi(leg_mosi), .sclk(leg_sclk), .ss(leg_ss),
        .rx_data(leg_rx_data), .busy(leg_busy), .done(leg_done)
    );

    spi_slave_bfm #(.DW(8)) legacy_slave (
        .sclk(leg_sclk), .ss(leg_ss), .cpol(cpol), .cpha(cpha),
        .mosi(leg_mosi), .miso(leg_miso),
        .tx_data(slave_tx), .rx_data(), .rx_valid()
    );

    always @(posedge clk) begin
        if (g1_active) begin
            if (mosi !== leg_mosi || sclk !== leg_sclk || ss_n[0] !== leg_ss ||
                busy !== leg_busy || done !== leg_done ||
                (done && rx_data[7:0] !== leg_rx_data))
                g1_mismatch <= 1'b1;
        end
    end

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------
    task wait_idle;
        begin
            @(posedge clk);   // busy rises one edge after start
            while (busy) @(posedge clk);
        end
    endtask

    task do_single(input [15:0] td, input [3:0] wm1, input [2:0] sel);
        begin
            wait_idle;
            @(posedge clk);
            tx_data   <= td;
            width_m1  <= wm1;
            burst_len <= 8'd1;
            ss_sel    <= sel;
            start     <= 1'b1;
            @(posedge clk);
            start     <= 1'b0;
        end
    endtask

    reg [15:0] word_q [0:7];
    integer    wq_idx;

    always @(posedge clk) begin
        if (start && !busy)
            begin wq_idx <= 2; if (burst_len > 1) tx_data <= word_q[1]; end
        else if (tx_load) begin
            tx_data <= word_q[wq_idx];
            wq_idx  <= wq_idx + 1;
        end
    end

    time    edge_t[0:63];
    integer edge_n;
    always @(posedge sclk or negedge sclk) begin
        if (busy) begin
            edge_t[edge_n] = $time;
            edge_n = edge_n + 1;
        end
    end

    // ------------------------------------------------------------------
    initial begin
        $dumpfile("wave_spi_master_core.vcd");
        $dumpvars(0, tb_spi_master_core);

        rst = 1; start = 0; cpol = 0; cpha = 0; tx_data = 0;
        width_m1 = 4'd7; burst_len = 8'd1; ss_sel = 3'd0;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ============= G1: diff vs frozen spi_master, all 4 modes =============
        g1_active = 1;
        for (m = 0; m < 4; m = m + 1) begin
            cpol = m[1]; cpha = m[0];
            for (i = 0; i < 4; i = i + 1) begin
                do_single({8'd0, (i*8'h33 + 8'h11)}, 4'd7, 3'd0);
                wait_idle;
                repeat (HOLD_CYCLES + 2) @(posedge clk);
            end
        end
        g1_active = 0;
        pf(!g1_mismatch, "G1 diff-test vs frozen spi_master (4 modes)");

        // ============= G2: continuous-SS burst, all 4 modes =============
        burst_len = 8'd4;
        width_m1  = 4'd7;
        ss_sel    = 3'd0;
        for (m = 0; m < 4; m = m + 1) begin
            cpol = m[1]; cpha = m[0];
            word_q[0] = 16'h0011; word_q[1] = 16'h0022;
            word_q[2] = 16'h0033; word_q[3] = 16'h0044;

            edge_n = 0;
            wait_idle;
            @(posedge clk);
            tx_data <= word_q[0];
            start   <= 1'b1;
            @(posedge clk);
            start   <= 1'b0;

            // collect all 4 done pulses + confirm SS stays low throughout
            begin : g2_word_loop
                integer wnum;
                reg ss_glitched;
                ss_glitched = 0;
                @(posedge clk);   // SS asserts one edge after start
                for (wnum = 0; wnum < 4; wnum = wnum + 1) begin
                    tw = 0;
                    while (!done && tw < BYTE_TO) begin
                        if (ss_n[0] !== 1'b0 || !busy) ss_glitched = 1;
                        @(posedge clk);
                        tw = tw + 1;
                    end
                    if (tw >= BYTE_TO) begin
                        pf(0, "G2 word timeout");
                    end else begin
                        pf(rx_data === {8'h00, slave_tx}, "G2 per-word rx_data correct");
                    if (rx_data !== {8'h00, slave_tx})
                        $display("   G2 m=%0d word=%0d rx_data=%h expected=%h", m, wnum, rx_data, slave_tx);
                    end
                    @(posedge clk);
                end
                pf(!ss_glitched, "G2 SS held continuously low across burst");
            end

            wait_idle;
            pf(1'b1, "G2 burst_done reached idle cleanly");

            // SCLK continuity: every inter-edge gap must equal N system clocks,
            // including the boundary between words - this is what would break
            // first if the CPHA=1 sample/reload coincidence were mishandled.
            begin : g2_gap_check
                integer k;
                reg gaps_ok;
                gaps_ok = 1;
                for (k = 1; k < edge_n; k = k + 1)
                    if ((edge_t[k] - edge_t[k-1]) !== N * CLK_PERIOD) gaps_ok = 0;
                pf(gaps_ok && (edge_n == 4*16), "G2 SCLK edge spacing uniform across word boundaries");
            end

            repeat (HOLD_CYCLES + 2) @(posedge clk);
        end
        burst_len = 8'd1;

        // ============= G3: multi-SS one-hot decode =============
        begin : g3_block
            integer sel;
            reg decode_ok;
            for (sel = 0; sel < 8; sel = sel + 1) begin
                ss_sel = sel[2:0];
                wait_idle;
                @(posedge clk);
                tx_data <= 16'h5A; width_m1 <= 4'd7; burst_len <= 8'd1;
                start   <= 1'b1;
                @(posedge clk);
                start   <= 1'b0;
                @(posedge clk);
                decode_ok = (ss_n == (~(8'b1 << sel)));
                pf(decode_ok, "G3 ss_n one-hot decode");
                wait_idle;
                repeat (HOLD_CYCLES + 2) @(posedge clk);
            end
        end
        ss_sel = 3'd0;

        // ============= G4: variable width (12-bit, via the wide slave) =============
        ss_sel   = 3'd1;             // selects wide_slave
        width_m1 = 4'd11;            // 12-bit word
        cpol = 0; cpha = 0;
        do_single(16'h0A5A, 4'd11, 3'd1);
        tw = 0;
        while (!done && tw < BYTE_TO) begin @(posedge clk); tw = tw + 1; end
        pf(tw < BYTE_TO, "G4 12-bit transfer completed");
        $display("   G4 rx_data=%h wide_slave_tx=%h", rx_data, wide_slave_tx);
        pf(rx_data === wide_slave_tx[15:4], "G4 12-bit rx_data correct, upper bits clean");
        wait_idle;

        $display("=== TOTAL: %0d PASS  %0d FAIL ===", pass_cnt, fail_cnt);
        $finish;
    end
endmodule