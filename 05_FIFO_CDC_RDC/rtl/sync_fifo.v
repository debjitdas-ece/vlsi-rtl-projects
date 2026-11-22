// Parameterized synchronous FIFO, first-word-fall-through read.
module sync_fifo #(
    parameter DW     = 8,
    parameter AW     = 4,          // depth = 2**AW
    parameter ALMOST = 2           // threshold for almost_full / almost_empty
)(
    input               clk,
    input               rst_n,
    input               wr_en,
    input               rd_en,
    input  [DW-1:0]     wdata,
    output [DW-1:0]     rdata,     // valid whenever !empty
    output              full,
    output              empty,
    output              almost_full,
    output              almost_empty,
    output [AW:0]       count
);
    localparam DEPTH = 1 << AW;
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [AW:0]   wptr, rptr;      // one extra MSB distinguishes full from empty

    assign count        = wptr - rptr;
    assign full         = (count == DEPTH);
    assign empty        = (count == 0);
    assign almost_full  = (count >= DEPTH - ALMOST);
    assign almost_empty = (count <= ALMOST);
    assign rdata        = mem[rptr[AW-1:0]];

    wire do_wr = wr_en & ~full;
    wire do_rd = rd_en & ~empty;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= 0;
            rptr <= 0;
        end else begin
            if (do_wr) begin
                mem[wptr[AW-1:0]] <= wdata;
                wptr <= wptr + 1'b1;
            end
            if (do_rd) rptr <= rptr + 1'b1;
        end
    end
endmodule
