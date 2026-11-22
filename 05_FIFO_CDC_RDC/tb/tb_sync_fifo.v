`timescale 1ns/1ps
module tb_sync_fifo;
    parameter DW = 8, AW = 4, NCYC = 60000;
    localparam DEPTH = 1 << AW;

    reg clk = 0, rst_n = 0, wr_en = 0, rd_en = 0;
    reg  [DW-1:0] wdata = 0;
    wire [DW-1:0] rdata;
    wire full, empty, almost_full, almost_empty;
    wire [AW:0] count;

    sync_fifo #(.DW(DW), .AW(AW), .ALMOST(2)) dut (
        .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en), .wdata(wdata),
        .rdata(rdata), .full(full), .empty(empty),
        .almost_full(almost_full), .almost_empty(almost_empty), .count(count));

    always #5 clk = ~clk;

    reg [DW-1:0] model [0:DEPTH-1];
    integer m_wr = 0, m_rd = 0, occ, cyc = 0, errors = 0, checks = 0;
    integer wp, rp, n_full = 0, n_empty = 0;
    reg do_wr, do_rd;

    always @(posedge clk) if (rst_n) begin
        occ = m_wr - m_rd;
        // flag checks (values seen just before this edge)
        checks = checks + 4;
        if (full         !== (occ == DEPTH))      begin errors = errors + 1; $display("%0t FULL mismatch occ=%0d", $time, occ); end
        if (empty        !== (occ == 0))          begin errors = errors + 1; $display("%0t EMPTY mismatch occ=%0d", $time, occ); end
        if (count        !== occ)                 begin errors = errors + 1; $display("%0t COUNT mismatch %0d vs %0d", $time, count, occ); end
        if (almost_full  !== (occ >= DEPTH - 2))  begin errors = errors + 1; $display("%0t ALMOST_FULL mismatch", $time); end
        if (occ == DEPTH) n_full  = n_full + 1;
        if (occ == 0)     n_empty = n_empty + 1;

        do_rd = rd_en && (occ > 0);
        do_wr = wr_en && (occ < DEPTH);
        if (do_rd) begin
            checks = checks + 1;
            if (rdata !== model[m_rd % DEPTH]) begin
                errors = errors + 1;
                $display("%0t DATA mismatch got %h exp %h", $time, rdata, model[m_rd % DEPTH]);
            end
            m_rd = m_rd + 1;
        end
        if (do_wr) begin model[m_wr % DEPTH] = wdata; m_wr = m_wr + 1; end

        // new stimulus; the write/read probabilities change every 2000 cycles
        cyc = cyc + 1;
        case ((cyc / 2000) % 3)
            0: begin wp = 85; rp = 20; end   // fill  -> hits full
            1: begin wp = 20; rp = 85; end   // drain -> hits empty
            default: begin wp = 50; rp = 50; end
        endcase
        wr_en <= ({$random} % 100) < wp;
        rd_en <= ({$random} % 100) < rp;
        wdata <= $random;
    end

    initial begin
        #23 rst_n = 1;
        wait (cyc >= NCYC);
        $display("sync_fifo: checks=%0d errors=%0d writes=%0d reads=%0d full_cycles=%0d empty_cycles=%0d",
                 checks, errors, m_wr, m_rd, n_full, n_empty);
        if (errors == 0 && n_full > 0 && n_empty > 0) $display("PASS"); else $display("FAIL");
        $finish;
    end
endmodule
