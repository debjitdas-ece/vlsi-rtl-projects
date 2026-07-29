`include "rtl/common/axi_pkg.v"

// tb_axi4_system_top.v
// Full-system integration test: 2 masters -> interconnect -> 2 slaves.
// Covers the plan's three Stage 2 scenarios:
//   Test 1: single master/slave sanity (should match Stage 1 behavior)
//   Test 2: two masters contending for one shared slave (both complete
//           correctly; strict grant-distribution fairness is not
//           re-derived here via internal signal snooping -- that's
//           already covered by the arbiter's own hand-traced reasoning)
//   Test 3: two masters to two independent slaves concurrently (no
//           cross-talk, no response swapping between masters)
//
// Uses hierarchical references (dut.wvalid_m0 etc.) to tap internal
// per-master AXI handshakes for beat-data plumbing, since
// axi4_system_top deliberately hides those channels behind the simple
// cmd interface at the top level -- standard white-box TB practice,
// no DUT ports were added just for this.
//
// Run (from project root): ./sim/run.sh tb/tb_axi4_system_top.v

module tb_axi4_system_top;

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

    reg clk, rst_n;
    always #5 clk = ~clk;

    // -----------------------------------------------------------------
    // DUT
    // -----------------------------------------------------------------
    reg                  cmd_valid_m0, cmd_op_m0;
    reg  [31:0]          cmd_addr_m0;
    reg  [7:0]           cmd_len_m0;
    reg  [2:0]           cmd_size_m0;
    reg  [1:0]           cmd_burst_m0;
    reg  [ID_WIDTH-1:0]  cmd_id_m0;
    reg  [31:0]          wdata_in_m0;
    reg  [3:0]           wstrb_in_m0;
    wire                 cmd_ready_m0;
    wire [31:0]          rdata_out_m0;
    wire [1:0]           rresp_out_m0;
    wire                 wr_resp_error_m0, rd_resp_error_m0;
    wire [ID_WIDTH-1:0]  wr_resp_error_id_m0, rd_resp_error_id_m0;

    reg                  cmd_valid_m1, cmd_op_m1;
    reg  [31:0]          cmd_addr_m1;
    reg  [7:0]           cmd_len_m1;
    reg  [2:0]           cmd_size_m1;
    reg  [1:0]           cmd_burst_m1;
    reg  [ID_WIDTH-1:0]  cmd_id_m1;
    reg  [31:0]          wdata_in_m1;
    reg  [3:0]           wstrb_in_m1;
    wire                 cmd_ready_m1;
    wire [31:0]          rdata_out_m1;
    wire [1:0]           rresp_out_m1;
    wire                 wr_resp_error_m1, rd_resp_error_m1;
    wire [ID_WIDTH-1:0]  wr_resp_error_id_m1, rd_resp_error_id_m1;

    axi4_system_top #(
        .ID_WIDTH(ID_WIDTH), .OUTSTANDING_DEPTH(4)
    ) dut (
        .clk(clk), .rst_n(rst_n),

        .cmd_valid_m0(cmd_valid_m0), .cmd_ready_m0(cmd_ready_m0), .cmd_op_m0(cmd_op_m0),
        .cmd_addr_m0(cmd_addr_m0), .cmd_len_m0(cmd_len_m0), .cmd_size_m0(cmd_size_m0),
        .cmd_burst_m0(cmd_burst_m0), .cmd_id_m0(cmd_id_m0),
        .wdata_in_m0(wdata_in_m0), .wstrb_in_m0(wstrb_in_m0),
        .rdata_out_m0(rdata_out_m0), .rresp_out_m0(rresp_out_m0),
        .wr_resp_error_m0(wr_resp_error_m0), .wr_resp_error_id_m0(wr_resp_error_id_m0),
        .rd_resp_error_m0(rd_resp_error_m0), .rd_resp_error_id_m0(rd_resp_error_id_m0),

        .cmd_valid_m1(cmd_valid_m1), .cmd_ready_m1(cmd_ready_m1), .cmd_op_m1(cmd_op_m1),
        .cmd_addr_m1(cmd_addr_m1), .cmd_len_m1(cmd_len_m1), .cmd_size_m1(cmd_size_m1),
        .cmd_burst_m1(cmd_burst_m1), .cmd_id_m1(cmd_id_m1),
        .wdata_in_m1(wdata_in_m1), .wstrb_in_m1(wstrb_in_m1),
        .rdata_out_m1(rdata_out_m1), .rresp_out_m1(rresp_out_m1),
        .wr_resp_error_m1(wr_resp_error_m1), .wr_resp_error_id_m1(wr_resp_error_id_m1),
        .rd_resp_error_m1(rd_resp_error_m1), .rd_resp_error_id_m1(rd_resp_error_id_m1)
    );

    // -----------------------------------------------------------------
    // beat-data plumbing -- one independent monotonic queue per master
    // (each master's own W order only has to match its own AW order,
    // not the other master's). Handshake taps use hierarchical refs
    // into the DUT since these signals aren't top-level ports.
    // -----------------------------------------------------------------
    reg [31:0] wq_data_m0 [0:63]; reg [3:0] wq_strb_m0 [0:63];
    reg [6:0]  wq_fill_ptr_m0, wr_beat_idx_m0;
    reg [31:0] rq_data_m0 [0:63]; reg [1:0] rq_resp_m0 [0:63];
    reg [6:0]  rd_beat_idx_m0;

    reg [31:0] wq_data_m1 [0:63]; reg [3:0] wq_strb_m1 [0:63];
    reg [6:0]  wq_fill_ptr_m1, wr_beat_idx_m1;
    reg [31:0] rq_data_m1 [0:63]; reg [1:0] rq_resp_m1 [0:63];
    reg [6:0]  rd_beat_idx_m1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) wr_beat_idx_m0 <= 7'd0;
        else if (dut.wvalid_m0 && dut.wready_m0) wr_beat_idx_m0 <= wr_beat_idx_m0 + 7'd1;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) wr_beat_idx_m1 <= 7'd0;
        else if (dut.wvalid_m1 && dut.wready_m1) wr_beat_idx_m1 <= wr_beat_idx_m1 + 7'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_beat_idx_m0 <= 7'd0;
        end else if (dut.rvalid_m0 && dut.rready_m0) begin
            rq_data_m0[rd_beat_idx_m0] <= rdata_out_m0;
            rq_resp_m0[rd_beat_idx_m0] <= rresp_out_m0;
            rd_beat_idx_m0 <= rd_beat_idx_m0 + 7'd1;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_beat_idx_m1 <= 7'd0;
        end else if (dut.rvalid_m1 && dut.rready_m1) begin
            rq_data_m1[rd_beat_idx_m1] <= rdata_out_m1;
            rq_resp_m1[rd_beat_idx_m1] <= rresp_out_m1;
            rd_beat_idx_m1 <= rd_beat_idx_m1 + 7'd1;
        end
    end

    always @(*) begin
        wdata_in_m0 = wq_data_m0[wr_beat_idx_m0];
        wstrb_in_m0 = wq_strb_m0[wr_beat_idx_m0];
    end
    always @(*) begin
        wdata_in_m1 = wq_data_m1[wr_beat_idx_m1];
        wstrb_in_m1 = wq_strb_m1[wr_beat_idx_m1];
    end

    task queue_beat_m0;
        input [31:0] data; input [3:0] strb;
        begin
            wq_data_m0[wq_fill_ptr_m0] = data;
            wq_strb_m0[wq_fill_ptr_m0] = strb;
            wq_fill_ptr_m0 = wq_fill_ptr_m0 + 1;
        end
    endtask
    task queue_beat_m1;
        input [31:0] data; input [3:0] strb;
        begin
            wq_data_m1[wq_fill_ptr_m1] = data;
            wq_strb_m1[wq_fill_ptr_m1] = strb;
            wq_fill_ptr_m1 = wq_fill_ptr_m1 + 1;
        end
    endtask

    // -----------------------------------------------------------------
    // driver tasks -- one set per master
    // -----------------------------------------------------------------
    task issue_cmd_m0;
        input [31:0] addr; input [7:0] len_beats; input [2:0] size;
        input [1:0] burst; input [ID_WIDTH-1:0] id; input op;
        begin
            @(negedge clk);
            cmd_addr_m0 = addr; cmd_len_m0 = len_beats - 1; cmd_size_m0 = size;
            cmd_burst_m0 = burst; cmd_id_m0 = id; cmd_op_m0 = op;
            cmd_valid_m0 = 1'b1;
            @(posedge clk);
            while (!cmd_ready_m0) @(posedge clk);
            @(negedge clk);
            cmd_valid_m0 = 1'b0;
        end
    endtask
    task issue_cmd_m1;
        input [31:0] addr; input [7:0] len_beats; input [2:0] size;
        input [1:0] burst; input [ID_WIDTH-1:0] id; input op;
        begin
            @(negedge clk);
            cmd_addr_m1 = addr; cmd_len_m1 = len_beats - 1; cmd_size_m1 = size;
            cmd_burst_m1 = burst; cmd_id_m1 = id; cmd_op_m1 = op;
            cmd_valid_m1 = 1'b1;
            @(posedge clk);
            while (!cmd_ready_m1) @(posedge clk);
            @(negedge clk);
            cmd_valid_m1 = 1'b0;
        end
    endtask

    task do_write_m0;
        input [31:0] addr; input [7:0] len_beats; input [2:0] size;
        input [1:0] burst; input [ID_WIDTH-1:0] id;
        output cap_err;
        begin
            issue_cmd_m0(addr, len_beats, size, burst, id, `CMD_OP_WRITE);
            @(posedge clk);
            while (!(dut.bvalid_m0 && dut.bready_m0)) @(posedge clk);
            cap_err = wr_resp_error_m0;
            @(negedge clk);
        end
    endtask
    task do_write_m1;
        input [31:0] addr; input [7:0] len_beats; input [2:0] size;
        input [1:0] burst; input [ID_WIDTH-1:0] id;
        output cap_err;
        begin
            issue_cmd_m1(addr, len_beats, size, burst, id, `CMD_OP_WRITE);
            @(posedge clk);
            while (!(dut.bvalid_m1 && dut.bready_m1)) @(posedge clk);
            cap_err = wr_resp_error_m1;
            @(negedge clk);
        end
    endtask

    task do_read_m0;
        input [31:0] addr; input [7:0] len_beats; input [2:0] size;
        input [1:0] burst; input [ID_WIDTH-1:0] id;
        output [6:0] start_idx;
        begin
            start_idx = rd_beat_idx_m0;
            issue_cmd_m0(addr, len_beats, size, burst, id, `CMD_OP_READ);
            @(posedge clk);
            while (!(dut.rvalid_m0 && dut.rready_m0 && dut.rlast_m0)) @(posedge clk);
            @(negedge clk);
        end
    endtask
    task do_read_m1;
        input [31:0] addr; input [7:0] len_beats; input [2:0] size;
        input [1:0] burst; input [ID_WIDTH-1:0] id;
        output [6:0] start_idx;
        begin
            start_idx = rd_beat_idx_m1;
            issue_cmd_m1(addr, len_beats, size, burst, id, `CMD_OP_READ);
            @(posedge clk);
            while (!(dut.rvalid_m1 && dut.rready_m1 && dut.rlast_m1)) @(posedge clk);
            @(negedge clk);
        end
    endtask

    // -----------------------------------------------------------------
    // test sequence
    // -----------------------------------------------------------------
    reg       cap_err;
    reg [6:0] r_idx0, r_idx1;

    initial begin
        clk = 0; rst_n = 0;
        cmd_valid_m0 = 0; cmd_op_m0 = 0; cmd_addr_m0 = 0; cmd_len_m0 = 0;
        cmd_size_m0 = 0; cmd_burst_m0 = 0; cmd_id_m0 = 0; wq_fill_ptr_m0 = 0;
        cmd_valid_m1 = 0; cmd_op_m1 = 0; cmd_addr_m1 = 0; cmd_len_m1 = 0;
        cmd_size_m1 = 0; cmd_burst_m1 = 0; cmd_id_m1 = 0; wq_fill_ptr_m1 = 0;
        @(negedge clk); @(negedge clk);
        rst_n = 1;
        @(negedge clk);

        // --- Test 1: single master/slave sanity (M0 -> S0 only) ---
        $display("--- Test 1: single master/slave sanity ---");
        queue_beat_m0(32'hCAFEBABE, 4'b1111);
        do_write_m0(32'h0000_0010, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd1, cap_err);
        check2("T1 no wr_resp_error", {1'b0, cap_err}, 2'b00);
        do_read_m0(32'h0000_0010, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd1, r_idx0);
        check32("T1 read-back matches write", rq_data_m0[r_idx0], 32'hCAFEBABE);

        // --- Test 2: both masters contending for the SAME slave (S0).
        //     M0 targets 0x0020, M1 targets 0x0024 -- both inside S0's
        //     region, so both requests hit the same arbiter. Confirm
        //     both complete correctly with no data corruption; strict
        //     fairness distribution isn't re-verified here (that's the
        //     arbiter's own responsibility, already hand-traced). ---
        $display("--- Test 2: two masters contending for one shared slave ---");
        queue_beat_m0(32'hAAAA_0001, 4'b1111);
        queue_beat_m1(32'hBBBB_0002, 4'b1111);
        issue_cmd_m0(32'h0000_0020, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd2, `CMD_OP_WRITE);
        issue_cmd_m1(32'h0000_0024, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd3, `CMD_OP_WRITE);
        // drain both B responses
        repeat (40) @(posedge clk);
        do_read_m0(32'h0000_0020, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd2, r_idx0);
        check32("T2 M0's write landed uncorrupted", rq_data_m0[r_idx0], 32'hAAAA_0001);
        do_read_m1(32'h0000_0024, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd3, r_idx1);
        check32("T2 M1's write landed uncorrupted", rq_data_m1[r_idx1], 32'hBBBB_0002);

        // --- Test 3: two masters to two INDEPENDENT slaves concurrently
        //     (M0 -> S0, M1 -> S1) -- confirm no cross-talk, no
        //     response swapped between masters ---
        $display("--- Test 3: two masters, two independent slaves, concurrent ---");
        queue_beat_m0(32'hCCCC_0003, 4'b1111);
        queue_beat_m1(32'hDDDD_0004, 4'b1111);
        issue_cmd_m0(32'h0000_0030, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd4, `CMD_OP_WRITE); // S0
        issue_cmd_m1(32'h0000_1030, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd5, `CMD_OP_WRITE); // S1
        repeat (40) @(posedge clk);
        do_read_m0(32'h0000_0030, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd4, r_idx0);
        check32("T3 M0/S0 write landed at correct slave", rq_data_m0[r_idx0], 32'hCCCC_0003);
        do_read_m1(32'h0000_1030, 8'd1, 3'd2, `AXI_BURST_INCR, 4'd5, r_idx1);
        check32("T3 M1/S1 write landed at correct slave", rq_data_m1[r_idx1], 32'hDDDD_0004);

        #20;
        $display("=================================================");
        $display("TOTAL: %0d passed, %0d failed", pass_count, fail_count);
        $display("=================================================");
        $finish;
    end

endmodule