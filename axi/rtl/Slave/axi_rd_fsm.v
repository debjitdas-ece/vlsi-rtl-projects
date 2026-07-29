module axi_rd_fsm #(
    parameter ID_WIDTH = 3
) (
    input  wire clk, rst_n,
    input  wire arvalid, rready, decode_err_in,
    input  wire [31:0] araddr,
    input  wire [7:0] arlen,
    input  wire [2:0] arsize,
    input  wire [1:0] arburst,
    input  wire [ID_WIDTH-1:0] arid,
    input  wire [31:0] regmap_rdata,   // TODO: wire to axi_regmap output once that module exists
    output wire arready, rvalid, rlast,
    output wire [1:0] rresp,
    output wire [ID_WIDTH-1:0] rid,
    output wire [31:0] cur_addr, rdata
);
    localparam IDLE = 2'b00, READ = 2'b01;

    reg [31:0] addr_reg;
    reg [7:0]  arlen_reg, beats_remaining;
    reg [2:0]  arsize_reg;
    reg [1:0]  arburst_reg;
    reg [ID_WIDTH-1:0] rid_reg;
    reg        resp_error_reg;
    reg [1:0]  s, ns;

    wire ar_hs = arvalid && arready;
    wire r_hs  = rvalid && rready;

    assign arready  = (s == IDLE);
    assign rvalid   = (s == READ);
    assign rlast    = (s == READ) && (beats_remaining == 8'd0);
    assign rresp    = resp_error_reg ? `AXI_RESP_DECERR : `AXI_RESP_OKAY;
    assign rid      = rid_reg;
    assign cur_addr = addr_reg;
    assign rdata    = regmap_rdata;

    always @(*) begin
        case (s)
            IDLE: ns = ar_hs ? READ : IDLE;
            READ: ns = (r_hs && rlast) ? IDLE : READ;
            default: ns = IDLE;
        endcase
    end

    wire [31:0] next_addr;
    axi_burst_calc burst_calc (
        .addr_in(addr_reg), .size(arsize_reg), .len(arlen_reg),
        .burst_type(arburst_reg), .addr_out(next_addr)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s <= IDLE; addr_reg <= 0; arlen_reg <= 0; arsize_reg <= 0;
            arburst_reg <= 0; beats_remaining <= 0; rid_reg <= 0; resp_error_reg <= 0;
        end else begin
            s <= ns;
            if (ar_hs) begin
                addr_reg <= araddr; arlen_reg <= arlen; arsize_reg <= arsize;
                arburst_reg <= arburst; beats_remaining <= arlen;
                rid_reg <= arid; resp_error_reg <= decode_err_in;
            end else if (r_hs) begin
                addr_reg <= next_addr;
                beats_remaining <= beats_remaining - 8'd1;
            end
        end
    end
endmodule