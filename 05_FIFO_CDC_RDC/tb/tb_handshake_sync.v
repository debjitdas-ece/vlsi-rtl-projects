`timescale 1ps/1ps
module tb_handshake_sync;
    parameter DW = 16, N = 300;
    reg sclk = 0, dclk = 0, srst_n = 0, drst_n = 0;
    always #5000 sclk = ~sclk;
    always #8300 dclk = ~dclk;
    initial begin #40000 srst_n = 1; #12345 drst_n = 1; end

    reg src_valid = 0; reg [DW-1:0] src_data = 0; wire src_ready, dst_valid; wire [DW-1:0] dst_data;
    handshake_sync #(.DW(DW)) dut (.src_clk(sclk), .src_rst_n(srst_n), .src_valid(src_valid),
        .src_data(src_data), .src_ready(src_ready), .dst_clk(dclk), .dst_rst_n(drst_n),
        .dst_valid(dst_valid), .dst_data(dst_data));

    reg [DW-1:0] sent [0:N-1];
    integer ns = 0, nr = 0, errors = 0;

    always @(posedge sclk) if (srst_n && drst_n) begin
        if (src_valid && src_ready) begin sent[ns] = src_data; ns = ns + 1; src_valid <= 0; end
        else if (!src_valid && src_ready && ns < N && ({$random} % 3 == 0)) begin
            src_valid <= 1; src_data <= $random;
        end
    end
    always @(posedge dclk) if (drst_n && dst_valid) begin
        if (dst_data !== sent[nr]) begin errors = errors + 1; $display("MISMATCH %0d got %h exp %h", nr, dst_data, sent[nr]); end
        nr = nr + 1;
    end
    initial begin
        wait (nr >= N); #100000;
        $display("handshake_sync: sent=%0d received=%0d errors=%0d", ns, nr, errors);
        if (errors == 0 && nr == N) $display("PASS"); else $display("FAIL");
        $finish;
    end
    initial begin #500000000; $display("TIMEOUT nr=%0d", nr); $display("FAIL"); $finish; end
endmodule
