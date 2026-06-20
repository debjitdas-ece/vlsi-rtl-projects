`timescale 1ns/1ns
module spi_master #(
    parameter CLK_F        = 50_000_000,
    parameter SPI_F        = 1_000_000,
    parameter SETUP_CYCLES = 8,
    parameter HOLD_CYCLES  = 8
)(
    input  wire       clk, rst,
    input  wire       start,
    input  wire [7:0] tx_data,
    input  wire       cpol, cpha,
    input  wire       miso,
    output wire       mosi, sclk, ss,
    output reg  [7:0] rx_data,
    output wire       busy, done
);

    localparam N       = CLK_F / (2 * SPI_F);
    localparam MAX_CNT = (N > SETUP_CYCLES) ? (N > HOLD_CYCLES ? N : HOLD_CYCLES) : (SETUP_CYCLES > HOLD_CYCLES ? SETUP_CYCLES : HOLD_CYCLES);
    localparam CW      = $clog2(MAX_CNT + 1);
    localparam NE      = 16;          
    localparam EW      = $clog2(NE);

    localparam IDLE = 2'b00, SETUP = 2'b01, XFER = 2'b10, HOLD = 2'b11;

    reg [1:0]    s, ns;
    reg [2:0]    bit_cnt;
    reg [CW-1:0] cnt;
    reg [EW-1:0] ecnt;
    reg          sclk_reg, done_reg;
    reg [7:0]    tx_shift, rx_shift;

    assign done = done_reg;
    assign busy = (s == SETUP || s == XFER || s == HOLD);
    assign ss   = ~busy;
    assign sclk = sclk_reg;
    assign mosi = tx_shift[7];

    wire toggle_now   = (s == XFER) && (cnt == N - 1);
    wire rising_edge  = toggle_now && !sclk_reg;
    wire falling_edge = toggle_now &&  sclk_reg;

    wire mode_xor    = cpol ^ cpha;
    wire sample_edge = mode_xor ? falling_edge : rising_edge;
    wire shift_edge  = (mode_xor ? rising_edge : falling_edge) && !(cpha && ecnt == 0);

    wire byte_done = (s == XFER) && sample_edge && (bit_cnt == 3'd7);
    wire clk_done  = toggle_now && (ecnt == NE - 1);

    always @(*) begin
        case (s)
            IDLE : ns = start ? SETUP : IDLE;
            SETUP: ns = (cnt == SETUP_CYCLES - 1) ? XFER : SETUP;
            XFER : ns = clk_done ? HOLD : XFER;
            HOLD : ns = (cnt == HOLD_CYCLES - 1)  ? IDLE : HOLD;
            default: ns = IDLE;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s <= IDLE; cnt <= 0; ecnt <= 0; sclk_reg <= 1'b0; done_reg <= 1'b0;
        end else begin
            s        <= ns;
            done_reg <= byte_done;

            case (s)
                IDLE : cnt <= 0;
                SETUP: cnt <= (cnt == SETUP_CYCLES - 1) ? 0 : cnt + 1'b1;
                XFER : cnt <= (cnt == N - 1)            ? 0 : cnt + 1'b1;
                HOLD : cnt <= (cnt == HOLD_CYCLES  - 1) ? 0 : cnt + 1'b1;
                default: cnt <= 0;
            endcase

            ecnt <= (s != XFER) ? 0 : (toggle_now ? ecnt + 1'b1 : ecnt);

            if (s != XFER)       sclk_reg <= cpol;
            else if (cnt == N-1) sclk_reg <= ~sclk_reg;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_shift <= 8'd0; rx_shift <= 8'd0; bit_cnt <= 3'd0; rx_data <= 8'd0;
        end else begin
            if (start && s == IDLE) begin
                tx_shift <= tx_data;
                bit_cnt  <= 3'd0;
            end

            if (shift_edge)
                tx_shift <= {tx_shift[6:0], 1'b0};

            if (sample_edge) begin
                bit_cnt <= bit_cnt + 1'b1;
                if (bit_cnt == 3'd7) rx_data  <= {rx_shift[6:0], miso};
                else                 rx_shift <= {rx_shift[6:0], miso};
            end
        end
    end

endmodule