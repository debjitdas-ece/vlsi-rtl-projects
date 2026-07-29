`include "rtl/common/axi_pkg.v"

module tb_axi_common;

    integer pass_count = 0;
    integer fail_count = 0;

    task check;
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

    // =================================================================
    // Section A: axi_burst_calc
    // =================================================================
    reg  [31:0] bc_addr_in;
    reg  [2:0]  bc_size;
    reg  [7:0]  bc_len;
    reg  [1:0]  bc_burst_type;
    wire [31:0] bc_addr_out;

    axi_burst_calc burst_calc_dut (
        .addr_in    (bc_addr_in),
        .size       (bc_size),
        .len        (bc_len),
        .burst_type (bc_burst_type),
        .addr_out   (bc_addr_out)
    );

    task bc_apply;
        input [31:0] addr_in;
        input [2:0]  size;
        input [7:0]  len;
        input [1:0]  burst_type;
        begin
            bc_addr_in    = addr_in;
            bc_size       = size;
            bc_len        = len;
            bc_burst_type = burst_type;
            #1;
        end
    endtask

    task test_burst_calc;
        begin
            $display("--- axi_burst_calc ---");

            bc_apply(32'h0000_1000, 3'd2, 8'd7, `AXI_BURST_FIXED);
            check32("FIXED holds addr", bc_addr_out, 32'h0000_1000);

            bc_apply(32'h0000_2000, 3'd2, 8'd3, `AXI_BURST_INCR);
            check32("INCR +4 step", bc_addr_out, 32'h0000_2004);

            bc_apply(32'h0000_0FFE, 3'd0, 8'd0, `AXI_BURST_INCR);
            check32("INCR crosses 4KB, still adds", bc_addr_out, 32'h0000_0FFF);

            bc_apply(32'h0000_1008, 3'd2, 8'd3, `AXI_BURST_WRAP);
            check32("WRAP beat0", bc_addr_out, 32'h0000_100C);
            bc_apply(32'h0000_100C, 3'd2, 8'd3, `AXI_BURST_WRAP);
            check32("WRAP beat1 (wraps)", bc_addr_out, 32'h0000_1000);
            bc_apply(32'h0000_1000, 3'd2, 8'd3, `AXI_BURST_WRAP);
            check32("WRAP beat2", bc_addr_out, 32'h0000_1004);
            bc_apply(32'h0000_1004, 3'd2, 8'd3, `AXI_BURST_WRAP);
            check32("WRAP beat3 (lands back at start)", bc_addr_out, 32'h0000_1008);

            bc_apply(32'h0000_2004, 3'd2, 8'd1, `AXI_BURST_WRAP);
            check32("WRAP len=1 wraps at window edge", bc_addr_out, 32'h0000_2000);

            bc_apply(32'h0000_301C, 3'd2, 8'd7, `AXI_BURST_WRAP);
            check32("WRAP len=7 wraps at window edge", bc_addr_out, 32'h0000_3000);

            bc_apply(32'h0000_403C, 3'd2, 8'd15, `AXI_BURST_WRAP);
            check32("WRAP len=15 wraps at window edge", bc_addr_out, 32'h0000_4000);

            bc_apply(32'h0000_5000, 3'd2, 8'd3, 2'b11);
            check32("reserved burst_type fallback", bc_addr_out, 32'h0000_5000);
        end
    endtask

    // =================================================================
    // Section B: axi_id_tracker
    // =================================================================
    localparam TRK_ID_WIDTH = 4;
    localparam TRK_DEPTH    = 4;

    reg                        it_clk, it_rst_n;
    reg                        it_issue_valid, it_complete_valid;
    reg  [TRK_ID_WIDTH-1:0]    it_issue_id, it_complete_id;
    wire                       it_issue_ready;

    axi_id_tracker #(
        .ID_WIDTH(TRK_ID_WIDTH),
        .DEPTH   (TRK_DEPTH)
    ) id_tracker_dut (
        .clk            (it_clk),
        .rst_n          (it_rst_n),
        .issue_valid    (it_issue_valid),
        .issue_id       (it_issue_id),
        .issue_ready    (it_issue_ready),
        .complete_valid (it_complete_valid),
        .complete_id    (it_complete_id)
    );

    always #5 it_clk = ~it_clk;

    task it_complete_one;
        input [TRK_ID_WIDTH-1:0] id;
        begin
            @(negedge it_clk);
            it_complete_id    = id;
            it_complete_valid = 1'b1;
            @(posedge it_clk);
            #1;
            @(negedge it_clk);
            it_complete_valid = 1'b0;
        end
    endtask

    task test_id_tracker;
        integer i;
        begin
            $display("--- axi_id_tracker ---");

            it_clk = 0; it_rst_n = 0;
            it_issue_valid = 0; it_complete_valid = 0;
            it_issue_id = 0; it_complete_id = 0;
            @(negedge it_clk); @(negedge it_clk);
            it_rst_n = 1;

            // Fill ID 3 to depth (4 issues). issue_valid MUST be high
            // before checking issue_ready, since issue_ready is defined
            // as (issue_valid && count<DEPTH) -- checking with valid=0
            // always reads back 0 regardless of the real count.
            for (i = 0; i < TRK_DEPTH; i = i + 1) begin
                @(negedge it_clk);
                it_issue_id    = 4'd3;
                it_issue_valid = 1'b1;
                #1;
                check("ready before issue", it_issue_ready, 1'b1);
                @(posedge it_clk);
                #1;
                @(negedge it_clk);
                it_issue_valid = 1'b0;
            end

            @(negedge it_clk);
            it_issue_id    = 4'd3;
            it_issue_valid = 1'b1;
            #1;
            check("depth-4 ID3 now full, ready must drop", it_issue_ready, 1'b0);
            it_issue_valid = 1'b0;

            @(negedge it_clk);
            it_issue_id    = 4'd7;
            it_issue_valid = 1'b1;
            #1;
            check("different ID (7) unaffected by ID3 being full", it_issue_ready, 1'b1);
            it_issue_valid = 1'b0;

            it_complete_one(4'd3);
            @(negedge it_clk);
            it_issue_id    = 4'd3;
            it_issue_valid = 1'b1;
            #1;
            check("ID3 reopens after one complete", it_issue_ready, 1'b1);
            it_issue_valid = 1'b0;

            it_issue_id = 4'd5;
            for (i = 0; i < TRK_DEPTH - 1; i = i + 1) begin
                @(negedge it_clk);
                it_issue_valid = 1'b1;
                @(posedge it_clk);
                #1;
                @(negedge it_clk);
                it_issue_valid = 1'b0;
            end

            @(negedge it_clk);
            it_issue_id       = 4'd5;
            it_complete_id    = 4'd5;
            it_issue_valid    = 1'b1;
            it_complete_valid = 1'b1;
            @(posedge it_clk);
            #1;
            @(negedge it_clk);
            it_issue_valid    = 1'b0;
            it_complete_valid = 1'b0;

            @(negedge it_clk);
            it_issue_id    = 4'd5;
            it_issue_valid = 1'b1;
            #1;
            check("ID5 same-cycle issue+complete -> net unchanged, still has room", it_issue_ready, 1'b1);
            it_issue_valid = 1'b0;

            @(negedge it_clk);
            it_rst_n = 1'b0;
            @(negedge it_clk);
            it_rst_n = 1'b1;

            for (i = 0; i < TRK_DEPTH; i = i + 1) begin
                @(negedge it_clk);
                it_issue_id    = 4'd3;
                it_issue_valid = 1'b1;
                #1;
                check("post-reset refill accepted", it_issue_ready, 1'b1);
                @(posedge it_clk);
                #1;
                @(negedge it_clk);
                it_issue_valid = 1'b0;
            end
        end
    endtask

    initial begin
        test_burst_calc;
        test_id_tracker;
        #20;
        $display("=================================================");
        $display("TOTAL: %0d passed, %0d failed", pass_count, fail_count);
        $display("=================================================");
        $finish;
    end

endmodule
