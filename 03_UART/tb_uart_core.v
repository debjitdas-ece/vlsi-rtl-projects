`timescale 1ns/1ps
// tb_uart_core: directed sanity testbench for uart_core (FIFO + RTS/CTS wrapper).
// Pre-UVM gate for the upgrade layer - same self-checking style as Uart_tb.v.
module tb_uart_core;
    localparam FIFO_DEPTH = 16;
    localparam BYTE_TO    = 6000;              // clk cycles - margin over one full frame
    localparam EXPECTED_RTS_COUNT = FIFO_DEPTH - 2; // fifo_sync default ALMOST_FULL_THRESH=2

    reg clk=0, rst=1;
    reg [3:0] dbit=8;
    reg sp_t=0, p_en=0, psel=0, cts_n=0;
    reg tx_wr_en=0; reg [7:0] tx_wr_data=0;
    reg rx_rd_en=0;
    reg inject_en=0, inject_val=1;

    wire tx_full, tx_empty, rx_empty, rx_full, rx_overrun_err, frame_err, parity_err, rts_n, tx_line;
    wire [7:0] rx_rd_data;
    wire rx_in = inject_en ? inject_val : tx_line;

    integer pass_cnt=0, fail_cnt=0, i, tw;
    reg [7:0] tmp;
    reg gd;

    reg rts_seen = 0;
    integer rts_count_snapshot = -1;

    uart_core #(.FIFO_DEPTH(FIFO_DEPTH)) dut (
        .clk(clk), .rst(rst),
        .sp_t(sp_t), .p_en(p_en), .psel(psel), .cts_n(cts_n),
        .tx_wr_en(tx_wr_en), .rx_rd_en(rx_rd_en), .rx_line(rx_in),
        .dbit(dbit), .tx_wr_data(tx_wr_data),
        .tx_full(tx_full), .tx_empty(tx_empty),
        .rx_empty(rx_empty), .rx_full(rx_full), .rx_overrun_err(rx_overrun_err),
        .frame_err(frame_err), .parity_err(parity_err), .rts_n(rts_n), .tx_line(tx_line),
        .rx_rd_data(rx_rd_data)
    );

    always #10 clk = ~clk;

    // catches the exact FIFO count at the moment rts_n first asserts, via a
    // hierarchical peek at the RX FIFO's internal count - same technique the
    // original testbench uses to peek at drx.s during inject_test.
    always @(posedge clk) begin
        if (!rts_seen && rts_n) begin
            rts_seen = 1;
            rts_count_snapshot = dut.u_rx_fifo.count;
        end
    end

    task push_byte(input [7:0] val);
        begin
            @(posedge clk);
            while (tx_full) @(posedge clk);
            tx_wr_data <= val; tx_wr_en <= 1;
            @(posedge clk);
            tx_wr_en <= 0;
        end
    endtask

    task pop_and_check(input [7:0] exp, input [127:0] lbl);
        begin
            gd = 0;
            for (tw = 0; tw < BYTE_TO && !gd; tw = tw + 1) begin
                @(posedge clk);
                if (!rx_empty) gd = 1;
            end
            if (!gd) begin
                $display("FAIL [%s] RX EMPTY TIMEOUT", lbl); fail_cnt = fail_cnt + 1;
            end else if (rx_rd_data !== exp) begin
                $display("FAIL [%s] got=0x%02x exp=0x%02x", lbl, rx_rd_data, exp); fail_cnt = fail_cnt + 1;
            end else begin
                $display("PASS [%s] got=0x%02x", lbl, rx_rd_data); pass_cnt = pass_cnt + 1;
            end
            rx_rd_en <= 1; @(posedge clk); rx_rd_en <= 0;
        end
    endtask

    initial begin
        $dumpfile("wave_uart_core.vcd");
        $dumpvars(0, tb_uart_core);

        @(posedge clk); @(posedge clk); rst = 0;
        @(posedge clk);

        // ---------------- G1: single byte end-to-end sanity ----------------
        push_byte(8'hA5);
        pop_and_check(8'hA5, "G1 single byte");

        // ---------------- G2: back-to-back order preservation ----------------
        for (i = 0; i < 5; i = i + 1) push_byte(i[7:0]);
        for (i = 0; i < 5; i = i + 1) begin
            tmp = i[7:0];
            pop_and_check(tmp, "G2 order");
        end

        // ---------------- G3: TX FIFO full + backpressure + overflow drop ----------------
        cts_n = 1;  // block auto-send so pushes accumulate instead of draining
        @(posedge clk);
        for (i = 0; i < FIFO_DEPTH; i = i + 1) push_byte(i[7:0]);
        @(posedge clk);
        if (tx_full !== 1'b1) begin
            $display("FAIL [G3 tx_full] expected full after %0d pushes", FIFO_DEPTH);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [G3 tx_full] full asserted at count=%0d", FIFO_DEPTH);
            pass_cnt = pass_cnt + 1;
        end
        // one more push while full - must be silently dropped, not corrupt existing entries
        tx_wr_data <= 8'hAA; tx_wr_en <= 1; @(posedge clk); tx_wr_en <= 0;
        cts_n = 0;  // release backpressure, let the queued bytes drain and transmit
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            tmp = i[7:0];
            pop_and_check(tmp, "G3 drain order");
        end
        @(posedge clk);
        if (!rx_empty) begin
            $display("FAIL [G3 overflow] unexpected extra byte 0x%02x after draining %0d", rx_rd_data, FIFO_DEPTH);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [G3 overflow] overflow push correctly dropped, no extra byte");
            pass_cnt = pass_cnt + 1;
        end

        // ---------------- G4: RX almost_full/rts_n, full, and overrun ----------------
        // cts_n stays low so TX auto-drains continuously; never call rx_rd_en here
        // so the RX FIFO fills up while the sender keeps going past its capacity.
        for (i = 0; i < FIFO_DEPTH + 2; i = i + 1) push_byte(i[7:0]);

        gd = 0;
        for (tw = 0; tw < 20*BYTE_TO && !gd; tw = tw + 1) begin
            @(posedge clk);
            if (rx_full) gd = 1;
        end
        if (!gd) begin
            $display("FAIL [G4 rx_full] TIMEOUT waiting for RX FIFO full"); fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [G4 rx_full] RX FIFO reports full"); pass_cnt = pass_cnt + 1;
        end

        // give the trailing overflow byte(s) time to finish reception so overrun latches
        for (tw = 0; tw < BYTE_TO; tw = tw + 1) @(posedge clk);

        if (!rts_seen) begin
            $display("FAIL [G4 rts_n] never asserted"); fail_cnt = fail_cnt + 1;
        end else if (rts_count_snapshot !== EXPECTED_RTS_COUNT) begin
            $display("FAIL [G4 rts_n] asserted at count=%0d, expected %0d", rts_count_snapshot, EXPECTED_RTS_COUNT);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [G4 rts_n] asserted at count=%0d as expected", rts_count_snapshot);
            pass_cnt = pass_cnt + 1;
        end

        if (rx_overrun_err !== 1'b1) begin
            $display("FAIL [G4 overrun] expected rx_overrun_err set"); fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [G4 overrun] rx_overrun_err correctly set"); pass_cnt = pass_cnt + 1;
        end

        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            tmp = i[7:0];
            pop_and_check(tmp, "G4 drain after overrun");
        end

        // ---------------- G5: error-flag passthrough sanity ----------------
        p_en = 1; psel = 0;  // even parity, clean frame
        push_byte(8'h55);
        gd = 0;
        for (tw = 0; tw < BYTE_TO && !gd; tw = tw + 1) begin
            @(posedge clk);
            if (!rx_empty) gd = 1;
        end
        if (!gd) begin
            $display("FAIL [G5 parity clean] RX EMPTY TIMEOUT"); fail_cnt = fail_cnt + 1;
        end else if (parity_err !== 1'b0) begin
            $display("FAIL [G5 parity clean] parity_err unexpectedly set"); fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [G5 parity clean] parity_err=0 on clean frame"); pass_cnt = pass_cnt + 1;
        end
        rx_rd_en <= 1; @(posedge clk); rx_rd_en <= 0;
        p_en = 0;

        $display("=== TOTAL: %0d PASS  %0d FAIL ===", pass_cnt, fail_cnt);
        $finish;
    end
endmodule