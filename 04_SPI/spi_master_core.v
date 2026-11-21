`timescale 1ns/1ns
// spi_master_core: burst / multi-SS / variable-width evolution of spi_master.v.
// spi_master.v is untouched - its 531/531 regression stays a valid frozen
// reference. This is a new module, not a wrapper, because continuous-SS
// burst mode requires changing the XFER->HOLD transition and SS timing
// inside the FSM itself.
//
// Verification note: with burst_len=1 and width_m1=7, every state
// transition and timing relationship here is bit-identical to spi_master.v's
// original behavior - diff-test against the frozen module under identical
// stimulus before trusting the new burst/width paths.
module spi_master_core #(
    parameter CLK_F        = 50_000_000,
    parameter SPI_F        = 1_000_000,
    parameter SETUP_CYCLES = 8,
    parameter HOLD_CYCLES  = 8,
    parameter MAX_WIDTH    = 16,   // widest supported word, in bits
    parameter MAX_SS       = 8     // number of slave-select lines
)(
    input  wire                  clk, rst,
    input  wire                  start,
    input  wire [MAX_WIDTH-1:0]  tx_data,     // right-justified; re-sampled on tx_load for word 2..N
    input  wire                  cpol, cpha,
    input  wire [3:0]            width_m1,    // word width minus 1 (7 = legacy 8-bit)
    input  wire [7:0]            burst_len,   // words in this transfer; 1 = legacy single-word behavior
    input  wire [2:0]            ss_sel,      // which of MAX_SS lines to assert
    input  wire                  miso,
    output wire                  mosi, sclk,
    output wire [MAX_SS-1:0]     ss_n,        // one-hot active-low; only ss_sel driven low while busy
    output reg  [MAX_WIDTH-1:0]  rx_data,     // last-received word, right-justified, valid on 'done'
    output wire                  busy,
    output wire                  done,        // pulses once per WORD - same per-word semantics as before
    output wire                  burst_done,  // pulses once, at the true end of the whole burst
    output wire                  tx_load      // pulses when word 2..N's tx_data must be freshly valid
);

    localparam N       = CLK_F / (2 * SPI_F);
    localparam MAX_CNT = (N > SETUP_CYCLES) ? (N > HOLD_CYCLES ? N : HOLD_CYCLES) : (SETUP_CYCLES > HOLD_CYCLES ? SETUP_CYCLES : HOLD_CYCLES);
    localparam CW      = $clog2(MAX_CNT + 1);
    localparam EW      = $clog2(2 * MAX_WIDTH);
    localparam BW      = $clog2(MAX_WIDTH);

    localparam IDLE = 2'b00, SETUP = 2'b01, XFER = 2'b10, HOLD = 2'b11;

    reg [1:0]    s, ns;
    reg [BW-1:0] bit_cnt;
    reg [CW-1:0] cnt;
    reg [EW-1:0] ecnt;
    reg [7:0]    byte_cnt;
    reg          sclk_reg, done_reg, burst_done_reg;
    reg [MAX_WIDTH-1:0] tx_shift, rx_shift;

    assign done       = done_reg;
    assign burst_done = burst_done_reg;
    assign busy       = (s == SETUP || s == XFER || s == HOLD);
    assign sclk       = sclk_reg;
    assign mosi       = tx_shift[MAX_WIDTH-1];

    wire [MAX_SS-1:0] ss_onehot = ({{(MAX_SS-1){1'b0}}, 1'b1}) << ss_sel;
    assign ss_n = busy ? ~ss_onehot : {MAX_SS{1'b1}};

    wire toggle_now   = (s == XFER) && (cnt == N - 1);
    wire rising_edge  = toggle_now && !sclk_reg;
    wire falling_edge = toggle_now &&  sclk_reg;

    wire mode_xor    = cpol ^ cpha;
    wire sample_edge = mode_xor ? falling_edge : rising_edge;
    wire shift_edge  = (mode_xor ? rising_edge : falling_edge) && !(cpha && ecnt == 0);

    wire word_edges_done = toggle_now && (ecnt == (2 * (width_m1 + 1) - 1));
    wire word_done       = (s == XFER) && sample_edge && (bit_cnt == width_m1);
    wire burst_word_done = (byte_cnt == burst_len - 1);
    wire more_words      = word_edges_done && (s == XFER) && !burst_word_done;

    assign tx_load = more_words;

    always @(*) begin
        case (s)
            IDLE : ns = start ? SETUP : IDLE;
            SETUP: ns = (cnt == SETUP_CYCLES - 1) ? XFER : SETUP;
            XFER : ns = word_edges_done ? (burst_word_done ? HOLD : XFER) : XFER;
            HOLD : ns = (cnt == HOLD_CYCLES - 1)  ? IDLE : HOLD;
            default: ns = IDLE;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s <= IDLE; cnt <= 0; ecnt <= 0; byte_cnt <= 0;
            sclk_reg <= 1'b0; done_reg <= 1'b0; burst_done_reg <= 1'b0;
        end else begin
            s              <= ns;
            done_reg       <= word_done;
            burst_done_reg <= word_done && burst_word_done;

            case (s)
                IDLE : cnt <= 0;
                SETUP: cnt <= (cnt == SETUP_CYCLES - 1) ? 0 : cnt + 1'b1;
                XFER : cnt <= (cnt == N - 1)            ? 0 : cnt + 1'b1;
                HOLD : cnt <= (cnt == HOLD_CYCLES  - 1) ? 0 : cnt + 1'b1;
                default: cnt <= 0;
            endcase

            ecnt <= (s != XFER) ? 0 : (word_edges_done ? 0 : (toggle_now ? ecnt + 1'b1 : ecnt));

            byte_cnt <= (start && s == IDLE) ? 0 : (word_edges_done ? byte_cnt + 1'b1 : byte_cnt);

            if (s != XFER)       sclk_reg <= cpol;
            else if (cnt == N-1) sclk_reg <= ~sclk_reg;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_shift <= 0; rx_shift <= 0; bit_cnt <= 0; rx_data <= 0;
        end else begin
            // TX: a word-boundary reload replaces the would-be ordinary
            // shift on the same cycle - safe, since the old word is fully
            // shifted out by then and about to be overwritten anyway.
            if (start && s == IDLE)
                tx_shift <= tx_data << (MAX_WIDTH - 1 - width_m1);
            else if (more_words)
                tx_shift <= tx_data << (MAX_WIDTH - 1 - width_m1);
            else if (shift_edge)
                tx_shift <= {tx_shift[MAX_WIDTH-2:0], 1'b0};

            // RX: for CPHA=1, the final sample of a word lands on the SAME
            // cycle as more_words - capture and bit_cnt reset must both be
            // able to fire together here, unlike the TX side above.
            if (start && s == IDLE) begin
                rx_shift <= 0;
                bit_cnt  <= 0;
            end else begin
                if (sample_edge) begin
                    if (bit_cnt == width_m1) begin rx_data <= {rx_shift[MAX_WIDTH-2:0], miso}; rx_shift <= 0; end
                    else                     rx_shift <= {rx_shift[MAX_WIDTH-2:0], miso};
                end
                if (more_words)      bit_cnt <= 0;
                else if (sample_edge) bit_cnt <= bit_cnt + 1'b1;
            end
        end
    end

endmodule