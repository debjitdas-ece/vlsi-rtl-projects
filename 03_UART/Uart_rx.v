`timescale 1ns/1ps
// uart_rx: 16x oversample, 3-tap majority vote, 1/2 stop bits
// Changes: majority vote on taps 6,7,8; sp_t adds STOP2 state
module uart_rx (
    input  wire       clk, rst, rx_tick, rx_line,
    input  wire [3:0] dbit,
    input  wire       sp_t, p_en, psel,
    output reg  [7:0] q,
    output reg        rx_done, frame_err, parity_err
);
    localparam IDLE=0,START=1,DATA=2,PARITY=3,STOP=4,STOP2=5;
    reg [2:0] s, ns;
    reg [3:0] t_counter, rbit;
    reg [1:0] mv_cnt;
    reg       start_ok, p_sample;
    wire [7:0] mask = (8'h01<<dbit)-8'h01;
    wire exp_parity  = psel ? ~^(q&mask) : ^(q&mask);
    wire tick15      = rx_tick && t_counter==15;
    wire mv_tap      = rx_tick && (t_counter==6||t_counter==7||t_counter==8);
    wire [1:0] mv_next = (t_counter==6) ? {1'b0,rx_line} : mv_cnt+{1'b0,rx_line};

    always @(*) case (s)
        IDLE  : ns = rx_line ? IDLE : START;
        START : ns = tick15 ? (start_ok ? DATA : IDLE) : START;
        DATA  : ns = (tick15 && rbit==dbit-1) ? (p_en?PARITY:STOP) : DATA;
        PARITY: ns = tick15 ? STOP : PARITY;
        STOP  : ns = tick15 ? (sp_t ? STOP2 : IDLE) : STOP;
        STOP2 : ns = tick15 ? IDLE : STOP2;
        default: ns = IDLE;
    endcase

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s<=IDLE; t_counter<=0; rbit<=0; q<=0; rx_done<=0;
            frame_err<=0; parity_err<=0; p_sample<=0; start_ok<=0; mv_cnt<=0;
        end else begin
            s <= ns;
            t_counter <= (s==IDLE) ? 4'd0 : tick15 ? 4'd0 : rx_tick ? t_counter+1'b1 : t_counter;

            if (s==IDLE && ns==START) begin q<=0; parity_err<=0; frame_err<=0; end
            if (s==START && rx_tick && t_counter==7) start_ok <= ~rx_line;

            rbit <= (s==START) ? 4'b0 : (s==DATA && tick15) ? rbit+1'b1 : rbit;

            if ((s==DATA||s==PARITY) && mv_tap) mv_cnt <= mv_next;

            if (s==DATA   && tick15)  q[rbit]    <= (mv_cnt>=2);
            if (s==PARITY && tick15) {parity_err,p_sample} <= {(mv_cnt>=2)!=exp_parity,(mv_cnt>=2)};

            if      (s==STOP  && tick15) begin frame_err<=~rx_line; rx_done<=~sp_t; end
            else if (s==STOP2 && tick15) begin frame_err<=frame_err|~rx_line; rx_done<=1; end
            else                          rx_done <= 0;
        end
    end
endmodule