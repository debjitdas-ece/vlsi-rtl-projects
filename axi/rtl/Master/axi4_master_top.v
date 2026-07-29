module axi4_master_top #(
    parameter ID_WIDTH          = 4,
    parameter OUTSTANDING_DEPTH = 4
) (
    input clk, rst_n,

    // command interface
    input                  cmd_valid,
    output                 cmd_ready,
    input                  cmd_op,
    input  [31:0]          cmd_addr,
    input  [7:0]           cmd_len,
    input  [2:0]           cmd_size,
    input  [1:0]           cmd_burst,
    input  [ID_WIDTH-1:0]  cmd_id,

    // AW
    output                 awvalid,
    input                  awready,
    output [31:0]          awaddr,
    output [7:0]           awlen,
    output [2:0]           awsize,
    output [1:0]           awburst,
    output [ID_WIDTH-1:0]  awid,

    // W
    output                 wvalid,
    input                  wready,
    output [31:0]          wdata,
    output [3:0]           wstrb,
    output                 wlast,
    input  [31:0]          wdata_in,
    input  [3:0]           wstrb_in,

    // B
    input                  bvalid,
    output                 bready,
    input  [1:0]           bresp,
    input  [ID_WIDTH-1:0]  bid,

    // AR
    output                 arvalid,
    input                  arready,
    output [31:0]          araddr,
    output [7:0]           arlen,
    output [2:0]           arsize,
    output [1:0]           arburst,
    output [ID_WIDTH-1:0]  arid,

    // R
    input                  rvalid,
    output                 rready,
    input  [31:0]          rdata,
    input  [1:0]           rresp,
    input                  rlast,
    input  [ID_WIDTH-1:0]  rid,
    output [31:0]          rdata_out,
    output [1:0]           rresp_out,

    // diagnostics
    output                 wr_resp_error,
    output [ID_WIDTH-1:0]  wr_resp_error_id,
    output                 rd_resp_error,
    output [ID_WIDTH-1:0]  rd_resp_error_id
);

    // -----------------------------------------------------------------
    // internal wires
    // -----------------------------------------------------------------
    wire wr_fifo_push_valid, wr_fifo_push_ready;
    wire [31:0] wr_fifo_push_addr;
    wire [7:0]  wr_fifo_push_len;
    wire [2:0]  wr_fifo_push_size;
    wire [1:0]  wr_fifo_push_burst;
    wire [ID_WIDTH-1:0] wr_fifo_push_id;

    wire rd_fifo_push_valid, rd_fifo_push_ready;
    wire [31:0] rd_fifo_push_addr;
    wire [7:0]  rd_fifo_push_len;
    wire [2:0]  rd_fifo_push_size;
    wire [1:0]  rd_fifo_push_burst;
    wire [ID_WIDTH-1:0] rd_fifo_push_id;

    wire wr_pop_valid, wr_pop_ready;
    wire [31:0] wr_pop_addr;
    wire [7:0]  wr_pop_len;
    wire [2:0]  wr_pop_size;
    wire [1:0]  wr_pop_burst;
    wire [ID_WIDTH-1:0] wr_pop_id;

    wire rd_pop_valid, rd_pop_ready;
    wire [7:0]  rd_pop_len;
    wire [ID_WIDTH-1:0] rd_pop_id;

    wire wr_complete_valid, rd_complete_valid;
    wire [ID_WIDTH-1:0] wr_complete_id, rd_complete_id;

    // -----------------------------------------------------------------
    // cmd_fsm -- dispatches AW/AR, gated by two internal id_tracker
    // instances, pushes onto the matching direction's FIFO
    // -----------------------------------------------------------------
    axi_master_cmd_fsm #(
        .ID_WIDTH(ID_WIDTH), .OUTSTANDING_DEPTH(OUTSTANDING_DEPTH)
    ) cmd_fsm (
        .clk(clk), .rst_n(rst_n),
        .cmd_valid(cmd_valid), .cmd_op(cmd_op),
        .awready(awready), .arready(arready),
        .wr_fifo_push_ready(wr_fifo_push_ready), .rd_fifo_push_ready(rd_fifo_push_ready),
        .wr_complete_valid(wr_complete_valid), .rd_complete_valid(rd_complete_valid),
        .cmd_addr(cmd_addr), .cmd_len(cmd_len), .cmd_size(cmd_size),
        .cmd_burst(cmd_burst), .cmd_id(cmd_id),
        .wr_complete_id(wr_complete_id), .rd_complete_id(rd_complete_id),
        .cmd_ready(cmd_ready), .awvalid(awvalid), .arvalid(arvalid),
        .wr_fifo_push_valid(wr_fifo_push_valid), .rd_fifo_push_valid(rd_fifo_push_valid),
        .awaddr(awaddr), .araddr(araddr),
        .wr_fifo_push_addr(wr_fifo_push_addr), .rd_fifo_push_addr(rd_fifo_push_addr),
        .awlen(awlen), .arlen(arlen),
        .wr_fifo_push_len(wr_fifo_push_len), .rd_fifo_push_len(rd_fifo_push_len),
        .awsize(awsize), .arsize(arsize),
        .wr_fifo_push_size(wr_fifo_push_size), .rd_fifo_push_size(rd_fifo_push_size),
        .awburst(awburst), .arburst(arburst),
        .wr_fifo_push_burst(wr_fifo_push_burst), .rd_fifo_push_burst(rd_fifo_push_burst),
        .awid(awid), .arid(arid),
        .wr_fifo_push_id(wr_fifo_push_id), .rd_fifo_push_id(rd_fifo_push_id)
    );

    // -----------------------------------------------------------------
    // write-side pending FIFO
    // -----------------------------------------------------------------
    axi_master_pending_fifo #(
        .DEPTH(OUTSTANDING_DEPTH), .ID_WIDTH(ID_WIDTH)
    ) wr_fifo (
        .clk(clk), .rst_n(rst_n),
        .push_valid(wr_fifo_push_valid), .pop_valid(wr_pop_valid),
        .push_addr(wr_fifo_push_addr), .push_len(wr_fifo_push_len),
        .push_size(wr_fifo_push_size), .push_burst(wr_fifo_push_burst),
        .push_id(wr_fifo_push_id),
        .push_ready(wr_fifo_push_ready), .pop_ready(wr_pop_ready),
        .pop_addr(wr_pop_addr), .pop_len(wr_pop_len),
        .pop_size(wr_pop_size), .pop_burst(wr_pop_burst), .pop_id(wr_pop_id)
    );

    // -----------------------------------------------------------------
    // read-side pending FIFO -- rd_fsm only needs pop_len/pop_id, the
    // other pop_* outputs are simply left unconnected
    // -----------------------------------------------------------------
    axi_master_pending_fifo #(
        .DEPTH(OUTSTANDING_DEPTH), .ID_WIDTH(ID_WIDTH)
    ) rd_fifo (
        .clk(clk), .rst_n(rst_n),
        .push_valid(rd_fifo_push_valid), .pop_valid(rd_pop_valid),
        .push_addr(rd_fifo_push_addr), .push_len(rd_fifo_push_len),
        .push_size(rd_fifo_push_size), .push_burst(rd_fifo_push_burst),
        .push_id(rd_fifo_push_id),
        .push_ready(rd_fifo_push_ready), .pop_ready(rd_pop_ready),
        .pop_addr(), .pop_len(rd_pop_len),
        .pop_size(), .pop_burst(), .pop_id(rd_pop_id)
    );

    // -----------------------------------------------------------------
    // write FSM -- pops from wr_fifo, drives W/B, forwards wdata_in/
    // wstrb_in live per beat (this module stores no data payload itself)
    // -----------------------------------------------------------------
    axi_master_wr_fsm #(
        .ID_WIDTH(ID_WIDTH)
    ) wr_fsm (
        .clk(clk), .rst_n(rst_n),
        .pop_ready(wr_pop_ready), .wready(wready), .bvalid(bvalid),
        .pop_addr(wr_pop_addr), .wdata_in(wdata_in),
        .pop_len(wr_pop_len), .pop_size(wr_pop_size), .pop_burst(wr_pop_burst),
        .bresp(bresp), .pop_id(wr_pop_id), .bid(bid), .wstrb_in(wstrb_in),
        .pop_valid(wr_pop_valid), .wvalid(wvalid), .wlast(wlast),
        .bready(bready), .wr_complete_valid(wr_complete_valid),
        .wdata_out(wdata), .cur_addr(), .wstrb_out(wstrb),
        .wr_complete_id(wr_complete_id)
    );

    // -----------------------------------------------------------------
    // read FSM -- pops from rd_fifo, accepts R beats, forwards rdata/
    // rresp out. No axi_burst_calc here -- the slave walks the burst,
    // this FSM is purely a receiver.
    // -----------------------------------------------------------------
    axi_master_rd_fsm #(
        .ID_WIDTH(ID_WIDTH)
    ) rd_fsm (
        .clk(clk), .rst_n(rst_n),
        .pop_ready(rd_pop_ready), .rvalid(rvalid), .rlast(rlast),
        .rresp(rresp), .rdata(rdata), .rid(rid), .pop_id(rd_pop_id),
        .pop_len(rd_pop_len),
        .pop_valid(rd_pop_valid), .rready(rready),
        .rd_complete_valid(rd_complete_valid),
        .rdata_out(rdata_out), .rresp_out(rresp_out),
        .rd_complete_id(rd_complete_id)
    );

    // -----------------------------------------------------------------
    // response check -- diagnostic only, does not gate any control flow
    // -----------------------------------------------------------------
    axi_master_resp_check #(
        .ID_WIDTH(ID_WIDTH)
    ) resp_check (
        .wr_complete_valid(wr_complete_valid), .rd_complete_valid(rd_complete_valid),
        .wr_complete_id(wr_complete_id), .rd_complete_id(rd_complete_id),
        .bresp(bresp), .rresp(rresp),
        .wr_resp_error(wr_resp_error), .rd_resp_error(rd_resp_error),
        .wr_resp_error_id(wr_resp_error_id), .rd_resp_error_id(rd_resp_error_id)
    );

endmodule
