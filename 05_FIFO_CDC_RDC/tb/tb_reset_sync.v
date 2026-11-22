`timescale 1ps/1ps
module tb_reset_sync;
    reg clk = 0, arst_n = 0; wire srst_n;
    always #5000 clk = ~clk;                    // posedges at 5000, 15000, ...
    reset_sync #(.STAGES(2)) dut (.clk(clk), .arst_n(arst_n), .srst_n(srst_n));

    integer errors = 0, i;
    // de-assert must only ever happen on a clock edge
    always @(posedge srst_n) if (($time % 10000) != 5000) begin errors = errors + 1; $display("%0t srst_n rose off-clock", $time); end

    initial begin
        #3000 arst_n = 0; #1 if (srst_n !== 0) begin errors = errors + 1; $display("assert not immediate"); end
        for (i = 0; i < 20; i = i + 1) begin
            #(20000 + ($random & 32'h7fffffff) % 9973) arst_n = 1;     // release at an arbitrary time
            #(40000) ;
            if (srst_n !== 1) begin errors = errors + 1; $display("srst_n not released"); end
            #(($random & 32'h7fffffff) % 7919) arst_n = 0;             // async re-assert at arbitrary time
            #1 if (srst_n !== 0) begin errors = errors + 1; $display("async assert failed"); end
            #20000;
        end
        $display("reset_sync: errors=%0d", errors);
        if (errors == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end
endmodule
