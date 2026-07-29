module axi_master_wr_fsm #(
    parameter ID_WIDTH = 4
) (
    input clk, rst_n,
    input pop_ready, wready, bvalid,
    input [31:0] pop_addr, wdata_in,
    input [7:0]  pop_len,
    input [2:0]  pop_size,
    input [1:0]  pop_burst, bresp,
    input [ID_WIDTH-1:0] pop_id, bid,
    input [3:0]  wstrb_in,
    output pop_valid, wvalid, wlast, bready, wr_complete_valid,
    output [31:0] wdata_out, cur_addr,
    output [3:0]  wstrb_out,
    output [ID_WIDTH-1:0] wr_complete_id
);
    localparam IDLE=2'd0, WRITE=2'd1, RESP=2'd2;
    reg  [1:0] s, ns;
    reg  [31:0] addr_reg;
    reg  [7:0]  beats_remaining, len_reg;
    reg  [2:0]  size_reg;
    reg  [1:0]  burst_reg;
    reg  [ID_WIDTH-1:0] id_reg;
    wire [31:0] next_addr;
    wire pop_hs = pop_valid && pop_ready;
    wire w_hs   = wvalid && wready;

    assign wdata_out = wvalid ? wdata_in : 32'd0;
    assign wstrb_out = wvalid ? wstrb_in : 4'd0;
    assign wr_complete_valid = (s == RESP) && bvalid && bready;
    assign wr_complete_id    = id_reg;
    assign cur_addr = addr_reg;
    assign wlast    = (s == WRITE) && (beats_remaining == 8'd0);
    assign pop_valid = (s == IDLE);
    assign wvalid    = (s == WRITE);
    assign bready    = (s == RESP);

    axi_burst_calc burst_calc (
        .addr_in(addr_reg), .size(size_reg), .len(len_reg),
        .burst_type(burst_reg), .addr_out(next_addr)
    );

    always @(*) begin
        case (s)
            IDLE:  ns = pop_hs ? WRITE : IDLE;
            WRITE: ns = (w_hs && beats_remaining == 8'd0) ? RESP : WRITE;
            RESP:  ns = (bready && bvalid) ? IDLE : RESP;
            default: ns = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s <= IDLE; addr_reg <= 0; len_reg <= 0; size_reg <= 0;
            burst_reg <= 0; id_reg <= 0; beats_remaining <= 0;
        end else begin
            s <= ns;
            if (pop_hs) begin
                addr_reg <= pop_addr; len_reg <= pop_len; size_reg <= pop_size;
                burst_reg <= pop_burst; id_reg <= pop_id;
                beats_remaining <= pop_len;
            end else if (w_hs) begin
                addr_reg <= next_addr;
                beats_remaining <= beats_remaining - 8'd1;
            end
        end
    end
endmodule