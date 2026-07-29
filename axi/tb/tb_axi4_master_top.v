`include "rtl/common/axi_pkg.v"

// tb_axi4_master_top.v
// Point-to-point integration test: axi4_master_top <-> axi4_slave_top,
// directly wired (Stage 1 style, per the plan's own diagram). Since the
// slave is already independently verified (tb_axi4_slave_top.v, all
// passing), this doubles as real end-to-end validation of the master's
// cmd_fsm + pending FIFOs + id_trackers + wr_fsm/rd_fsm, not just a
// unit test against a simplified stand-in.
//
// Run (from project root): ./sim/run.sh tb/tb_axi4_master_top.v

module tb_axi4_master_top;

    localparam ID_WIDTH = 4;

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

    task check1;
        input [1023:0] name;
        input          got;
        input          expected;
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
    // shared clock/reset
    // -----------------------------------------------------------------
    reg clk, rst_n;
    always #5 clk = ~clk;

    // -----------------------------------------------------------------
    // wires connecting master_top <-> slave_top, point-to-point
    // -----------------------------------------------------------------
    wire                 awvalid, awready;
    wire [31:0]          awaddr;
    wire [7:0]           awlen;
    wire [2:0]           awsize;
    wire [1:0]           awburst;
    wire [ID_WIDTH-1:0]  awid;

    wire                 wvalid, wready;
    wire [31:0]          wdata;
    wire [3:0]           wstrb;
    wire                 wlast;

    wire                 bvalid, bready;
    wire [1:0]           bresp;
    wire [ID_WIDTH-1:0]  bid;

    wire                 arvalid, arready;
    wire [31:0]          araddr;
    wire [7:0]           arlen;
    wire [2:0]           arsize;
    wire [1:0]           arburst;
    wire [ID_WIDTH-1:0]  arid;

    wire                 rvalid, rready;
    wire [31:0]          rdata;
    wire [1:0]           rresp;
    wire                 rlast;
    wire [ID_WIDTH-1:0]  rid;

    // -----------------------------------------------------------------
    // master_top's TB-facing ports
    // -----------------------------------------------------------------
    reg                  cmd_valid;
    wire                 cmd_ready;
    reg                  cmd_op;
    reg  [31:0]          cmd_addr;
    reg  [7:0]           cmd_len;
    reg  [2:0]           cmd_size;
    reg  [1:0]           cmd_burst;
    reg  [ID_WIDTH-1:0]  cmd_id;

    reg  [31:0]          wdata_in;
    reg  [3:0]           wstrb_in;
    wire [31:0]          rdata_out;
    wire [1:0]           rresp_out;

    wire                 wr_resp_error, rd_resp_error;
    wire [ID_WIDTH-1:0]  wr_resp_error_id, rd_resp_error_id;

    axi4_master_top #(
        .ID_WIDTH(ID_WIDTH), .OUTSTANDING_DEPTH(4)
    ) master_dut (
        .clk(clk), .rst_n(rst_n),
        .cmd_valid(cmd_valid), .cmd_ready(cmd_ready), .cmd_op(cmd_op),
        .cmd_addr(cmd_addr), .cmd_len(cmd_len), .cmd_size(cmd_size),
        .cmd_burst(cmd_burst), .cmd_id(cmd_id),
        .awvalid(awvalid), .awready(awready), .awaddr(awaddr), .awlen(awlen),
        .awsize(awsize), .awburst(awburst), .awid(awid),
        .wvalid(wvalid), .wready(wready), .wdata(wdata), .wstrb(wstrb), .wlast(wlast),
        .wdata_in(wdata_in), .wstrb_in(wstrb_in),
        .bvalid(bvalid), .bready(bready), .bresp(bresp), .bid(bid),
        .arvalid(arvalid), .arready(arready), .araddr(araddr), .arlen(arlen),
        .arsize(arsize), .arburst(arburst), .arid(arid),
        .rvalid(rvalid), .rready(rready), .rdata(rdata), .rresp(rresp),
        .rlast(rlast), .rid(rid), .rdata_out(rdata_out), .rresp_out(rresp_out),
        .wr_resp_error(wr_resp_error), .wr_resp_error_id(wr_resp_error_id),
        .rd_resp_error(rd_resp_error), .rd_resp_error_id(rd_resp_error_id)
    );

    axi4_slave_top #(
        .ID_WIDTH(ID_WIDTH)
        // REGION_BASE/REGION_LIMIT left at default (Slave 0: 0x0000-0x0FFF)
    ) slave_dut (
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

    // -----------------------------------------------------------------
    // beat-data plumbing. AXI guarantees W beats arrive in the same
    // order AW was issued -- so a single monotonically-increasing
    // index, filled in program order and NEVER reset between commands
    // (only at simulation start), is the correct model even under
    // pipelined dispatch. A per-command reset (the earlier draft) races
    // under pipelining: resetting write #2's index while write #1's
    // beat is still in flight makes both writes fight over slot 0.
    // -----------------------------------------------------------------
    reg [31:0] wq_data [0:63];
    reg [3:0]  wq_strb [0:63];
    reg [6:0]  wq_fill_ptr;   // next free slot a test can queue into
    reg [6:0]  wr_beat_idx;   // consumption pointer -- monotonic, never reset

    reg [31:0] rq_data [0:63];
    reg [1:0]  rq_resp [0:63];
    reg [6:0]  rd_beat_idx;   // monotonic, same reasoning as wr_beat_idx

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) wr_beat_idx <= 7'd0;
        else if (wvalid && wready) wr_beat_idx <= wr_beat_idx + 7'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_beat_idx <= 7'd0;
        end else if (rvalid && rready) begin
            rq_data[rd_beat_idx] <= rdata_out;
            rq_resp[rd_beat_idx] <= rresp_out;
            rd_beat_idx <= rd_beat_idx + 7'd1;
        end
    end

    always @(*) begin
        wdata_in = wq_data[wr_beat_idx];
        wstrb_in = wq_strb[wr_beat_idx];
    end

    task queue_beat;
        input [31:0] data;
        input [3:0]  strb;
        begin
            wq_data[wq_fill_ptr] = data;
            wq_strb[wq_fill_ptr] = strb;
            wq_fill_ptr = wq_fill_ptr + 1;
        end
    endtask

    // -----------------------------------------------------------------
    // driver tasks
    // -----------------------------------------------------------------
    task issue_cmd;
        input [31:0]         addr;
        input [7:0]          len_beats;
        input [2:0]          size;
        input [1:0]          burst;
        input [ID_WIDTH-1:0] id;
        input                op;
        begin
            @(negedge clk);
            cmd_addr = addr; cmd_len = len_beats - 1; cmd_size = size;
            cmd_burst = burst; cmd_id = id; cmd_op = op;
            cmd_valid = 1'b1;
            @(posedge clk);
            while (!cmd_ready) @(posedge clk);
            @(negedge clk);
            cmd_valid = 1'b0;
        end
    endtask

    // blocking do_write: issues the cmd, then waits for the B response
    // (bvalid&&bready). Captures bresp/wr_resp_error at the EXACT
    // completion cycle -- checking these after the task returns is too
    // late, since wr_complete_valid (and hence wr_resp_error) is only
    // high for that one cycle, and the state has already moved on to
    // IDLE by the time control returns to the caller.
    task do_write;
        input [31:0]         addr;
        input [7:0]          len_beats;
        input [2:0]          size;
        input [1:0]          burst;
        input [ID_WIDTH-1:0] id;
        output [1:0]         captured_bresp;
        output               captured_wr_err;
        begin
            issue_cmd(addr, len_beats, size, burst, id, `CMD_OP_WRITE);
            @(posedge clk);
            while (!(bvalid && bready)) @(posedge clk);
            captured_bresp = bresp;
            captured_wr_err = wr_resp_error;
            @(negedge clk);
        end
    endtask

    // blocking do_read: issues the cmd, records where in the global
    // rq_data/rq_resp queue this read's beats will land (rd_beat_idx is
    // monotonic and never reset), waits for the last R beat, and
    // captures rd_resp_error at that exact cycle for the same reason.
    task do_read;
        input [31:0]         addr;
        input [7:0]          len_beats;
        input [2:0]          size;
        input [1:0]          burst;
        input [ID_WIDTH-1:0] id;
        output [6:0]         start_idx;
        output               captured_rd_err;
        begin
            start_idx = rd_beat_idx;
            issue_cmd(addr, len_beats, size, burst, id, `CMD_OP_READ);
            @(posedge clk);
            while (!(rvalid && rready && rlast)) @(posedge clk);
            captured_rd_err = rd_resp_error;
            @(negedge clk);
        end
    endtask

    // -----------------------------------------------------------------
    // test sequence
    // -----------------------------------------------------------------
    reg [1:0] cap_bresp;
    reg       cap_wr_err, cap_rd_err;
    reg [6:0] r_idx;

    initial begin
        clk = 0; rst_n = 0;
        cmd_valid = 0; cmd_op = 0; cmd_addr = 0; cmd_len = 0;
        cmd_size = 0; cmd_burst = 0; cmd_id = 0;
        wq_fill_ptr = 0;
        @(negedge clk); @(negedge clk);
        rst_n = 1;
        @(negedge clk);

        // --- Test 1: single-beat write + read-back ---
        $display("--- Test 1: single-beat write + read-back ---");
        queue_beat(32'hCAFEBABE, 4'b1111);
        do_write(32'h0000_0010, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd1, cap_bresp, cap_wr_err);
        check2("T1 bresp OKAY", cap_bresp, `AXI_RESP_OKAY);
        check1("T1 no wr_resp_error", cap_wr_err, 1'b0);
        do_read(32'h0000_0010, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd1, r_idx, cap_rd_err);
        check32("T1 read-back matches write", rq_data[r_idx], 32'hCAFEBABE);
        check2("T1 rresp OKAY", rq_resp[r_idx], `AXI_RESP_OKAY);
        check1("T1 no rd_resp_error", cap_rd_err, 1'b0);

        // --- Test 2: 4-beat INCR burst write, then read back ---
        $display("--- Test 2: 4-beat INCR burst ---");
        queue_beat(32'h1111_1111, 4'b1111);
        queue_beat(32'h2222_2222, 4'b1111);
        queue_beat(32'h3333_3333, 4'b1111);
        queue_beat(32'h4444_4444, 4'b1111);
        do_write(32'h0000_0100, 8'd4, 3'd2, `AXI_BURST_INCR, 4'd2, cap_bresp, cap_wr_err);
        check2("T2 bresp OKAY", cap_bresp, `AXI_RESP_OKAY);
        do_read(32'h0000_0100, 8'd4, 3'd2, `AXI_BURST_INCR, 4'd2, r_idx, cap_rd_err);
        check32("T2 beat0", rq_data[r_idx+0], 32'h1111_1111);
        check32("T2 beat1", rq_data[r_idx+1], 32'h2222_2222);
        check32("T2 beat2", rq_data[r_idx+2], 32'h3333_3333);
        check32("T2 beat3", rq_data[r_idx+3], 32'h4444_4444);

        // --- Test 3: WRAP burst write + read-back end-to-end ---
        $display("--- Test 3: WRAP burst ---");
        queue_beat(32'hA000, 4'b1111);
        queue_beat(32'hB000, 4'b1111);
        queue_beat(32'hC000, 4'b1111);
        queue_beat(32'hD000, 4'b1111);
        do_write(32'h0000_0008, 8'd4, 3'd2, `AXI_BURST_WRAP, 4'd3, cap_bresp, cap_wr_err); // window 0x0000-0x000F
        check2("T3 bresp OKAY", cap_bresp, `AXI_RESP_OKAY);
        do_read(32'h0000_0000, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd3, r_idx, cap_rd_err);
        check32("T3 addr 0x0 got beat2 data", rq_data[r_idx], 32'hC000);
        do_read(32'h0000_0004, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd3, r_idx, cap_rd_err);
        check32("T3 addr 0x4 got beat3 data", rq_data[r_idx], 32'hD000);
        do_read(32'h0000_0008, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd3, r_idx, cap_rd_err);
        check32("T3 addr 0x8 got beat0 data", rq_data[r_idx], 32'hA000);
        do_read(32'h0000_000C, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd3, r_idx, cap_rd_err);
        check32("T3 addr 0xC got beat1 data", rq_data[r_idx], 32'hB000);

        // --- Test 4: out-of-region write -> DECERR surfaces through
        //     the master's own wr_resp_error diagnostic, captured at
        //     the exact completion cycle, not read after the fact ---
        $display("--- Test 4: out-of-region write, check wr_resp_error ---");
        queue_beat(32'hDEAD_DEAD, 4'b1111);
        do_write(32'h0000_2000, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd4, cap_bresp, cap_wr_err); // outside 0x0FFF limit
        check2("T4 bresp DECERR", cap_bresp, `AXI_RESP_DECERR);
        check1("T4 wr_resp_error asserted", cap_wr_err, 1'b1);

        // --- Test 5: pipelined dispatch -- issue a second write's
        //     command before the first has completed. Data for both is
        //     queued in program order BEFORE either issue_cmd fires, so
        //     the monotonic consumption index lines up correctly with
        //     AXI's own W-must-follow-AW-order guarantee, regardless of
        //     how the two dispatches interleave underneath. ---
        $display("--- Test 5: back-to-back cmd dispatch (pipelining) ---");
        queue_beat(32'h5555_0001, 4'b1111); // write A's beat
        queue_beat(32'h5555_0002, 4'b1111); // write B's beat
        issue_cmd(32'h0000_0300, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd5, `CMD_OP_WRITE);
        issue_cmd(32'h0000_0304, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd6, `CMD_OP_WRITE);
        // drain both B responses before checking final memory state
        repeat (30) @(posedge clk);
        do_read(32'h0000_0300, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd5, r_idx, cap_rd_err);
        check32("T5 first pipelined write landed", rq_data[r_idx], 32'h5555_0001);
        do_read(32'h0000_0304, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd6, r_idx, cap_rd_err);
        check32("T5 second pipelined write landed", rq_data[r_idx], 32'h5555_0002);

        #20;
        $display("=================================================");
        $display("TOTAL: %0d passed, %0d failed", pass_count, fail_count);
        $display("=================================================");
        $finish;
    end

endmodule
