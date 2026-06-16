`timescale 1ns/1ns
// ================================================================
//  Self-checking testbench for alu.v
//
//  Sampling strategy (critical for RLC/RRC):
//    res  = combinational → sampled BEFORE posedge (after 2ns settle)
//    z,c,o,n,p = registered → sampled AFTER posedge (+1ns)
//
//  Coverage: all 20 opcodes, carry/overflow corners, signed overflow,
//            RLC/RRC c_reg feedback, reset, mid-op reset, default op.
// ================================================================
module alu_tb;

    // ---- DUT signals -------------------------------------------
    reg        clk, rst;
    reg  [7:0] a, b;
    reg  [4:0] op;
    wire [7:0] res;
    wire       z, c, o, n, p;

    // ---- DUT instance ------------------------------------------
    alu dut (
        .clk(clk), .rst(rst),
        .a(a), .b(b), .op(op),
        .res(res),
        .z(z), .c(c), .o(o), .n(n), .p(p)
    );

    // ---- Clock: 10 ns period -----------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Opcode aliases ----------------------------------------
    localparam
        OP_ADD=5'd0,  OP_SUB=5'd1,  OP_INC=5'd2,  OP_DEC=5'd3,
        OP_NEG=5'd4,  OP_AND=5'd5,  OP_OR =5'd6,  OP_XOR=5'd7,
        OP_NOT=5'd8,  OP_LSL=5'd9,  OP_LSR=5'd10, OP_ASL=5'd11,
        OP_ASR=5'd12, OP_RL =5'd13, OP_RR =5'd14, OP_RLC=5'd15,
        OP_RRC=5'd16, OP_EQ =5'd17, OP_GT =5'd18, OP_LT =5'd19;

    // ---- Scoreboard --------------------------------------------
    integer pass_cnt = 0;
    integer fail_cnt = 0;
    integer test_num = 0;

    // ---- Parity helper (even parity = 1 when even number of 1s)
    function automatic PAR;
        input [7:0] v;
        PAR = ~^v;
    endfunction

    // ================================================================
    //  CHECK_ALL task
    //    Call with inputs already applied.
    //    Samples res before posedge, flags after posedge.
    // ================================================================
    task CHECK_ALL;
        input [7:0]   exp_res;
        input         exp_z, exp_c, exp_o, exp_n, exp_p;
        input [127:0] label;
        reg   [7:0]   got_res;
        reg           got_z, got_c, got_o, got_n, got_p;
        integer       ok;
    begin
        // 1) Let combinational settle, then snapshot res
        #2;
        got_res = res;

        // 2) Wait for posedge, then snapshot registered flags
        @(posedge clk); #1;
        got_z = z; got_c = c; got_o = o; got_n = n; got_p = p;

        test_num = test_num + 1;
        ok = (got_res === exp_res) && (got_z === exp_z) &&
             (got_c === exp_c)     && (got_o === exp_o) &&
             (got_n === exp_n)     && (got_p === exp_p);

        if (ok) begin
            $display("PASS [T%0d] %s", test_num, label);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("FAIL [T%0d] %s", test_num, label);
            $display("       a=%02h  b=%02h  op=%0d", a, b, op);
            if (got_res !== exp_res)
                $display("       res: exp=%02h  got=%02h  <--", exp_res, got_res);
            if (got_z   !== exp_z)
                $display("       Z  : exp=%0b   got=%0b   <--", exp_z, got_z);
            if (got_c   !== exp_c)
                $display("       C  : exp=%0b   got=%0b   <--", exp_c, got_c);
            if (got_o   !== exp_o)
                $display("       OVF: exp=%0b   got=%0b   <--", exp_o, got_o);
            if (got_n   !== exp_n)
                $display("       N  : exp=%0b   got=%0b   <--", exp_n, got_n);
            if (got_p   !== exp_p)
                $display("       P  : exp=%0b   got=%0b   <--", exp_p, got_p);
            fail_cnt = fail_cnt + 1;
        end
    end
    endtask

    // ================================================================
    //  APPLY + CHECK  (combined convenience task)
    // ================================================================
    task APPLY;
        input [7:0]   _a, _b;
        input [4:0]   _op;
        input [7:0]   exp_res;
        input         exp_z, exp_c, exp_o, exp_n, exp_p;
        input [127:0] label;
    begin
        a = _a; b = _b; op = _op;
        CHECK_ALL(exp_res, exp_z, exp_c, exp_o, exp_n, exp_p, label);
    end
    endtask

    // ================================================================
    //  MAIN STIMULUS
    // ================================================================
    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        // ---- Reset check ----------------------------------------
        rst = 1; a = 0; b = 0; op = 0;
        @(posedge clk); #1;
        test_num = test_num + 1;
        if ({z,c,o,n,p} !== 5'b00000) begin
            $display("FAIL [T%0d] RESET: flags not cleared", test_num);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [T%0d] RESET: all flags cleared", test_num);
            pass_cnt = pass_cnt + 1;
        end
        rst = 0;

        // ===========================================================
        // ADD
        // ===========================================================
        // Basic positive sum
        APPLY(8'h03, 8'h04, OP_ADD, 8'h07,
              0,0,0,0,PAR(8'h07), "ADD  3+4=7");

        // Unsigned carry: 0xFF+0x01=0x00 (carry=1, no signed overflow)
        APPLY(8'hFF, 8'h01, OP_ADD, 8'h00,
              1,1,0,0,PAR(8'h00), "ADD  FF+01 carry wrap");

        // Signed overflow: 0x7F+0x01=0x80 (pos+pos=neg)
        APPLY(8'h7F, 8'h01, OP_ADD, 8'h80,
              0,0,1,1,PAR(8'h80), "ADD  7F+01 signed OVF");

        // Zero sum
        APPLY(8'h00, 8'h00, OP_ADD, 8'h00,
              1,0,0,0,PAR(8'h00), "ADD  0+0=0 zero flag");

        // -128 + -128 = -256: wraps to 0x00, carry=1, SIGNED OVERFLOW (neg+neg=pos)
        APPLY(8'h80, 8'h80, OP_ADD, 8'h00,
              1,1,1,0,PAR(8'h00), "ADD  80+80 signed OVF+carry");

        // Signed overflow: neg+neg=pos 0x80+0xFF=0x7F
        APPLY(8'h80, 8'hFF, OP_ADD, 8'h7F,
              0,1,1,0,PAR(8'h7F), "ADD  80+FF signed OVF neg+neg=pos");

        // ===========================================================
        // SUB
        // ===========================================================
        APPLY(8'h05, 8'h03, OP_SUB, 8'h02,
              0,0,0,0,PAR(8'h02), "SUB  5-3=2");

        // Borrow: 0-1=0xFF, carry=1
        APPLY(8'h00, 8'h01, OP_SUB, 8'hFF,
              0,1,0,1,PAR(8'hFF), "SUB  0-1 borrow");

        // Signed overflow: 0x80-0x01=0x7F (neg-pos=pos)
        APPLY(8'h80, 8'h01, OP_SUB, 8'h7F,
              0,0,1,0,PAR(8'h7F), "SUB  80-01 signed OVF");

        // Equal operands → zero
        APPLY(8'hAA, 8'hAA, OP_SUB, 8'h00,
              1,0,0,0,PAR(8'h00), "SUB  AA-AA=0");

        // ===========================================================
        // INC
        // ===========================================================
        APPLY(8'h0A, 8'hXX, OP_INC, 8'h0B,
              0,0,0,0,PAR(8'h0B), "INC  0A->0B");

        APPLY(8'hFF, 8'hXX, OP_INC, 8'h00,
              1,1,0,0,PAR(8'h00), "INC  FF->00 carry");

        // ===========================================================
        // DEC
        // ===========================================================
        APPLY(8'h05, 8'hXX, OP_DEC, 8'h04,
              0,0,0,0,PAR(8'h04), "DEC  05->04");

        APPLY(8'h00, 8'hXX, OP_DEC, 8'hFF,
              0,1,0,1,PAR(8'hFF), "DEC  00->FF carry");

        APPLY(8'h01, 8'hXX, OP_DEC, 8'h00,
              1,0,0,0,PAR(8'h00), "DEC  01->00 zero");

        // ===========================================================
        // NEG  (~a + 1)
        // ===========================================================
        APPLY(8'h05, 8'hXX, OP_NEG, 8'hFB,
              0,0,0,1,PAR(8'hFB), "NEG  05->FB");

        APPLY(8'h00, 8'hXX, OP_NEG, 8'h00,
              1,0,0,0,PAR(8'h00), "NEG  00->00 zero");

        APPLY(8'hFF, 8'hXX, OP_NEG, 8'h01,
              0,0,0,0,PAR(8'h01), "NEG  FF->01");

        // ===========================================================
        // AND
        // ===========================================================
        APPLY(8'hF0, 8'h0F, OP_AND, 8'h00,
              1,0,0,0,PAR(8'h00), "AND  F0&0F=00");

        APPLY(8'hAA, 8'hFF, OP_AND, 8'hAA,
              0,0,0,1,PAR(8'hAA), "AND  AA&FF=AA");

        APPLY(8'hFF, 8'hFF, OP_AND, 8'hFF,
              0,0,0,1,PAR(8'hFF), "AND  FF&FF=FF");

        // ===========================================================
        // OR
        // ===========================================================
        APPLY(8'hA0, 8'h0B, OP_OR, 8'hAB,
              0,0,0,1,PAR(8'hAB), "OR   A0|0B=AB");

        APPLY(8'h00, 8'h00, OP_OR, 8'h00,
              1,0,0,0,PAR(8'h00), "OR   00|00=00");

        // ===========================================================
        // XOR
        // ===========================================================
        APPLY(8'hFF, 8'hFF, OP_XOR, 8'h00,
              1,0,0,0,PAR(8'h00), "XOR  FF^FF=00");

        APPLY(8'hA5, 8'h5A, OP_XOR, 8'hFF,
              0,0,0,1,PAR(8'hFF), "XOR  A5^5A=FF");

        APPLY(8'h00, 8'hFF, OP_XOR, 8'hFF,
              0,0,0,1,PAR(8'hFF), "XOR  00^FF=FF");

        // ===========================================================
        // NOT
        // ===========================================================
        APPLY(8'h00, 8'hXX, OP_NOT, 8'hFF,
              0,0,0,1,PAR(8'hFF), "NOT  00->FF");

        APPLY(8'hFF, 8'hXX, OP_NOT, 8'h00,
              1,0,0,0,PAR(8'h00), "NOT  FF->00");

        APPLY(8'hA5, 8'hXX, OP_NOT, 8'h5A,
              0,0,0,0,PAR(8'h5A), "NOT  A5->5A");

        // ===========================================================
        // LSL  {carry,result}={a,1'b0}
        // ===========================================================
        APPLY(8'hA5, 8'hXX, OP_LSL, 8'h4A,
              0,1,0,0,PAR(8'h4A), "LSL  A5->4A c=1");

        APPLY(8'h01, 8'hXX, OP_LSL, 8'h02,
              0,0,0,0,PAR(8'h02), "LSL  01->02");

        APPLY(8'h80, 8'hXX, OP_LSL, 8'h00,
              1,1,0,0,PAR(8'h00), "LSL  80->00 carry+zero");

        // ===========================================================
        // LSR  {result,carry}={1'b0,a}
        // ===========================================================
        APPLY(8'hA5, 8'hXX, OP_LSR, 8'h52,
              0,1,0,0,PAR(8'h52), "LSR  A5->52 c=1");

        APPLY(8'h80, 8'hXX, OP_LSR, 8'h40,
              0,0,0,0,PAR(8'h40), "LSR  80->40");

        APPLY(8'h01, 8'hXX, OP_LSR, 8'h00,
              1,1,0,0,PAR(8'h00), "LSR  01->00 carry+zero");

        // ===========================================================
        // ASL  (same encoding as LSL)
        // ===========================================================
        APPLY(8'hC0, 8'hXX, OP_ASL, 8'h80,
              0,1,0,1,PAR(8'h80), "ASL  C0->80 c=1");

        APPLY(8'h01, 8'hXX, OP_ASL, 8'h02,
              0,0,0,0,PAR(8'h02), "ASL  01->02");

        // ===========================================================
        // ASR  {result,carry}={a[7],a}  (sign-extend right shift)
        // ===========================================================
        // Negative number: 0x80 → 0xC0, carry=0
        APPLY(8'h80, 8'hXX, OP_ASR, 8'hC0,
              0,0,0,1,PAR(8'hC0), "ASR  80->C0 sign ext");

        // Positive odd: 0x55 → 0x2A, carry=1
        APPLY(8'h55, 8'hXX, OP_ASR, 8'h2A,
              0,1,0,0,PAR(8'h2A), "ASR  55->2A c=1");

        // 0xFF → 0xFF, carry=1
        APPLY(8'hFF, 8'hXX, OP_ASR, 8'hFF,
              0,1,0,1,PAR(8'hFF), "ASR  FF->FF c=1");

        // ===========================================================
        // RL  {a[6:0], a[7]}
        // ===========================================================
        APPLY(8'hA5, 8'hXX, OP_RL, 8'h4B,
              0,0,0,0,PAR(8'h4B), "RL   A5->4B");

        APPLY(8'h80, 8'hXX, OP_RL, 8'h01,
              0,0,0,0,PAR(8'h01), "RL   80->01");

        APPLY(8'h01, 8'hXX, OP_RL, 8'h02,
              0,0,0,0,PAR(8'h02), "RL   01->02");

        // ===========================================================
        // RR  {a[0], a[7:1]}
        // ===========================================================
        APPLY(8'hA5, 8'hXX, OP_RR, 8'hD2,
              0,0,0,1,PAR(8'hD2), "RR   A5->D2");

        APPLY(8'h01, 8'hXX, OP_RR, 8'h80,
              0,0,0,1,PAR(8'h80), "RR   01->80");

        APPLY(8'hFE, 8'hXX, OP_RR, 8'h7F,
              0,0,0,0,PAR(8'h7F), "RR   FE->7F");

        // ===========================================================
        // RLC  {carry,result}={a, c_reg}
        //   c_reg is latched carry from previous clock.
        //   Strategy: use ADD FF+01 to set carry=1, then run RLC.
        //   Must check res BEFORE posedge (combinational) and flags AFTER.
        // ===========================================================

        // --- Setup: produce carry=1 ---
        APPLY(8'hFF, 8'h01, OP_ADD, 8'h00,
              1,1,0,0,PAR(8'h00), "RLC_SETUP  ADD FF+01 c->1");

        // RLC A5 with c_reg=1: {carry,result}={A5,1}=1_0100_1011 → res=4B, c=1
        APPLY(8'hA5, 8'hXX, OP_RLC, 8'h4B,
              0,1,0,0,PAR(8'h4B), "RLC  A5,c_reg=1 -> 4B c=1");

        // c_reg still 1 (carry from previous RLC=1), same result
        APPLY(8'hA5, 8'hXX, OP_RLC, 8'h4B,
              0,1,0,0,PAR(8'h4B), "RLC  A5,c_reg=1 again -> 4B");

        // --- Clear carry via AND 0,0 ---
        APPLY(8'h00, 8'h00, OP_AND, 8'h00,
              1,0,0,0,PAR(8'h00), "RLC_SETUP  AND 00&00 c->0");

        // RLC A5 with c_reg=0: {carry,result}={A5,0}=1_0100_1010 → res=4A, c=1
        APPLY(8'hA5, 8'hXX, OP_RLC, 8'h4A,
              0,1,0,0,PAR(8'h4A), "RLC  A5,c_reg=0 -> 4A c=1");

        // RLC with zero data: 0x00, c_reg=1 → res=01, c=0
        APPLY(8'h00, 8'hXX, OP_RLC, 8'h01,
              0,0,0,0,PAR(8'h01), "RLC  00,c_reg=1 -> 01 c=0");

        // ===========================================================
        // RRC  {result,carry}={c_reg,a}
        //   c_reg=0 after the previous RLC (RLC 00 → carry=0)
        // ===========================================================
        // c_reg=0, a=A5=1010_0101 → {result,carry}={0,1010_0101} → res=0101_0010=52, c=1
        APPLY(8'hA5, 8'hXX, OP_RRC, 8'h52,
              0,1,0,0,PAR(8'h52), "RRC  A5,c_reg=0 -> 52 c=1");

        // c_reg=1 now, a=A5 → {result,carry}={1,1010_0101} → res=1101_0010=D2, c=1
        APPLY(8'hA5, 8'hXX, OP_RRC, 8'hD2,
              0,1,0,1,PAR(8'hD2), "RRC  A5,c_reg=1 -> D2 c=1");

        // c_reg=1, a=00 → {result,carry}={1,0000_0000}→ res=1000_0000=80, c=0
        APPLY(8'h00, 8'hXX, OP_RRC, 8'h80,
              0,0,0,1,PAR(8'h80), "RRC  00,c_reg=1 -> 80 c=0");

        // ===========================================================
        // EQUAL
        // ===========================================================
        APPLY(8'h07, 8'h07, OP_EQ, 8'h01,
              0,0,0,0,PAR(8'h01), "EQ   07==07 -> 1");

        APPLY(8'h07, 8'h08, OP_EQ, 8'h00,
              1,0,0,0,PAR(8'h00), "EQ   07!=08 -> 0");

        APPLY(8'h00, 8'h00, OP_EQ, 8'h01,
              0,0,0,0,PAR(8'h01), "EQ   00==00 -> 1");

        // ===========================================================
        // GT  (unsigned)
        // ===========================================================
        APPLY(8'hFF, 8'h00, OP_GT, 8'h01,
              0,0,0,0,PAR(8'h01), "GT   FF>00 -> 1");

        APPLY(8'h00, 8'hFF, OP_GT, 8'h00,
              1,0,0,0,PAR(8'h00), "GT   00>FF -> 0");

        APPLY(8'h05, 8'h05, OP_GT, 8'h00,
              1,0,0,0,PAR(8'h00), "GT   05==05 -> 0");

        // ===========================================================
        // LT  (unsigned)
        // ===========================================================
        APPLY(8'h00, 8'hFF, OP_LT, 8'h01,
              0,0,0,0,PAR(8'h01), "LT   00<FF -> 1");

        APPLY(8'hFF, 8'h00, OP_LT, 8'h00,
              1,0,0,0,PAR(8'h00), "LT   FF<00 -> 0");

        APPLY(8'h05, 8'h05, OP_LT, 8'h00,
              1,0,0,0,PAR(8'h00), "LT   05==05 -> 0");

        // ===========================================================
        // DEFAULT opcode (unused code → res=0)
        // ===========================================================
        a = 8'hAA; b = 8'h55; op = 5'd20;
        #2;
        test_num = test_num + 1;
        if (res !== 8'h00) begin
            $display("FAIL [T%0d] DEFAULT op=20 res=%02h (exp=00)", test_num, res);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [T%0d] DEFAULT op=20 res=00", test_num);
            pass_cnt = pass_cnt + 1;
        end
        @(posedge clk); #1; // consume clock

        // ===========================================================
        // MID-OPERATION RESET
        // ===========================================================
        a = 8'hFF; b = 8'hFF; op = OP_ADD;
        #2; rst = 1;
        @(posedge clk); #1;
        test_num = test_num + 1;
        if ({z,c,o,n,p} !== 5'b00000) begin
            $display("FAIL [T%0d] MID-OP RESET: flags=%b%b%b%b%b (exp=00000)",
                     test_num, z, c, o, n, p);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS [T%0d] MID-OP RESET: all flags cleared", test_num);
            pass_cnt = pass_cnt + 1;
        end
        rst = 0;

        // ===========================================================
        // SUMMARY
        // ===========================================================
        $display("\n==============================================");
        $display("  RESULTS: %0d passed,  %0d failed  /  %0d total",
                 pass_cnt, fail_cnt, test_num);
        if (fail_cnt == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** %0d TEST(S) FAILED — see above ***", fail_cnt);
        $display("==============================================\n");

        $finish;
    end

endmodule