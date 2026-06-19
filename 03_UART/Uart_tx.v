`timescale 1ns/1ps
module uart_tx (
    input wire clk, rst, tx_tick, sr, input wire [7:0] d,
    input wire [3:0] dbit, input wire sp_t, p_en, psel,
    output wire tx_line, idle
);
    localparam I=0, ST=1, D=2, P=3, SP=4;
    reg [2:0] s, ns; reg [3:0] bit_idx; reg [7:0] data; reg [1:0] sp_c;
    wire [7:0] mask = (8'h01<<dbit)-8'h01;
    wire parity_bit = psel ? ~^(data&mask) : ^(data&mask);

    always @(*) case (s)
        I : ns = sr ? ST : I;
        ST: ns = tx_tick ? D : ST;
        D : ns = (tx_tick && bit_idx==dbit-1) ? (p_en?P:SP) : D;
        P : ns = tx_tick ? SP : P;
        SP: ns = sp_t ? ((tx_tick && sp_c==1) ? I : SP) : (tx_tick ? I : SP);
        default: ns = I;
    endcase

    always @(posedge clk or posedge rst) begin
        if (rst) begin s<=I; bit_idx<=0; data<=0; sp_c<=0; end
        else begin
            s <= ns;
            bit_idx <= (s==ST) ? 4'b0 : (s==D && tx_tick) ? bit_idx+1'b1 : bit_idx;
            sp_c    <= (s==D)  ? 2'b0 : (s==SP && tx_tick) ? sp_c+1'b1 : sp_c;
            data    <= (s==I && sr) ? d : data;
        end
    end

    assign idle    = (s==I);
    assign tx_line = (s==I || s==SP) ? 1'b1 : (s==ST) ? 1'b0 : (s==P) ? parity_bit : data[bit_idx];
endmodule