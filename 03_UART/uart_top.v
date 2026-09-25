`timescale 1ns/1ps
// uart_top: APB3 register-mapped wrapper around uart_core.
// Zero-wait-state slave (PREADY tied high) - PSEL && PENABLE is valid for
// exactly one cycle per transfer, so address decode happens directly on it
// with no separate SETUP/ACCESS state tracking needed.
//
// Register map (byte offsets):
//   0x00 CTRL   R/W  [0]EN [1]PARITY_EN [2]PARITY_ODD [3]TWO_STOP_BITS [7:4]DBIT
//   0x04 STATUS RO   [0]TX_EMPTY [1]TX_FULL [2]RX_EMPTY [3]RX_FULL
//                    [4]FRAME_ERR [5]PARITY_ERR [6]OVERRUN_ERR
//   0x0C TXDATA WO   [7:0] - write pushes a byte into the TX FIFO
//   0x10 RXDATA RO   [7:0] - read pops a byte from the RX FIFO
//
// Design decision: CTRL.EN gates uart_core through its own reset input.
// While EN=0, uart_core is held in reset (FIFOs stay at count=0, TX/RX FSMs
// stay parked in IDLE) - matches how a real peripheral's enable bit behaves.
// Software must write CTRL with EN=1 before TXDATA/RXDATA do anything.
//
// Baud rate is still compile-time only (uart_core doesn't expose CLK_F/
// BAUD_R/O yet) - no BAUD_DIV register here since there's nothing for it
// to drive. Add it alongside a runtime divider input on baud_gen if/when
// that's needed.
module uart_top #(
    parameter FIFO_DEPTH = 16
)(
    input  wire        PCLK, PRESETn,
    input  wire        PSEL, PENABLE, PWRITE,
    input  wire [7:0]  PADDR,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output wire        PREADY,

    input  wire        rx_line, cts_n,
    output wire         tx_line, rts_n
);
    localparam ADDR_CTRL   = 8'h00;
    localparam ADDR_STATUS = 8'h04;
    localparam ADDR_TXDATA = 8'h0C;
    localparam ADDR_RXDATA = 8'h10;

    wire rst = ~PRESETn;               // uart_core uses active-high, async rst
    assign PREADY = 1'b1;               // zero-wait-state slave

    wire access = PSEL && PENABLE;      // valid for exactly 1 cycle per transfer
    wire wr     = access && PWRITE;
    wire rd     = access && !PWRITE;

    // ---- CTRL register (R/W) ----
    reg       ctrl_en, ctrl_parity_en, ctrl_parity_odd, ctrl_two_stop;
    reg [3:0] ctrl_dbit;
    always @(posedge PCLK or posedge rst) begin
        if (rst) begin
            ctrl_en <= 1'b0; ctrl_parity_en <= 1'b0; ctrl_parity_odd <= 1'b0;
            ctrl_two_stop <= 1'b0; ctrl_dbit <= 4'd8;
        end else if (wr && PADDR == ADDR_CTRL) begin
            ctrl_en         <= PWDATA[0];
            ctrl_parity_en  <= PWDATA[1];
            ctrl_parity_odd <= PWDATA[2];
            ctrl_two_stop   <= PWDATA[3];
            ctrl_dbit       <= PWDATA[7:4];
        end
    end
    wire core_rst = rst | ~ctrl_en;     // held in reset while disabled

    // ---- uart_core instance ----
    wire       tx_full, tx_empty, rx_empty, rx_full, rx_overrun_err, frame_err, parity_err;
    wire [7:0] rx_rd_data;
    wire       tx_wr_en = wr && (PADDR == ADDR_TXDATA);
    wire       rx_rd_en = rd && (PADDR == ADDR_RXDATA);

    uart_core #(.FIFO_DEPTH(FIFO_DEPTH)) u_core (
        .clk          (PCLK),
        .rst          (core_rst),
        .sp_t         (ctrl_two_stop),
        .p_en         (ctrl_parity_en),
        .psel         (ctrl_parity_odd),
        .cts_n        (cts_n),
        .tx_wr_en     (tx_wr_en),
        .tx_wr_data   (PWDATA[7:0]),
        .rx_rd_en     (rx_rd_en),
        .rx_rd_data   (rx_rd_data),
        .dbit         (ctrl_dbit),
        .tx_full      (tx_full),
        .tx_empty     (tx_empty),
        .rx_empty     (rx_empty),
        .rx_full      (rx_full),
        .rx_overrun_err (rx_overrun_err),
        .frame_err    (frame_err),
        .parity_err   (parity_err),
        .rts_n        (rts_n),
        .tx_line      (tx_line),
        .rx_line      (rx_line)
    );

    // ---- read mux ----
    always @(*) begin
        case (PADDR)
            ADDR_CTRL:   PRDATA = {24'd0, ctrl_dbit, ctrl_two_stop, ctrl_parity_odd, ctrl_parity_en, ctrl_en};
            ADDR_STATUS: PRDATA = {25'd0, rx_overrun_err, parity_err, frame_err, rx_full, rx_empty, tx_full, tx_empty};
            ADDR_RXDATA: PRDATA = {24'd0, rx_rd_data};
            default:     PRDATA = 32'd0;
        endcase
    end
endmodule