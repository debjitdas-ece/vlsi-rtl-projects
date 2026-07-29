module axi4_slave_top #(
    parameter ID_WIDTH     = 3,
    parameter REGION_BASE  = `SLAVE0_BASE,
    parameter REGION_LIMIT = `SLAVE0_LIMIT
) (
    input  wire clk, rst_n,

    input  wire                  awvalid,
    output wire                  awready,
    input  wire [31:0]           awaddr,
    input  wire [7:0]            awlen,
    input  wire [2:0]            awsize,
    input  wire [1:0]            awburst,
    input  wire [ID_WIDTH-1:0]   awid,

    input  wire                  wvalid,
    output wire                  wready,
    input  wire [31:0]           wdata,
    input  wire [3:0]            wstrb,
    input  wire                  wlast,


    output wire                  bvalid,
    input  wire                  bready,
    output wire [1:0]            bresp,
    output wire [ID_WIDTH-1:0]   bid,


    input  wire                  arvalid,
    output wire                  arready,
    input  wire [31:0]           araddr,
    input  wire [7:0]            arlen,
    input  wire [2:0]            arsize,
    input  wire [1:0]            arburst,
    input  wire [ID_WIDTH-1:0]   arid,


    output wire                  rvalid,
    input  wire                  rready,
    output wire [31:0]           rdata,
    output wire [1:0]            rresp,
    output wire                  rlast,
    output wire [ID_WIDTH-1:0]   rid
);

    wire        decode_error_wr, decode_error_rd;
    wire        wr_en;
    wire [31:0] wr_cur_addr, rd_cur_addr;
    wire [31:0] regmap_old_data, regmap_rd_data;
    wire [31:0] merged_wr_data;


    axi_addr_decode #(
        .REGION_BASE (REGION_BASE),
        .REGION_LIMIT(REGION_LIMIT)
    ) addr_decode_wr (
        .addr          (awaddr),
        .len           (awlen),
        .size          (awsize),
        .region_hit    (),
        .boundary_okay (),
        .decode_error  (decode_error_wr)
    );

    axi_addr_decode #(
        .REGION_BASE (REGION_BASE),
        .REGION_LIMIT(REGION_LIMIT)
    ) addr_decode_rd (
        .addr          (araddr),
        .len           (arlen),
        .size          (arsize),
        .region_hit    (),
        .boundary_okay (),
        .decode_error  (decode_error_rd)
    );

    axi_wr_fsm #(
        .ID_WIDTH(ID_WIDTH)
    ) wr_fsm (
        .clk          (clk),
        .rst_n        (rst_n),
        .awvalid      (awvalid),
        .awaddr       (awaddr),
        .awlen        (awlen),
        .awsize       (awsize),
        .awburst      (awburst),
        .awid         (awid),
        .awready      (awready),
        .wvalid       (wvalid),
        .wdata        (wdata),
        .wstrb        (wstrb),
        .wlast        (wlast),
        .wready       (wready),
        .bvalid       (bvalid),
        .bresp        (bresp),
        .bid          (bid),
        .bready       (bready),
        .decode_error (decode_error_wr),
        .cur_addr     (wr_cur_addr),
        .wr_en        (wr_en)
    );
    axi_rd_fsm #(
        .ID_WIDTH(ID_WIDTH)
    ) rd_fsm (
        .clk          (clk),
        .rst_n        (rst_n),
        .arvalid      (arvalid),
        .araddr       (araddr),
        .arlen        (arlen),
        .arsize       (arsize),
        .arburst      (arburst),
        .arid         (arid),
        .arready      (arready),
        .rready       (rready),
        .decode_err_in(decode_error_rd),
        .regmap_rdata (regmap_rd_data),
        .rvalid       (rvalid),
        .rlast        (rlast),
        .rresp        (rresp),
        .rid          (rid),
        .cur_addr     (rd_cur_addr),
        .rdata        (rdata)
    );

    axi_wstrb_merge wstrb_merge (
        .wdata       (wdata),
        .old_data    (regmap_old_data),
        .wstrb       (wstrb),
        .merged_data (merged_wr_data)
    );
    axi_regmap #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .NUM_WORDS (1024)
    ) regmap (
        .clk      (clk),
        .wr_en    (wr_en),
        .wr_addr  (wr_cur_addr),
        .wr_data  (merged_wr_data),
        .rd_addr  (rd_cur_addr),
        .rd_data  (regmap_rd_data),
        .old_data (regmap_old_data)
    );

endmodule