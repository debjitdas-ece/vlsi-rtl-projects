module axi_master_rd_fsm #(
    parameter ID_WIDTH = 4
) (
    input  clk, rst_n,
    input  pop_ready, rvalid, rlast,
    input  [1:0]  rresp,
    input  [31:0] rdata,
    input  [ID_WIDTH-1:0] rid, pop_id,
    input  [7:0]  pop_len,
    output pop_valid, rready, rd_complete_valid,
    output [31:0] rdata_out,
    output [1:0]  rresp_out,
    output [ID_WIDTH-1:0] rd_complete_id
);
    localparam IDLE = 1'd0, READ = 1'd1;
    reg s, ns;
    reg [7:0] len_reg, beats_remaining;
    reg [ID_WIDTH-1:0] id_reg;

    wire pop_hs = pop_valid && pop_ready;

    assign pop_valid        = (s == IDLE);
    assign rready            = (s == READ);
    assign rd_complete_valid = rvalid && rready && rlast;
    assign rd_complete_id    = id_reg;
    assign rdata_out         = rdata;
    assign rresp_out         = rresp;
    // TODO: sanity-check rlast against (beats_remaining==0) via a checker
    // task later -- a mismatch would indicate a real protocol violation

    always @(*) begin
        case (s)
            IDLE: ns = pop_hs ? READ : IDLE;
            READ: ns = (rvalid && rready && rlast) ? IDLE : READ;
            default: ns = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s <= IDLE; len_reg <= 0; beats_remaining <= 0; id_reg <= 0;
        end else begin
            s <= ns;
            if (pop_hs) begin
                len_reg <= pop_len; beats_remaining <= pop_len; id_reg <= pop_id;
            end else if (rvalid && rready) begin
                beats_remaining <= beats_remaining - 1'b1;
            end
        end
    end
endmodule