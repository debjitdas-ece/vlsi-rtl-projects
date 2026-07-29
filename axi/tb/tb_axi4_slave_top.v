`include "rtl/common/axi_pkg.v"

// tb_axi4_slave_top.v
// Self-checking integration testbench for the full slave (all 7 slave
// modules wired together). Drives it via minimal master-BFM tasks
// (do_write / do_read) built here, since hand-toggling every channel
// signal per beat in the test body would be unreadable.
//
// Uses default slave region (Slave 0: 0x0000_0000 - 0x0000_0FFF).
//
// Run: cd sim && ./run.sh ../tb/tb_axi4_slave_top.v \
//        ../rtl/slave/axi4_slave_top.v ../rtl/slave/axi_addr_decode.v \
//        ../rtl/slave/axi_wr_fsm.v ../rtl/slave/axi_rd_fsm.v \
//        ../rtl/slave/axi_wstrb_merge.v ../rtl/slave/axi_regmap.v \
//        ../rtl/common/axi_burst_calc.v

module tb_axi4_slave_top;

    localparam ID_WIDTH = 3;

    integer pass_count = 0;
    integer fail_count = 0;

    task check32;
        input [1023:0] name;
        input [31:0]   got;
        input [31:0]   expected;
        begin
            if (got !== expected) begin
                $display("FAIL: %0s (got=%h expected=%h) at time %0t", name, got, expected, $time);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check2;
        input [1023:0] name;
        input [1:0]    got;
        input [1:0]    expected;
        begin
            if (got !== expected) begin
                $display("FAIL: %0s (got=%b expected=%b) at time %0t", name, got, expected, $time);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------
    reg clk, rst_n;

    reg                  awvalid;
    wire                 awready;
    reg  [31:0]          awaddr;
    reg  [7:0]           awlen;
    reg  [2:0]           awsize;
    reg  [1:0]           awburst;
    reg  [ID_WIDTH-1:0]  awid;

    reg                  wvalid;
    wire                 wready;
    reg  [31:0]          wdata;
    reg  [3:0]           wstrb;
    reg                  wlast;

    wire                 bvalid;
    reg                  bready;
    wire [1:0]           bresp;
    wire [ID_WIDTH-1:0]  bid;

    reg                  arvalid;
    wire                 arready;
    reg  [31:0]          araddr;
    reg  [7:0]           arlen;
    reg  [2:0]           arsize;
    reg  [1:0]           arburst;
    reg  [ID_WIDTH-1:0]  arid;

    wire                 rvalid;
    reg                  rready;
    wire [31:0]          rdata;
    wire [1:0]           rresp;
    wire                 rlast;
    wire [ID_WIDTH-1:0]  rid;

    axi4_slave_top #(
        .ID_WIDTH(ID_WIDTH)
        // REGION_BASE / REGION_LIMIT left at default (Slave 0: 0x0000-0x0FFF)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .awvalid(awvalid), .awready(awready), .awaddr(awaddr), .awlen(awlen),
        .awsize(awsize), .awburst(awburst), .awid(awid),
        .wvalid(wvalid), .wready(wready), .wdata(wdata), .wstrb(wstrb), .wlast(wlast),
        .bvalid(bvalid), .bready(bready), .bresp(bresp), .bid(bid),
        .arvalid(arvalid), .arready(arready), .araddr(araddr), .arlen(arlen),
        .arsize(arsize), .arburst(arburst), .arid(arid),
        .rvalid(rvalid), .rready(rready), .rdata(rdata), .rresp(rresp),
        .rlast(rlast), .rid(rid)
    );

    always #5 clk = ~clk;

    // -----------------------------------------------------------------
    // minimal master BFM
    // -----------------------------------------------------------------
    reg [31:0] tb_wdata [0:15];
    reg [3:0]  tb_wstrb [0:15];
    reg [31:0] tb_rdata [0:15];
    reg [1:0]  tb_rresp [0:15];
    reg [1:0]  tb_bresp;

    task do_write;
        input [31:0]          addr;
        input [7:0]           len_beats;
        input [2:0]           size;
        input [1:0]           burst;
        input [ID_WIDTH-1:0]  id;
        integer i;
        begin
            @(negedge clk);
            awaddr = addr; awlen = len_beats - 1; awsize = size; awburst = burst; awid = id;
            awvalid = 1'b1;
            @(posedge clk);
            while (!awready) @(posedge clk);
            @(negedge clk);
            awvalid = 1'b0;

            for (i = 0; i < len_beats; i = i + 1) begin
                @(negedge clk);
                wdata  = tb_wdata[i];
                wstrb  = tb_wstrb[i];
                wlast  = (i == len_beats - 1);
                wvalid = 1'b1;
                @(posedge clk);
                while (!wready) @(posedge clk);
            end
            @(negedge clk);
            wvalid = 1'b0;
            wlast  = 1'b0;

            bready = 1'b1;
            @(posedge clk);
            while (!bvalid) @(posedge clk);
            tb_bresp = bresp;
            @(negedge clk);
            bready = 1'b0;
        end
    endtask

    task do_read;
        input [31:0]          addr;
        input [7:0]           len_beats;
        input [2:0]           size;
        input [1:0]           burst;
        input [ID_WIDTH-1:0]  id;
        integer i;
        begin
            @(negedge clk);
            araddr = addr; arlen = len_beats - 1; arsize = size; arburst = burst; arid = id;
            arvalid = 1'b1;
            @(posedge clk);
            while (!arready) @(posedge clk);
            @(negedge clk);
            arvalid = 1'b0;

            rready = 1'b1;
            for (i = 0; i < len_beats; i = i + 1) begin
                @(posedge clk);
                while (!rvalid) @(posedge clk);
                tb_rdata[i] = rdata;
                tb_rresp[i] = rresp;
                @(negedge clk);
            end
            rready = 1'b0;
        end
    endtask

    // -----------------------------------------------------------------
    // test sequence
    // -----------------------------------------------------------------
    initial begin
        clk = 0; rst_n = 0;
        awvalid = 0; wvalid = 0; bready = 0; arvalid = 0; rready = 0;
        wlast = 0;
        @(negedge clk); @(negedge clk);
        rst_n = 1;
        @(negedge clk);

        // --- Test 1: single-beat write then read-back ---
        $display("--- Test 1: single-beat write + read-back ---");
        tb_wdata[0] = 32'hCAFEBABE; tb_wstrb[0] = 4'b1111;
        do_write(32'h0000_0010, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd1);
        check2("T1 bresp OKAY", tb_bresp, `AXI_RESP_OKAY);
        do_read(32'h0000_0010, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd1);
        check32("T1 read-back matches write", tb_rdata[0], 32'hCAFEBABE);
        check2("T1 rresp OKAY", tb_rresp[0], `AXI_RESP_OKAY);

        // --- Test 2: 4-beat INCR burst write, then read back ---
        $display("--- Test 2: 4-beat INCR burst ---");
        tb_wdata[0]=32'h1111_1111; tb_wstrb[0]=4'b1111;
        tb_wdata[1]=32'h2222_2222; tb_wstrb[1]=4'b1111;
        tb_wdata[2]=32'h3333_3333; tb_wstrb[2]=4'b1111;
        tb_wdata[3]=32'h4444_4444; tb_wstrb[3]=4'b1111;
        do_write(32'h0000_0100, 8'd4, 3'd2, `AXI_BURST_INCR, 3'd2);
        check2("T2 bresp OKAY", tb_bresp, `AXI_RESP_OKAY);
        do_read(32'h0000_0100, 8'd4, 3'd2, `AXI_BURST_INCR, 3'd2);
        check32("T2 beat0", tb_rdata[0], 32'h1111_1111);
        check32("T2 beat1", tb_rdata[1], 32'h2222_2222);
        check32("T2 beat2", tb_rdata[2], 32'h3333_3333);
        check32("T2 beat3", tb_rdata[3], 32'h4444_4444);

        // --- Test 3: partial WSTRB write, confirm unstrobed bytes preserved ---
        $display("--- Test 3: partial WSTRB write ---");
        tb_wdata[0] = 32'hAABBCCDD; tb_wstrb[0] = 4'b1111;
        do_write(32'h0000_0200, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd3); // seed known value
        tb_wdata[0] = 32'h11223344; tb_wstrb[0] = 4'b0011; // only lower 2 bytes
        do_write(32'h0000_0200, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd3);
        do_read(32'h0000_0200, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd3);
        check32("T3 partial strobe merge", tb_rdata[0], 32'hAABB3344);

        // --- Test 4: write outside region -> DECERR, memory unchanged ---
        $display("--- Test 4: out-of-region write ---");
        tb_wdata[0] = 32'hDEAD_DEAD; tb_wstrb[0] = 4'b1111;
        do_write(32'h0000_2000, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd4); // outside 0x0FFF limit
        check2("T4 bresp DECERR (out of region)", tb_bresp, `AXI_RESP_DECERR);

        // --- Test 5: burst crossing the region/4KB edge -> DECERR ---
        $display("--- Test 5: burst crossing 4KB boundary ---");
        tb_wdata[0]=32'h1; tb_wdata[1]=32'h2; tb_wdata[2]=32'h3; tb_wdata[3]=32'h4;
        tb_wstrb[0]=4'b1111; tb_wstrb[1]=4'b1111; tb_wstrb[2]=4'b1111; tb_wstrb[3]=4'b1111;
        do_write(32'h0000_0FFC, 8'd4, 3'd2, `AXI_BURST_INCR, 3'd5); // ends at 0x100B, crosses boundary
        check2("T5 bresp DECERR (crosses boundary)", tb_bresp, `AXI_RESP_DECERR);

        // --- Test 6: WRAP burst write + read-back, confirm wrap pattern end-to-end ---
        $display("--- Test 6: WRAP burst ---");
        tb_wdata[0]=32'hA000; tb_wdata[1]=32'hB000; tb_wdata[2]=32'hC000; tb_wdata[3]=32'hD000;
        tb_wstrb[0]=4'b1111; tb_wstrb[1]=4'b1111; tb_wstrb[2]=4'b1111; tb_wstrb[3]=4'b1111;
        do_write(32'h0000_0008, 8'd4, 3'd2, `AXI_BURST_WRAP, 3'd6); // window 0x0000-0x000F
        check2("T6 bresp OKAY", tb_bresp, `AXI_RESP_OKAY);
        // beat order written: 0x8, 0xC, 0x0, 0x4 (wrap pattern)
        do_read(32'h0000_0000, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd6);
        check32("T6 addr 0x0 got beat2 data", tb_rdata[0], 32'hC000);
        do_read(32'h0000_0004, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd6);
        check32("T6 addr 0x4 got beat3 data", tb_rdata[0], 32'hD000);
        do_read(32'h0000_0008, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd6);
        check32("T6 addr 0x8 got beat0 data", tb_rdata[0], 32'hA000);
        do_read(32'h0000_000C, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd6);
        check32("T6 addr 0xC got beat1 data", tb_rdata[0], 32'hB000);

        // --- Test 7: back-to-back bursts, no gap ---
        $display("--- Test 7: back-to-back bursts ---");
        tb_wdata[0] = 32'h7777_0001; tb_wstrb[0] = 4'b1111;
        do_write(32'h0000_0300, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd7);
        tb_wdata[0] = 32'h7777_0002; tb_wstrb[0] = 4'b1111;
        do_write(32'h0000_0304, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd7);
        check2("T7 second burst bresp OKAY", tb_bresp, `AXI_RESP_OKAY);
        do_read(32'h0000_0300, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd7);
        check32("T7 first burst landed", tb_rdata[0], 32'h7777_0001);
        do_read(32'h0000_0304, 8'd1, 3'd2, `AXI_BURST_INCR, 3'd7);
        check32("T7 second burst landed", tb_rdata[0], 32'h7777_0002);

        #20;
        $display("=================================================");
        $display("TOTAL: %0d passed, %0d failed", pass_count, fail_count);
        $display("=================================================");
        $finish;
    end

endmodule
