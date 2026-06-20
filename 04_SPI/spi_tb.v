`timescale 1ns/1ns
module tb_spi_master;

    // ------------------------------------------------------------------
    // DUT configuration (kept small so the regression runs fast)
    // ------------------------------------------------------------------
    localparam CLK_F        = 50_000_000;
    localparam SPI_F        = 5_000_000;          // N = 5
    localparam SETUP_CYCLES = 4;
    localparam HOLD_CYCLES  = 6;
    localparam N            = CLK_F / (2*SPI_F);
    localparam CLK_PERIOD   = 1_000_000_000 / CLK_F; // ns
    localparam NE           = 16;                  // edges/byte

    reg clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    reg        rst, start, cpol, cpha;
    reg  [7:0] tx_data;
    wire       mosi, sclk, ss, busy, done;
    wire [7:0] rx_data;
    wire       miso;

    reg  [7:0] slave_tx;
    wire [7:0] slave_rx;
    wire       slave_rx_valid;

    spi_master #(
        .CLK_F(CLK_F), .SPI_F(SPI_F),
        .SETUP_CYCLES(SETUP_CYCLES), .HOLD_CYCLES(HOLD_CYCLES)
    ) dut (
        .clk(clk), .rst(rst), .start(start), .tx_data(tx_data),
        .cpol(cpol), .cpha(cpha), .miso(miso),
        .mosi(mosi), .sclk(sclk), .ss(ss),
        .rx_data(rx_data), .busy(busy), .done(done)
    );

    spi_slave_bfm #(.DW(8)) slave (
        .sclk(sclk), .ss(ss), .cpol(cpol), .cpha(cpha),
        .mosi(mosi), .miso(miso),
        .tx_data(slave_tx), .rx_data(slave_rx), .rx_valid(slave_rx_valid)
    );

    // ------------------------------------------------------------------
    // sclk edge / chip-select timestamp capture
    // ------------------------------------------------------------------
    time    edge_t [0:31];
    integer edge_n;
    time    ss_fall_t, ss_rise_t;

    always @(negedge ss) begin
        edge_n    = 0;
        ss_fall_t = $time;
    end
    always @(posedge ss) ss_rise_t = $time;
    always @(sclk) if (!ss) begin
        edge_t[edge_n] = $time;
        edge_n         = edge_n + 1;
    end

    // ------------------------------------------------------------------
    // scoreboard
    // ------------------------------------------------------------------
    integer n_checks = 0;
    integer n_fail   = 0;

    task check(input string name, input ok);
        begin
            n_checks = n_checks + 1;
            if (!ok) begin
                n_fail = n_fail + 1;
                $display("[%0t] FAIL: %s", $time, name);
            end
        end
    endtask

    // ------------------------------------------------------------------
    // transfer driver + checks
    // ------------------------------------------------------------------
    integer i;

    task do_transfer(input [7:0] m_tx, input [7:0] s_tx, input cpol_v, input cpha_v);
        begin
            wait (!busy);
            @(posedge clk); #1;
            cpol     = cpol_v;
            cpha     = cpha_v;
            tx_data  = m_tx;
            slave_tx = s_tx;
            start    = 1'b1;
            @(posedge clk); #1;
            start = 1'b0;

            @(posedge done);
            check("rx_data valid the same cycle done asserts", rx_data === s_tx);

            @(posedge ss);
            #1;
            check("slave captured exact master tx byte (full-duplex bit integrity)", slave_rx === m_tx);
            check("idle sclk returns to cpol level", sclk === cpol_v);
            check("exactly 16 sclk edges generated for one byte", edge_n == NE);

            for (i = 1; i < NE; i = i + 1)
                check("sclk half-period uniform, incl. final pulse", (edge_t[i]-edge_t[i-1]) == N*CLK_PERIOD);

            check("ss-to-first-sclk-edge setup time correct", (edge_t[0]-ss_fall_t) == (SETUP_CYCLES+N)*CLK_PERIOD);
            check("last-sclk-edge-to-ss hold time correct", (ss_rise_t-edge_t[NE-1]) == HOLD_CYCLES*CLK_PERIOD);
        end
    endtask

    // ------------------------------------------------------------------
    // stimulus
    // ------------------------------------------------------------------
    reg [7:0] pattern [0:5];
    integer   mode;
    integer   b;

    initial begin
        pattern[0] = 8'h00; pattern[1] = 8'hFF; pattern[2] = 8'hA5;
        pattern[3] = 8'h5A; pattern[4] = 8'h3C; pattern[5] = 8'h81;
    end

    initial begin
        $dumpfile("spi_tb.vcd");
        $dumpvars(0, tb_spi_master);

        rst = 1; start = 0; cpol = 0; cpha = 0; tx_data = 0; slave_tx = 0;
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (3) @(posedge clk);

        // ---- directed + pseudo-random sweep across all 4 SPI modes ----
        for (mode = 0; mode < 4; mode = mode + 1) begin
            for (b = 0; b < 6; b = b + 1) begin
                $display("[%0t] starting mode=%0d cpol=%0d cpha=%0d byte=%0d", $time, mode, mode[1], mode[0], b);
                do_transfer(pattern[b], ~pattern[b] ^ 8'h3C, mode[1], mode[0]);
                $display("[%0t] finished mode=%0d byte=%0d", $time, mode, b);
                repeat (2) @(posedge clk);
            end
        end

        // ---- back-to-back: start asserted the instant IDLE is reached ----
        $display("[%0t] starting back-to-back test", $time);
        do_transfer(8'h11, 8'h22, 1'b0, 1'b0);
        $display("[%0t] back-to-back txn1 done, ss already high, issuing txn2 immediately", $time);
        tx_data  = 8'h33; slave_tx = 8'h44; cpol = 0; cpha = 0;
        start = 1'b1;
        @(posedge clk); #1;
        start = 1'b0;
        $display("[%0t] txn2 start pulsed, waiting done", $time);
        @(posedge done);
        $display("[%0t] txn2 done seen", $time);
        check("back-to-back: rx_data correct on 2nd txn", rx_data === 8'h44);
        wait (!busy); #1;
        check("back-to-back: slave saw correct 2nd byte", slave_rx === 8'h33);
        $display("[%0t] back-to-back test complete", $time);

        // ---- reset asserted mid-transfer ----
        @(posedge clk); #1;
        cpol = 0; cpha = 1; tx_data = 8'h99; slave_tx = 8'h66;
        start = 1'b1;
        @(posedge clk); #1;
        start = 1'b0;
        repeat (SETUP_CYCLES + N + 3) @(posedge clk);
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        check("reset mid-transfer: busy deasserted", busy === 1'b0);
        check("reset mid-transfer: ss deasserted",   ss   === 1'b1);
        check("reset mid-transfer: sclk at cpol",    sclk === 1'b0);
        check("reset mid-transfer: done low",        done === 1'b0);
        repeat (3) @(posedge clk);

        $display("========================================");
        $display(" SPI master regression: %0d checks, %0d failed", n_checks, n_fail);
        if (n_fail == 0) $display(" RESULT: PASS");
        else             $display(" RESULT: FAIL");
        $display("========================================");
        $finish;
    end

    // watchdog
    initial begin
        #200000;
        $display("TIMEOUT - simulation hung");
        $finish;
    end

endmodule