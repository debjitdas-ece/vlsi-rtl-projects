`timescale 1ns/1ps
module tb_uart;
    parameter CLK_F=50_000_000, BAUD_R=115_200, O=16;

    reg clk=0, rst=1, sr=0, sp_t=0, p_en=0, psel=0, inject_en=0, inject_val=1;
    reg [7:0] d=0; reg [3:0] dbit=8;
    wire rx_tick, tx_tick, tx_line, idle;
    wire [7:0] q; wire rx_done, frame_err, parity_err;
    wire rx_in = inject_en ? inject_val : tx_line;
    integer pass_cnt=0, fail_cnt=0, i;

    baud_gen #(.CLK_F(CLK_F),.BAUD_R(BAUD_R),.O(O)) bg (.clk(clk),.rst(rst),.rx_tick(rx_tick),.tx_tick(tx_tick));
    uart_tx  dtx (.clk(clk),.rst(rst),.tx_tick(tx_tick),.sr(sr),.d(d),.dbit(dbit),.sp_t(sp_t),.p_en(p_en),.psel(psel),.tx_line(tx_line),.idle(idle));
    uart_rx  drx (.clk(clk),.rst(rst),.rx_tick(rx_tick),.rx_line(rx_in),.dbit(dbit),.sp_t(sp_t),.p_en(p_en),.psel(psel),.q(q),.rx_done(rx_done),.frame_err(frame_err),.parity_err(parity_err));

    always #10 clk = ~clk;

    // --- task: basic send & check ---
    task send_and_check;
        input [7:0] bv, eq; input ef, ep; input [63:0] tns; input [79:0] lbl;
        integer tw; reg gd;
        begin
            @(posedge clk); while(!idle) @(posedge clk);
            d<=bv; sr<=1; @(posedge clk); sr<=0;
            gd=0; for(tw=0; tw<tns/20&&!gd; tw=tw+1) begin @(posedge clk); if(rx_done) gd=1; end
            if(!gd) begin $display("FAIL [%s] 0x%02x TIMEOUT",lbl,bv); fail_cnt=fail_cnt+1; end
            else if(q!==eq||frame_err!==ef||parity_err!==ep) begin
                $display("FAIL [%s] 0x%02x q=0x%02x f=%b p=%b | exp 0x%02x f=%b p=%b",lbl,bv,q,frame_err,parity_err,eq,ef,ep); fail_cnt=fail_cnt+1;
            end else begin $display("PASS [%s] 0x%02x q=0x%02x f=%b p=%b",lbl,bv,q,frame_err,parity_err); pass_cnt=pass_cnt+1; end
        end
    endtask

    // --- task: error injection (parity / frame) ---
    task inject_test;
        input [7:0] bv; input inj_p, inj_s, ep, ef; input [79:0] lbl;
        integer tw; reg gd;
        begin
            inject_en=0; inject_val=1;
            @(posedge clk); while(!idle) @(posedge clk);
            d<=bv; p_en<=1; psel<=0; sr<=1; @(posedge clk); sr<=0;
            gd=0;
            for(tw=0; tw<200000&&!gd; tw=tw+1) begin
                @(posedge clk);
                if      (inj_p && drx.s==3'd3) begin inject_en<=1; inject_val<=~tx_line; end
                else if (inj_s && drx.s==3'd4) begin inject_en<=1; inject_val<=0; end
                else                            begin inject_en<=0; inject_val<=1; end
                if(rx_done) gd=1;
            end
            inject_en<=0;
            if(!gd) begin $display("FAIL [%s] TIMEOUT",lbl); fail_cnt=fail_cnt+1; end
            else if(frame_err!==ef||parity_err!==ep) begin
                $display("FAIL [%s] 0x%02x f=%b p=%b | exp f=%b p=%b",lbl,bv,frame_err,parity_err,ef,ep); fail_cnt=fail_cnt+1;
            end else begin $display("PASS [%s] 0x%02x f=%b p=%b",lbl,bv,frame_err,parity_err); pass_cnt=pass_cnt+1; end
            p_en<=0; @(posedge clk);
        end
    endtask

    // --- task: single-tap majority-vote glitch ---
    task noise_glitch_test;
        input [7:0] bv; input [3:0] ibit, itap; input [79:0] lbl;
        integer tw; reg gd, gdone;
        begin
            inject_en=0; inject_val=1; gdone=0;
            @(posedge clk); while(!idle) @(posedge clk);
            d<=bv; p_en<=0; sr<=1; @(posedge clk); sr<=0;
            gd=0;
            for(tw=0; tw<200000&&!gd; tw=tw+1) begin
                @(posedge clk);
                if(!gdone && drx.s==3'd2 && drx.rbit==ibit && drx.t_counter==itap && rx_tick)
                    begin inject_en<=1; inject_val<=~tx_line; gdone=1; end
                else begin inject_en<=0; inject_val<=1; end
                if(rx_done) gd=1;
            end
            inject_en<=0;
            if(!gd) begin $display("FAIL [%s] TIMEOUT",lbl); fail_cnt=fail_cnt+1; end
            else if(q!==bv||frame_err||parity_err) begin
                $display("FAIL [%s] 0x%02x q=0x%02x f=%b p=%b (not corrected)",lbl,bv,q,frame_err,parity_err); fail_cnt=fail_cnt+1;
            end else begin $display("PASS [%s] 0x%02x bit[%0d] tap[%0d] corrected",lbl,bv,ibit,itap); pass_cnt=pass_cnt+1; end
        end
    endtask

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0,tb_uart);
        rst=1; repeat(10) @(posedge clk); rst=0; repeat(5) @(posedge clk);

        // G1: basic 8N1
        $display("\n=== G1: Basic 8N1 ===");
        dbit=8; p_en=0; psel=0; sp_t=0;
        send_and_check(8'h00,8'h00,0,0,1_000_000,"8N1_00"); send_and_check(8'hFF,8'hFF,0,0,1_000_000,"8N1_FF");
        send_and_check(8'hA5,8'hA5,0,0,1_000_000,"8N1_A5"); send_and_check(8'h5A,8'h5A,0,0,1_000_000,"8N1_5A");
        send_and_check(8'h01,8'h01,0,0,1_000_000,"8N1_01"); send_and_check(8'h80,8'h80,0,0,1_000_000,"8N1_80");

        // G2: full 256-byte 8E1 sweep
        $display("\n=== G2: 0x00-0xFF sweep 8E1 ===");
        dbit=8; p_en=1; psel=0; sp_t=0;
        for(i=0; i<=255; i=i+1) send_and_check(i[7:0],i[7:0],0,0,1_500_000,"8E1");
        $display("  => G2 done: %0d pass %0d fail",pass_cnt,fail_cnt);

        // G3: odd parity 8O1
        $display("\n=== G3: 8O1 ===");
        dbit=8; p_en=1; psel=1; sp_t=0;
        send_and_check(8'h00,8'h00,0,0,1_500_000,"8O1_00"); send_and_check(8'hFF,8'hFF,0,0,1_500_000,"8O1_FF");
        send_and_check(8'hA5,8'hA5,0,0,1_500_000,"8O1_A5"); send_and_check(8'h5A,8'h5A,0,0,1_500_000,"8O1_5A");
        send_and_check(8'h55,8'h55,0,0,1_500_000,"8O1_55"); send_and_check(8'hAA,8'hAA,0,0,1_500_000,"8O1_AA");

        // G4: 7-bit 7E1
        $display("\n=== G4: 7E1 ===");
        dbit=7; p_en=1; psel=0; sp_t=0;
        send_and_check(8'h7F,8'h7F,0,0,1_500_000,"7E1_7F"); send_and_check(8'h55,8'h55,0,0,1_500_000,"7E1_55");
        send_and_check(8'h00,8'h00,0,0,1_500_000,"7E1_00"); send_and_check(8'h41,8'h41,0,0,1_500_000,"7E1_41");

        // G5: error injection
        $display("\n=== G5: Error injection 8E1 ===");
        dbit=8; sp_t=0;
        inject_test(8'hA5,0,0,0,0,"CLEAN"); inject_test(8'hA5,1,0,1,0,"PERR"); inject_test(8'hA5,0,1,0,1,"FERR");

        // G6: sr-while-busy
        $display("\n=== G6: sr-while-busy ===");
        begin : g6
            integer tw6; reg gd6;
            dbit=8; p_en=0; psel=0; sp_t=0;
            @(posedge clk); while(!idle) @(posedge clk);
            d<=8'hA5; sr<=1; @(posedge clk); sr<=0;
            repeat(1728) @(posedge clk);          // ~4 bit-times in
            d<=8'h3C; sr<=1; @(posedge clk); sr<=0; // spurious sr
            gd6=0; for(tw6=0; tw6<100000&&!gd6; tw6=tw6+1) begin @(posedge clk); if(rx_done) gd6=1; end
            if(!gd6) begin $display("FAIL [SR_BUSY] TIMEOUT"); fail_cnt=fail_cnt+1; end
            else if(q!==8'hA5) begin $display("FAIL [SR_BUSY] q=0x%02x (not 0xA5)",q); fail_cnt=fail_cnt+1; end
            else begin $display("PASS [SR_BUSY] q=0x%02x, spurious sr ignored",q); pass_cnt=pass_cnt+1; end
            repeat(5) @(posedge clk);
        end

        // G7: majority-vote noise immunity
        $display("\n=== G7: Majority-vote glitch immunity ===");
        dbit=8; p_en=0; psel=0; sp_t=0;
        noise_glitch_test(8'hA5,4'd0,4'd8,"MV_1_t8"); // bit[0]=1, tap 8 glitched
        noise_glitch_test(8'hA5,4'd1,4'd6,"MV_0_t6"); // bit[1]=0, tap 6 glitched
        noise_glitch_test(8'hA5,4'd7,4'd6,"MV_1_t6"); // bit[7]=1, tap 6 glitched
        noise_glitch_test(8'h00,4'd4,4'd8,"MV_0_t8"); // bit[4]=0, tap 8 glitched
        noise_glitch_test(8'hFF,4'd3,4'd8,"MV_F_t8"); // bit[3]=1, tap 8 glitched

        // G8: 2-stop-bit
        $display("\n=== G8: 2-stop-bit ===");
        dbit=8; p_en=0; psel=0; sp_t=1;
        send_and_check(8'hA5,8'hA5,0,0,2_000_000,"8N2_A5"); send_and_check(8'h00,8'h00,0,0,2_000_000,"8N2_00");
        send_and_check(8'hFF,8'hFF,0,0,2_000_000,"8N2_FF");
        p_en=1;
        send_and_check(8'hA5,8'hA5,0,0,2_000_000,"8E2_A5"); send_and_check(8'h5A,8'h5A,0,0,2_000_000,"8E2_5A");

        $display("\n=== TOTAL: %0d PASS  %0d FAIL %s ===",pass_cnt,fail_cnt,fail_cnt==0?"— CLEAN":"— FAILURES");
        $finish;
    end

    initial begin #900_000_000; $display("WATCHDOG"); $finish; end
endmodule