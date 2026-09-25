`timescale 1ns/1ps
module uart_core #(
    parameter FIFO_DEPTH = 16
)(
    input wire clk, rst, sp_t, p_en, psel, cts_n, tx_wr_en, rx_rd_en, rx_line,
    input wire [3:0] dbit,
    input wire [7:0] tx_wr_data,
    output wire tx_full, tx_empty, rx_empty, rx_full, rx_overrun_err, frame_err, parity_err, rts_n, tx_line,
    output wire [7:0] rx_rd_data
);
    wire rx_tick, tx_tick;
    baud_gen u_baud (
        .clk     (clk),
        .rst     (rst),
        .rx_tick (rx_tick),
        .tx_tick (tx_tick)
    );
    wire        tx_idle;
    wire [7:0]  tx_fifo_rd_data;
    wire        tx_pop = tx_idle && !tx_empty && !cts_n;
    fifo_sync #(
        .WIDTH (8),
        .DEPTH (FIFO_DEPTH)
    ) u_tx_fifo (
        .clk          (clk),
        .rst          (rst),
        .wr_en        (tx_wr_en),
        .wr_data      (tx_wr_data),
        .rd_en        (tx_pop),
        .rd_data      (tx_fifo_rd_data),
        .full         (tx_full),
        .empty        (tx_empty),
        .almost_full  (),
        .almost_empty (),
        .count        ()
    );
    uart_tx u_tx (
        .clk     (clk),
        .rst     (rst),
        .tx_tick (tx_tick),
        .sr      (tx_pop),
        .d       (tx_fifo_rd_data),
        .dbit    (dbit),
        .sp_t    (sp_t),
        .p_en    (p_en),
        .psel    (psel),
        .tx_line (tx_line),
        .idle    (tx_idle)
    );
    wire [7:0] rx_q;
    wire       rx_done;
    wire       rx_almost_full;
    wire       rx_push = rx_done && !rx_full;

    uart_rx u_rx (
        .clk        (clk),
        .rst        (rst),
        .rx_tick    (rx_tick),
        .rx_line    (rx_line),
        .dbit       (dbit),
        .sp_t       (sp_t),
        .p_en       (p_en),
        .psel       (psel),
        .q          (rx_q),
        .rx_done    (rx_done),
        .frame_err  (frame_err),
        .parity_err (parity_err)
    );
    fifo_sync #(
        .WIDTH (8),
        .DEPTH (FIFO_DEPTH)
    ) u_rx_fifo (
        .clk          (clk),
        .rst          (rst),
        .wr_en        (rx_push),
        .wr_data      (rx_q),
        .rd_en        (rx_rd_en),
        .rd_data      (rx_rd_data),
        .full         (rx_full),
        .empty        (rx_empty),
        .almost_full  (rx_almost_full),
        .almost_empty (),
        .count        ()
    );
    reg rx_overrun_r;
    always @(posedge clk or posedge rst) begin
        if (rst) rx_overrun_r <= 1'b0;
        else if (rx_done && rx_full) rx_overrun_r <= 1'b1;
    end
    assign rx_overrun_err = rx_overrun_r;
    assign rts_n = rx_almost_full;
endmodule