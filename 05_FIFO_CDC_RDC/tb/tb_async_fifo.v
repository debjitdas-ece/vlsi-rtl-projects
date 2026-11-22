`timescale 1ps/1ps
// Random-ratio async FIFO test. Half-periods are in ps so odd ratios work.
//   vvp ... +WHALF=5000 +RHALF=7300 +WPROB=70 +RPROB=40 +NUM=20000 +SEED=1
module tb_async_fifo;
    parameter DW = 8, AW = 4, SKEW = 0;

    integer WHALF = 5000, RHALF = 7300, WPROB = 70, RPROB = 40, NUM = 20000, SEED = 1;
    integer seed_w, seed_r;

    reg wclk = 0, rclk = 0, wrst_n = 0, rrst_n = 0;
    reg winc = 0, rinc = 0;
    reg [DW-1:0] wdata = 0;
    wire [DW-1:0] rdata;
    wire wfull, rempty;

    async_fifo #(.DW(DW), .AW(AW), .SKEW(SKEW)) dut (
        .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wdata(wdata), .wfull(wfull),
        .rclk(rclk), .rrst_n(rrst_n), .rinc(rinc), .rdata(rdata), .rempty(rempty));

    initial begin
        if (!$value$plusargs("WHALF=%d", WHALF)) ;
        if (!$value$plusargs("RHALF=%d", RHALF)) ;
        if (!$value$plusargs("WPROB=%d", WPROB)) ;
        if (!$value$plusargs("RPROB=%d", RPROB)) ;
        if (!$value$plusargs("NUM=%d",   NUM))   ;
        if (!$value$plusargs("SEED=%d",  SEED))  ;
        seed_w = SEED * 7 + 1;
        seed_r = SEED * 13 + 5;
        fork
            forever #(WHALF) wclk = ~wclk;
            begin #(RHALF/3) forever #(RHALF) rclk = ~rclk; end   // arbitrary phase offset
            begin #(4*WHALF + 1) wrst_n = 1; end
            begin #(5*RHALF + 7) rrst_n = 1; end                  // resets released at different times
        join
    end

    reg [DW-1:0] exp_mem [0:200000];
    integer wr_cnt = 0, rd_cnt = 0, errors = 0, saw_full = 0, saw_empty = 0;

    always @(posedge wclk) if (wrst_n) begin
        if (winc && !wfull) begin exp_mem[wr_cnt] = wdata; wr_cnt = wr_cnt + 1; end
        if (wfull) saw_full = saw_full + 1;
        winc  <= (wr_cnt < NUM) && ((($random(seed_w)) & 32'h7fffffff) % 100 < WPROB);
        wdata <= $random(seed_w);
    end

    always @(posedge rclk) if (rrst_n) begin
        if (rinc && !rempty) begin
            if (rd_cnt >= wr_cnt) begin
                errors = errors + 1; $display("%0t UNDERFLOW: read with nothing written", $time);
            end else if (rdata !== exp_mem[rd_cnt]) begin
                errors = errors + 1;
                if (errors < 10) $display("%0t DATA mismatch idx=%0d got %h exp %h", $time, rd_cnt, rdata, exp_mem[rd_cnt]);
            end
            rd_cnt = rd_cnt + 1;
        end
        if (rempty) saw_empty = saw_empty + 1;
        rinc <= ((($random(seed_r)) & 32'h7fffffff) % 100 < RPROB);
    end

    initial begin
        wait (rd_cnt >= NUM);
        #(20*WHALF);
        $display("async_fifo: WHALF=%0d RHALF=%0d WPROB=%0d RPROB=%0d SKEW=%0d written=%0d read=%0d errors=%0d full_cyc=%0d empty_cyc=%0d",
                 WHALF, RHALF, WPROB, RPROB, SKEW, wr_cnt, rd_cnt, errors, saw_full, saw_empty);
        if (errors == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end

    // watchdog
    initial begin #(400*1000*1000*1000.0); $display("TIMEOUT rd=%0d wr=%0d", rd_cnt, wr_cnt); $display("FAIL"); $finish; end
endmodule
