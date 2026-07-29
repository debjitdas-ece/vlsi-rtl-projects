module axi4_system_top #(
    parameter ID_WIDTH          = 4,
    parameter OUTSTANDING_DEPTH = 4
) (
    input clk, rst_n,

    // ---- Master 0 command interface ----
    input                  cmd_valid_m0,
    output                 cmd_ready_m0,
    input                  cmd_op_m0,
    input  [31:0]          cmd_addr_m0,
    input  [7:0]           cmd_len_m0,
    input  [2:0]           cmd_size_m0,
    input  [1:0]           cmd_burst_m0,
    input  [ID_WIDTH-1:0]  cmd_id_m0,
    input  [31:0]          wdata_in_m0,
    input  [3:0]           wstrb_in_m0,
    output [31:0]          rdata_out_m0,
    output [1:0]           rresp_out_m0,
    output                 wr_resp_error_m0,
    output [ID_WIDTH-1:0]  wr_resp_error_id_m0,
    output                 rd_resp_error_m0,
    output [ID_WIDTH-1:0]  rd_resp_error_id_m0,

    // ---- Master 1 command interface (identical shape) ----
    input                  cmd_valid_m1,
    output                 cmd_ready_m1,
    input                  cmd_op_m1,
    input  [31:0]          cmd_addr_m1,
    input  [7:0]           cmd_len_m1,
    input  [2:0]           cmd_size_m1,
    input  [1:0]           cmd_burst_m1,
    input  [ID_WIDTH-1:0]  cmd_id_m1,
    input  [31:0]          wdata_in_m1,
    input  [3:0]           wstrb_in_m1,
    output [31:0]          rdata_out_m1,
    output [1:0]           rresp_out_m1,
    output                 wr_resp_error_m1,
    output [ID_WIDTH-1:0]  wr_resp_error_id_m1,
    output                 rd_resp_error_m1,
    output [ID_WIDTH-1:0]  rd_resp_error_id_m1
);

    // -----------------------------------------------------------------
    // internal AXI wires: master0 <-> interconnect
    // -----------------------------------------------------------------
    wire                 awvalid_m0, wvalid_m0, wlast_m0, bready_m0;
    wire [31:0]          awaddr_m0, wdata_m0;
    wire [7:0]           awlen_m0;
    wire [2:0]           awsize_m0;
    wire [1:0]           awburst_m0;
    wire [3:0]           wstrb_m0;
    wire [ID_WIDTH-1:0]  awid_m0;
    wire                 awready_m0, wready_m0, bvalid_m0;
    wire [1:0]           bresp_m0;
    wire [ID_WIDTH-1:0]  bid_m0;

    wire                 arvalid_m0, rready_m0;
    wire [31:0]          araddr_m0;
    wire [7:0]           arlen_m0;
    wire [2:0]           arsize_m0;
    wire [1:0]           arburst_m0;
    wire [ID_WIDTH-1:0]  arid_m0;
    wire                 arready_m0, rvalid_m0, rlast_m0;
    wire [31:0]          rdata_m0;
    wire [1:0]           rresp_m0;
    wire [ID_WIDTH-1:0]  rid_m0;

    // -----------------------------------------------------------------
    // internal AXI wires: master1 <-> interconnect (identical shape)
    // -----------------------------------------------------------------
    wire                 awvalid_m1, wvalid_m1, wlast_m1, bready_m1;
    wire [31:0]          awaddr_m1, wdata_m1;
    wire [7:0]           awlen_m1;
    wire [2:0]           awsize_m1;
    wire [1:0]           awburst_m1;
    wire [3:0]           wstrb_m1;
    wire [ID_WIDTH-1:0]  awid_m1;
    wire                 awready_m1, wready_m1, bvalid_m1;
    wire [1:0]           bresp_m1;
    wire [ID_WIDTH-1:0]  bid_m1;

    wire                 arvalid_m1, rready_m1;
    wire [31:0]          araddr_m1;
    wire [7:0]           arlen_m1;
    wire [2:0]           arsize_m1;
    wire [1:0]           arburst_m1;
    wire [ID_WIDTH-1:0]  arid_m1;
    wire                 arready_m1, rvalid_m1, rlast_m1;
    wire [31:0]          rdata_m1;
    wire [1:0]           rresp_m1;
    wire [ID_WIDTH-1:0]  rid_m1;

    // -----------------------------------------------------------------
    // internal AXI wires: interconnect <-> slave0
    // -----------------------------------------------------------------
    wire                 awvalid_s0, wvalid_s0, wlast_s0, bready_s0;
    wire [31:0]          awaddr_s0, wdata_s0;
    wire [7:0]           awlen_s0;
    wire [2:0]           awsize_s0;
    wire [1:0]           awburst_s0;
    wire [3:0]           wstrb_s0;
    wire [ID_WIDTH-1:0]  awid_s0;
    wire                 awready_s0, wready_s0, bvalid_s0;
    wire [1:0]           bresp_s0;
    wire [ID_WIDTH-1:0]  bid_s0;

    wire                 arvalid_s0;
    wire [31:0]          araddr_s0;
    wire [7:0]           arlen_s0;
    wire [2:0]           arsize_s0;
    wire [1:0]           arburst_s0;
    wire [ID_WIDTH-1:0]  arid_s0;
    wire                 arready_s0, rvalid_s0, rlast_s0;
    wire [31:0]          rdata_s0;
    wire [1:0]           rresp_s0;
    wire [ID_WIDTH-1:0]  rid_s0;
    wire                 rready_s0;

    // -----------------------------------------------------------------
    // internal AXI wires: interconnect <-> slave1 (identical shape)
    // -----------------------------------------------------------------
    wire                 awvalid_s1, wvalid_s1, wlast_s1, bready_s1;
    wire [31:0]          awaddr_s1, wdata_s1;
    wire [7:0]           awlen_s1;
    wire [2:0]           awsize_s1;
    wire [1:0]           awburst_s1;
    wire [3:0]           wstrb_s1;
    wire [ID_WIDTH-1:0]  awid_s1;
    wire                 awready_s1, wready_s1, bvalid_s1;
    wire [1:0]           bresp_s1;
    wire [ID_WIDTH-1:0]  bid_s1;

    wire                 arvalid_s1;
    wire [31:0]          araddr_s1;
    wire [7:0]           arlen_s1;
    wire [2:0]           arsize_s1;
    wire [1:0]           arburst_s1;
    wire [ID_WIDTH-1:0]  arid_s1;
    wire                 arready_s1, rvalid_s1, rlast_s1;
    wire [31:0]          rdata_s1;
    wire [1:0]           rresp_s1;
    wire [ID_WIDTH-1:0]  rid_s1;
    wire                 rready_s1;

    // -----------------------------------------------------------------
    // Master 0
    // -----------------------------------------------------------------
    axi4_master_top #(
        .ID_WIDTH(ID_WIDTH), .OUTSTANDING_DEPTH(OUTSTANDING_DEPTH)
    ) master0 (
        .clk(clk), .rst_n(rst_n),
        .cmd_valid(cmd_valid_m0), .cmd_ready(cmd_ready_m0), .cmd_op(cmd_op_m0),
        .cmd_addr(cmd_addr_m0), .cmd_len(cmd_len_m0), .cmd_size(cmd_size_m0),
        .cmd_burst(cmd_burst_m0), .cmd_id(cmd_id_m0),
        .awvalid(awvalid_m0), .awready(awready_m0), .awaddr(awaddr_m0), .awlen(awlen_m0),
        .awsize(awsize_m0), .awburst(awburst_m0), .awid(awid_m0),
        .wvalid(wvalid_m0), .wready(wready_m0), .wdata(wdata_m0), .wstrb(wstrb_m0), .wlast(wlast_m0),
        .wdata_in(wdata_in_m0), .wstrb_in(wstrb_in_m0),
        .bvalid(bvalid_m0), .bready(bready_m0), .bresp(bresp_m0), .bid(bid_m0),
        .arvalid(arvalid_m0), .arready(arready_m0), .araddr(araddr_m0), .arlen(arlen_m0),
        .arsize(arsize_m0), .arburst(arburst_m0), .arid(arid_m0),
        .rvalid(rvalid_m0), .rready(rready_m0), .rdata(rdata_m0), .rresp(rresp_m0),
        .rlast(rlast_m0), .rid(rid_m0), .rdata_out(rdata_out_m0), .rresp_out(rresp_out_m0),
        .wr_resp_error(wr_resp_error_m0), .wr_resp_error_id(wr_resp_error_id_m0),
        .rd_resp_error(rd_resp_error_m0), .rd_resp_error_id(rd_resp_error_id_m0)
    );

    // -----------------------------------------------------------------
    // Master 1
    // -----------------------------------------------------------------
    axi4_master_top #(
        .ID_WIDTH(ID_WIDTH), .OUTSTANDING_DEPTH(OUTSTANDING_DEPTH)
    ) master1 (
        .clk(clk), .rst_n(rst_n),
        .cmd_valid(cmd_valid_m1), .cmd_ready(cmd_ready_m1), .cmd_op(cmd_op_m1),
        .cmd_addr(cmd_addr_m1), .cmd_len(cmd_len_m1), .cmd_size(cmd_size_m1),
        .cmd_burst(cmd_burst_m1), .cmd_id(cmd_id_m1),
        .awvalid(awvalid_m1), .awready(awready_m1), .awaddr(awaddr_m1), .awlen(awlen_m1),
        .awsize(awsize_m1), .awburst(awburst_m1), .awid(awid_m1),
        .wvalid(wvalid_m1), .wready(wready_m1), .wdata(wdata_m1), .wstrb(wstrb_m1), .wlast(wlast_m1),
        .wdata_in(wdata_in_m1), .wstrb_in(wstrb_in_m1),
        .bvalid(bvalid_m1), .bready(bready_m1), .bresp(bresp_m1), .bid(bid_m1),
        .arvalid(arvalid_m1), .arready(arready_m1), .araddr(araddr_m1), .arlen(arlen_m1),
        .arsize(arsize_m1), .arburst(arburst_m1), .arid(arid_m1),
        .rvalid(rvalid_m1), .rready(rready_m1), .rdata(rdata_m1), .rresp(rresp_m1),
        .rlast(rlast_m1), .rid(rid_m1), .rdata_out(rdata_out_m1), .rresp_out(rresp_out_m1),
        .wr_resp_error(wr_resp_error_m1), .wr_resp_error_id(wr_resp_error_id_m1),
        .rd_resp_error(rd_resp_error_m1), .rd_resp_error_id(rd_resp_error_id_m1)
    );

    // -----------------------------------------------------------------
    // Interconnect
    // -----------------------------------------------------------------
    axi4_interconnect_top #(
        .ID_WIDTH(ID_WIDTH)
    ) interconnect (
        .clk(clk), .rst_n(rst_n),

        .awvalid_m0(awvalid_m0), .wvalid_m0(wvalid_m0), .wlast_m0(wlast_m0), .bready_m0(bready_m0),
        .awaddr_m0(awaddr_m0), .wdata_m0(wdata_m0), .awlen_m0(awlen_m0), .awsize_m0(awsize_m0),
        .awburst_m0(awburst_m0), .wstrb_m0(wstrb_m0), .awid_m0(awid_m0),
        .awready_m0(awready_m0), .wready_m0(wready_m0), .bvalid_m0(bvalid_m0),
        .bresp_m0(bresp_m0), .bid_m0(bid_m0),
        .arvalid_m0(arvalid_m0), .rready_m0(rready_m0), .araddr_m0(araddr_m0),
        .arlen_m0(arlen_m0), .arsize_m0(arsize_m0), .arburst_m0(arburst_m0), .arid_m0(arid_m0),
        .arready_m0(arready_m0), .rvalid_m0(rvalid_m0), .rlast_m0(rlast_m0),
        .rdata_m0(rdata_m0), .rresp_m0(rresp_m0), .rid_m0(rid_m0),

        .awvalid_m1(awvalid_m1), .wvalid_m1(wvalid_m1), .wlast_m1(wlast_m1), .bready_m1(bready_m1),
        .awaddr_m1(awaddr_m1), .wdata_m1(wdata_m1), .awlen_m1(awlen_m1), .awsize_m1(awsize_m1),
        .awburst_m1(awburst_m1), .wstrb_m1(wstrb_m1), .awid_m1(awid_m1),
        .awready_m1(awready_m1), .wready_m1(wready_m1), .bvalid_m1(bvalid_m1),
        .bresp_m1(bresp_m1), .bid_m1(bid_m1),
        .arvalid_m1(arvalid_m1), .rready_m1(rready_m1), .araddr_m1(araddr_m1),
        .arlen_m1(arlen_m1), .arsize_m1(arsize_m1), .arburst_m1(arburst_m1), .arid_m1(arid_m1),
        .arready_m1(arready_m1), .rvalid_m1(rvalid_m1), .rlast_m1(rlast_m1),
        .rdata_m1(rdata_m1), .rresp_m1(rresp_m1), .rid_m1(rid_m1),

        .awvalid_s0(awvalid_s0), .wvalid_s0(wvalid_s0), .wlast_s0(wlast_s0), .bready_s0(bready_s0),
        .awaddr_s0(awaddr_s0), .wdata_s0(wdata_s0), .awlen_s0(awlen_s0), .awsize_s0(awsize_s0),
        .awburst_s0(awburst_s0), .wstrb_s0(wstrb_s0), .awid_s0(awid_s0),
        .awready_s0(awready_s0), .wready_s0(wready_s0), .bvalid_s0(bvalid_s0),
        .bresp_s0(bresp_s0), .bid_s0(bid_s0),
        .arvalid_s0(arvalid_s0), .araddr_s0(araddr_s0), .arlen_s0(arlen_s0),
        .arsize_s0(arsize_s0), .arburst_s0(arburst_s0), .arid_s0(arid_s0),
        .arready_s0(arready_s0), .rvalid_s0(rvalid_s0), .rlast_s0(rlast_s0),
        .rdata_s0(rdata_s0), .rresp_s0(rresp_s0), .rid_s0(rid_s0), .rready_s0(rready_s0),

        .awvalid_s1(awvalid_s1), .wvalid_s1(wvalid_s1), .wlast_s1(wlast_s1), .bready_s1(bready_s1),
        .awaddr_s1(awaddr_s1), .wdata_s1(wdata_s1), .awlen_s1(awlen_s1), .awsize_s1(awsize_s1),
        .awburst_s1(awburst_s1), .wstrb_s1(wstrb_s1), .awid_s1(awid_s1),
        .awready_s1(awready_s1), .wready_s1(wready_s1), .bvalid_s1(bvalid_s1),
        .bresp_s1(bresp_s1), .bid_s1(bid_s1),
        .arvalid_s1(arvalid_s1), .araddr_s1(araddr_s1), .arlen_s1(arlen_s1),
        .arsize_s1(arsize_s1), .arburst_s1(arburst_s1), .arid_s1(arid_s1),
        .arready_s1(arready_s1), .rvalid_s1(rvalid_s1), .rlast_s1(rlast_s1),
        .rdata_s1(rdata_s1), .rresp_s1(rresp_s1), .rid_s1(rid_s1), .rready_s1(rready_s1)
    );

    // -----------------------------------------------------------------
    // Slave 0 -- default parameters (Slave 0's own region, from axi_pkg.v)
    // -----------------------------------------------------------------
    axi4_slave_top #(
        .ID_WIDTH(ID_WIDTH)
    ) slave0 (
        .clk(clk), .rst_n(rst_n),
        .awvalid(awvalid_s0), .awready(awready_s0), .awaddr(awaddr_s0), .awlen(awlen_s0),
        .awsize(awsize_s0), .awburst(awburst_s0), .awid(awid_s0),
        .wvalid(wvalid_s0), .wready(wready_s0), .wdata(wdata_s0), .wstrb(wstrb_s0), .wlast(wlast_s0),
        .bvalid(bvalid_s0), .bready(bready_s0), .bresp(bresp_s0), .bid(bid_s0),
        .arvalid(arvalid_s0), .arready(arready_s0), .araddr(araddr_s0), .arlen(arlen_s0),
        .arsize(arsize_s0), .arburst(arburst_s0), .arid(arid_s0),
        .rvalid(rvalid_s0), .rready(rready_s0), .rdata(rdata_s0), .rresp(rresp_s0),
        .rlast(rlast_s0), .rid(rid_s0)
    );

    // -----------------------------------------------------------------
    // Slave 1 -- overridden region (Slave 1's own base/limit) -- the
    // one place a parameter override actually matters in this file,
    // since both slave instances use the identical module
    // -----------------------------------------------------------------
    axi4_slave_top #(
        .ID_WIDTH(ID_WIDTH),
        .REGION_BASE(`SLAVE1_BASE),
        .REGION_LIMIT(`SLAVE1_LIMIT)
    ) slave1 (
        .clk(clk), .rst_n(rst_n),
        .awvalid(awvalid_s1), .awready(awready_s1), .awaddr(awaddr_s1), .awlen(awlen_s1),
        .awsize(awsize_s1), .awburst(awburst_s1), .awid(awid_s1),
        .wvalid(wvalid_s1), .wready(wready_s1), .wdata(wdata_s1), .wstrb(wstrb_s1), .wlast(wlast_s1),
        .bvalid(bvalid_s1), .bready(bready_s1), .bresp(bresp_s1), .bid(bid_s1),
        .arvalid(arvalid_s1), .arready(arready_s1), .araddr(araddr_s1), .arlen(arlen_s1),
        .arsize(arsize_s1), .arburst(arburst_s1), .arid(arid_s1),
        .rvalid(rvalid_s1), .rready(rready_s1), .rdata(rdata_s1), .rresp(rresp_s1),
        .rlast(rlast_s1), .rid(rid_s1)
    );

endmodule