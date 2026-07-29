module axi_wr_fsm #(
    parameter ID_WIDTH = 3
) (
    input  wire clk, rst_n,
    input  wire awvalid, wvalid, bready, decode_error,
    input  wire [31:0] awaddr, wdata,
    input  wire [7:0] awlen,
    input  wire [2:0] awsize,
    input  wire [1:0] awburst,
    input  wire [ID_WIDTH-1:0] awid,
    input  wire [3:0] wstrb,
    input  wire wlast,
    output wire awready, wready, bvalid, wr_en,
    output wire [1:0] bresp,
    output wire [ID_WIDTH-1:0] bid,
    output wire [31:0] cur_addr
);
    localparam IDLE=2'b00, WRITE=2'b01, RESP=2'b10;
    reg [1:0] s, ns;
    reg [31:0] addr_reg;
    reg [7:0]  awlen_reg, beats_remaining;
    reg [2:0]  awsize_reg;
    reg [1:0]  awburst_reg;
    reg [ID_WIDTH-1:0] bid_reg;
    reg        resp_error_reg;

    wire aw_hs = awvalid && awready;
    wire w_hs  = wvalid && wready;

    assign awready = (s == IDLE);
    assign wready  = (s == WRITE);
    assign bvalid  = (s == RESP);
    assign cur_addr = addr_reg;
    assign wr_en    = w_hs && !resp_error_reg;
    assign bresp    = resp_error_reg ? `AXI_RESP_DECERR : `AXI_RESP_OKAY;
    assign bid      = bid_reg;

    always @(*) begin
        case (s)
            IDLE:  ns = aw_hs ? WRITE : IDLE;
            WRITE: ns = (w_hs && beats_remaining == 8'd0) ? RESP : WRITE;
            RESP:  ns = (bvalid && bready) ? IDLE : RESP;
            default: ns = IDLE;
        endcase
    end

    wire [31:0] next_addr;
    axi_burst_calc burst_calc (
        .addr_in(addr_reg), .size(awsize_reg), .len(awlen_reg),
        .burst_type(awburst_reg), .addr_out(next_addr)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s <= IDLE; addr_reg <= 0; awlen_reg <= 0; awsize_reg <= 0;
            awburst_reg <= 0; beats_remaining <= 0; bid_reg <= 0; resp_error_reg <= 0;
        end else begin
            s <= ns;
            if (aw_hs) begin
                addr_reg <= awaddr; awlen_reg <= awlen; awsize_reg <= awsize;
                awburst_reg <= awburst; beats_remaining <= awlen;
                bid_reg <= awid; resp_error_reg <= decode_error;
            end else if (w_hs) begin
                addr_reg <= next_addr;
                beats_remaining <= beats_remaining - 8'd1;
            end
        end
    end
endmodule