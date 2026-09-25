`timescale 1ns/1ps
// tb_uart_top: APB3-level sanity testbench for uart_top.
// Drives every register through a proper SETUP->ACCESS transfer and loops
// tx_line back into rx_line, so a byte written to TXDATA can be checked by
// reading it back out of RXDATA through the same bus - no direct DUT-internal
// signal access needed at this level (unlike tb_uart_core's rts_n snapshot).
module tb_uart_top;
    localparam FIFO_DEPTH = 16;
    localparam BYTE_TO    = 6000;

    localparam ADDR_CTRL   = 8'h00;
    localparam ADDR_STATUS = 8'h04;
    localparam ADDR_TXDATA = 8'h0C;
    localparam ADDR_RXDATA = 8'h10;

    reg PCLK=0, PRESETn=0;
    reg PSEL=0, PENABLE=0, PWRITE=0;
    reg [7:0]  PADDR=0;
    reg [31:0] PWDATA=0;
    wire [31:0] PRDATA;
    wire PREADY;

    reg cts_n = 0;
    wire tx_line, rts_n;
    wire rx_line = tx_line;   // loopback at this level of the stack

    integer pass_cnt=0, fail_cnt=0, i, tw;
    reg [31:0] rd;
    reg gd;

    uart_top #(.FIFO_DEPTH(FIFO_DEPTH)) dut (
        .PCLK(PCLK), .PRESETn(PRESETn),
        .PSEL(PSEL), .PENABLE(PENABLE), .PWRITE(PWRITE),
        .PADDR(PADDR), .PWDATA(PWDATA), .PRDATA(PRDATA), .PREADY(PREADY),
        .rx_line(rx_line), .cts_n(cts_n),
        .tx_line(tx_line), .rts_n(rts_n)
    );

    always #10 PCLK = ~PCLK;

    // one full APB write: SETUP cycle, ACCESS cycle, then back to idle
    task apb_write(input [7:0] addr, input [31:0] data);
        begin
            @(posedge PCLK);
            PSEL <= 1; PENABLE <= 0; PWRITE <= 1; PADDR <= addr; PWDATA <= data;
            @(posedge PCLK);
            PENABLE <= 1;
            @(posedge PCLK);
            PSEL <= 0; PENABLE <= 0; PWRITE <= 0;
        end
    endtask

    // one full APB read: SETUP cycle, ACCESS cycle, sample PRDATA, then idle
    task apb_read(input [7:0] addr, output [31:0] data);
        begin
            @(posedge PCLK);
            PSEL <= 1; PENABLE <= 0; PWRITE <= 0; PADDR <= addr;
            @(posedge PCLK);
            PENABLE <= 1;
            @(posedge PCLK);
            data = PRDATA;
            PSEL <= 0; PENABLE <= 0;
        end
    endtask

    task check_status_bit(input [31:0] status_val, input integer bit_idx,
                           input exp_val, input [8*48-1:0] lbl);
        begin
            if (status_val[bit_idx] !== exp_val) begin
                $display("FAIL [%0s] bit%0d=%b exp=%b (STATUS=0x%08x)",
                          lbl, bit_idx, status_val[bit_idx], exp_val, status_val);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("PASS [%0s] bit%0d=%b", lbl, bit_idx, status_val[bit_idx]);
                pass_cnt = pass_cnt + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("wave_uart_top.vcd");
        $dumpvars(0, tb_uart_top);

        // ---------------- reset ----------------
        PRESETn = 0;
        repeat (3) @(posedge PCLK);
        PRESETn = 1;
        @(posedge PCLK);

        // ---------------- G0: disabled core ignores TXDATA ----------------
        apb_write(ADDR_TXDATA, 32'h000000AA);   // EN=0 - core held in reset, must be dropped
        repeat (5) @(posedge PCLK);
        apb_read(ADDR_STATUS, rd);
        check_status_bit(rd, 0, 1'b1, "G0 tx_empty stays set while disabled");

        // ---------------- G1: enable 8N1, verify CTRL readback ----------------
        // CTRL = {DBIT=8, TWO_STOP=0, PARITY_ODD=0, PARITY_EN=0, EN=1} = 8'h81
        apb_write(ADDR_CTRL, 32'h00000081);
        apb_read(ADDR_CTRL, rd);
        if (rd[0] !== 1'b1 || rd[7:4] !== 4'd8) begin
            $display("FAIL [G1 ctrl readback] CTRL=0x%08x", rd); fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [G1 ctrl readback] CTRL=0x%08x", rd); pass_cnt = pass_cnt + 1;
        end

        // ---------------- G2: single byte through the bus, loopback, read back ----------------
        apb_write(ADDR_TXDATA, 32'h000000A5);

        gd = 0;
        for (tw = 0; tw < BYTE_TO && !gd; tw = tw + 1) begin
            @(posedge PCLK);
            apb_read(ADDR_STATUS, rd);
            if (rd[2] === 1'b0) gd = 1;   // rx_empty deasserted -> byte arrived
        end
        if (!gd) begin
            $display("FAIL [G2 byte arrival] TIMEOUT waiting for rx_empty=0"); fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [G2 byte arrival] rx_empty deasserted"); pass_cnt = pass_cnt + 1;
        end

        apb_read(ADDR_RXDATA, rd);
        if (rd[7:0] !== 8'hA5) begin
            $display("FAIL [G2 rxdata] got=0x%02x exp=0xA5", rd[7:0]); fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [G2 rxdata] got=0x%02x", rd[7:0]); pass_cnt = pass_cnt + 1;
        end

        // ---------------- G3: burst of 5 bytes through the bus, order preserved ----------------
        for (i = 0; i < 5; i = i + 1) apb_write(ADDR_TXDATA, {24'd0, i[7:0]});

        for (i = 0; i < 5; i = i + 1) begin
            gd = 0;
            for (tw = 0; tw < BYTE_TO && !gd; tw = tw + 1) begin
                @(posedge PCLK);
                apb_read(ADDR_STATUS, rd);
                if (rd[2] === 1'b0) gd = 1;
            end
            if (!gd) begin
                $display("FAIL [G3 burst byte %0d] TIMEOUT", i); fail_cnt = fail_cnt + 1;
            end else begin
                apb_read(ADDR_RXDATA, rd);
                if (rd[7:0] !== i[7:0]) begin
                    $display("FAIL [G3 burst byte %0d] got=0x%02x exp=0x%02x", i, rd[7:0], i[7:0]);
                    fail_cnt = fail_cnt + 1;
                end else begin
                    $display("PASS [G3 burst byte %0d] got=0x%02x", i, rd[7:0]);
                    pass_cnt = pass_cnt + 1;
                end
            end
        end

        // ---------------- G4: STATUS reflects TX FIFO full via the bus ----------------
        cts_n = 1;   // block auto-drain so pushes accumulate
        for (i = 0; i < FIFO_DEPTH; i = i + 1) apb_write(ADDR_TXDATA, {24'd0, i[7:0]});
        apb_read(ADDR_STATUS, rd);
        check_status_bit(rd, 1, 1'b1, "G4 tx_full via STATUS");

        cts_n = 0;                                  // release, let the queue drain+arrive
        repeat (FIFO_DEPTH * BYTE_TO) @(posedge PCLK); // generous margin - ordering already proven at uart_core level

        for (i = 0; i < FIFO_DEPTH; i = i + 1) apb_read(ADDR_RXDATA, rd);  // drain via the bus

        apb_read(ADDR_STATUS, rd);
        check_status_bit(rd, 2, 1'b1, "G4 rx_empty after full drain");

        $display("=== TOTAL: %0d PASS  %0d FAIL ===", pass_cnt, fail_cnt);
        $finish;
    end
endmodule