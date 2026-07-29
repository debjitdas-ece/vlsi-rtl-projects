module axi_regmap #(
    parameter ADDR_WIDTH = 32, DATA_WIDTH = 32, NUM_WORDS = 1024
) (
    input clk, wr_en,
    input  [ADDR_WIDTH-1:0] wr_addr, rd_addr,
    input  [DATA_WIDTH-1:0] wr_data,
    output [DATA_WIDTH-1:0] rd_data, old_data
);
    localparam WB = $clog2(NUM_WORDS);
    reg [DATA_WIDTH-1:0] mem [0:NUM_WORDS-1];
    wire [WB-1:0] wr_idx = wr_addr[WB+1:2];
    wire [WB-1:0] rd_idx = rd_addr[WB+1:2];

    always @(posedge clk) if (wr_en) mem[wr_idx] <= wr_data;

    assign rd_data  = mem[rd_idx];
    assign old_data = mem[wr_idx];
endmodule