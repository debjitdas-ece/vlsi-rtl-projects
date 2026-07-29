module axi4_interconnect_top #(
    parameter ID_WIDTH = 4
) (
    input clk, rst_n,

    // Master 0 -- full AXI4 interface (AW/W/B/AR/R)
    input                  awvalid_m0, wvalid_m0, wlast_m0, bready_m0,
    input  [31:0]          awaddr_m0, wdata_m0,
    input  [7:0]           awlen_m0,
    input  [2:0]           awsize_m0,
    input  [1:0]           awburst_m0,
    input  [3:0]           wstrb_m0,
    input  [ID_WIDTH-1:0]  awid_m0,
    output                 awready_m0, wready_m0, bvalid_m0,
    output [1:0]           bresp_m0,
    output [ID_WIDTH-1:0]  bid_m0,

    input                  arvalid_m0, rready_m0,
    input  [31:0]          araddr_m0,
    input  [7:0]           arlen_m0,
    input  [2:0]           arsize_m0,
    input  [1:0]           arburst_m0,
    input  [ID_WIDTH-1:0]  arid_m0,
    output                 arready_m0, rvalid_m0, rlast_m0,
    output [31:0]          rdata_m0,
    output [1:0]           rresp_m0,
    output [ID_WIDTH-1:0]  rid_m0,

    // Master 1 -- identical shape to Master 0
    input                  awvalid_m1, wvalid_m1, wlast_m1, bready_m1,
    input  [31:0]          awaddr_m1, wdata_m1,
    input  [7:0]           awlen_m1,
    input  [2:0]           awsize_m1,
    input  [1:0]           awburst_m1,
    input  [3:0]           wstrb_m1,
    input  [ID_WIDTH-1:0]  awid_m1,
    output                 awready_m1, wready_m1, bvalid_m1,
    output [1:0]           bresp_m1,
    output [ID_WIDTH-1:0]  bid_m1,

    input                  arvalid_m1, rready_m1,
    input  [31:0]          araddr_m1,
    input  [7:0]           arlen_m1,
    input  [2:0]           arsize_m1,
    input  [1:0]           arburst_m1,
    input  [ID_WIDTH-1:0]  arid_m1,
    output                 arready_m1, rvalid_m1, rlast_m1,
    output [31:0]          rdata_m1,
    output [1:0]           rresp_m1,
    output [ID_WIDTH-1:0]  rid_m1,

    // Slave 0 -- full AXI4 interface, opposite direction from masters
    output                 awvalid_s0, wvalid_s0, wlast_s0, bready_s0,
    output [31:0]          awaddr_s0, wdata_s0,
    output [7:0]           awlen_s0,
    output [2:0]           awsize_s0,
    output [1:0]           awburst_s0,
    output [3:0]           wstrb_s0,
    output [ID_WIDTH-1:0]  awid_s0,
    input                  awready_s0, wready_s0, bvalid_s0,
    input  [1:0]           bresp_s0,
    input  [ID_WIDTH-1:0]  bid_s0,

    output                 arvalid_s0,
    output [31:0]          araddr_s0,
    output [7:0]           arlen_s0,
    output [2:0]           arsize_s0,
    output [1:0]           arburst_s0,
    output [ID_WIDTH-1:0]  arid_s0,
    input                  arready_s0, rvalid_s0, rlast_s0,
    input  [31:0]          rdata_s0,
    input  [1:0]           rresp_s0,
    input  [ID_WIDTH-1:0]  rid_s0,
    output                 rready_s0,

    // Slave 1 -- identical shape to Slave 0
    output                 awvalid_s1, wvalid_s1, wlast_s1, bready_s1,
    output [31:0]          awaddr_s1, wdata_s1,
    output [7:0]           awlen_s1,
    output [2:0]           awsize_s1,
    output [1:0]           awburst_s1,
    output [3:0]           wstrb_s1,
    output [ID_WIDTH-1:0]  awid_s1,
    input                  awready_s1, wready_s1, bvalid_s1,
    input  [1:0]           bresp_s1,
    input  [ID_WIDTH-1:0]  bid_s1,

    output                 arvalid_s1,
    output [31:0]          araddr_s1,
    output [7:0]           arlen_s1,
    output [2:0]           arsize_s1,
    output [1:0]           arburst_s1,
    output [ID_WIDTH-1:0]  arid_s1,
    input                  arready_s1, rvalid_s1, rlast_s1,
    input  [31:0]          rdata_s1,
    input  [1:0]           rresp_s1,
    input  [ID_WIDTH-1:0]  rid_s1,
    output                 rready_s1
);
    axi_ic_mux_wr #(.ID_WIDTH(ID_WIDTH)) mux_wr (
        .clk(clk), .rst_n(rst_n),

        .awvalid_m0(awvalid_m0), .wvalid_m0(wvalid_m0), .wlast_m0(wlast_m0), .bready_m0(bready_m0),
        .awaddr_m0(awaddr_m0), .wdata_m0(wdata_m0), .awlen_m0(awlen_m0), .awsize_m0(awsize_m0),
        .awburst_m0(awburst_m0), .wstrb_m0(wstrb_m0), .awid_m0(awid_m0),
        .awready_m0(awready_m0), .wready_m0(wready_m0), .bvalid_m0(bvalid_m0),
        .bresp_m0(bresp_m0), .bid_m0(bid_m0),

        .awvalid_m1(awvalid_m1), .wvalid_m1(wvalid_m1), .wlast_m1(wlast_m1), .bready_m1(bready_m1),
        .awaddr_m1(awaddr_m1), .wdata_m1(wdata_m1), .awlen_m1(awlen_m1), .awsize_m1(awsize_m1),
        .awburst_m1(awburst_m1), .wstrb_m1(wstrb_m1), .awid_m1(awid_m1),
        .awready_m1(awready_m1), .wready_m1(wready_m1), .bvalid_m1(bvalid_m1),
        .bresp_m1(bresp_m1), .bid_m1(bid_m1),

        .awvalid_s0(awvalid_s0), .wvalid_s0(wvalid_s0), .wlast_s0(wlast_s0), .bready_s0(bready_s0),
        .awaddr_s0(awaddr_s0), .wdata_s0(wdata_s0), .awlen_s0(awlen_s0), .awsize_s0(awsize_s0),
        .awburst_s0(awburst_s0), .wstrb_s0(wstrb_s0), .awid_s0(awid_s0),
        .awready_s0(awready_s0), .wready_s0(wready_s0), .bvalid_s0(bvalid_s0),
        .bresp_s0(bresp_s0), .bid_s0(bid_s0),

        .awvalid_s1(awvalid_s1), .wvalid_s1(wvalid_s1), .wlast_s1(wlast_s1), .bready_s1(bready_s1),
        .awaddr_s1(awaddr_s1), .wdata_s1(wdata_s1), .awlen_s1(awlen_s1), .awsize_s1(awsize_s1),
        .awburst_s1(awburst_s1), .wstrb_s1(wstrb_s1), .awid_s1(awid_s1),
        .awready_s1(awready_s1), .wready_s1(wready_s1), .bvalid_s1(bvalid_s1),
        .bresp_s1(bresp_s1), .bid_s1(bid_s1)
    );

    axi_ic_mux_rd #(.ID_WIDTH(ID_WIDTH)) mux_rd (
        .clk(clk), .rst_n(rst_n),

        .arvalid_m0(arvalid_m0), .rready_m0(rready_m0), .araddr_m0(araddr_m0),
        .arlen_m0(arlen_m0), .arsize_m0(arsize_m0), .arburst_m0(arburst_m0), .arid_m0(arid_m0),
        .arready_m0(arready_m0), .rvalid_m0(rvalid_m0), .rlast_m0(rlast_m0),
        .rdata_m0(rdata_m0), .rresp_m0(rresp_m0), .rid_m0(rid_m0),

        .arvalid_m1(arvalid_m1), .rready_m1(rready_m1), .araddr_m1(araddr_m1),
        .arlen_m1(arlen_m1), .arsize_m1(arsize_m1), .arburst_m1(arburst_m1), .arid_m1(arid_m1),
        .arready_m1(arready_m1), .rvalid_m1(rvalid_m1), .rlast_m1(rlast_m1),
        .rdata_m1(rdata_m1), .rresp_m1(rresp_m1), .rid_m1(rid_m1),

        .arvalid_s0(arvalid_s0), .araddr_s0(araddr_s0), .arlen_s0(arlen_s0),
        .arsize_s0(arsize_s0), .arburst_s0(arburst_s0), .arid_s0(arid_s0),
        .arready_s0(arready_s0), .rvalid_s0(rvalid_s0), .rlast_s0(rlast_s0),
        .rdata_s0(rdata_s0), .rresp_s0(rresp_s0), .rid_s0(rid_s0), .rready_s0(rready_s0),

        .arvalid_s1(arvalid_s1), .araddr_s1(araddr_s1), .arlen_s1(arlen_s1),
        .arsize_s1(arsize_s1), .arburst_s1(arburst_s1), .arid_s1(arid_s1),
        .arready_s1(arready_s1), .rvalid_s1(rvalid_s1), .rlast_s1(rlast_s1),
        .rdata_s1(rdata_s1), .rresp_s1(rresp_s1), .rid_s1(rid_s1), .rready_s1(rready_s1)
    );

endmodule