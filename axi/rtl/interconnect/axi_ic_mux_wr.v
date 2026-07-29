module axi_ic_mux_wr #(
    parameter ID_WIDTH = 4
) (
    input clk, rst_n,

    // Master 0
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

    // Master 1 (identical shape)
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

    // Slave 0
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

    // Slave 1 (identical shape)
    output                 awvalid_s1, wvalid_s1, wlast_s1, bready_s1,
    output [31:0]          awaddr_s1, wdata_s1,
    output [7:0]           awlen_s1,
    output [2:0]           awsize_s1,
    output [1:0]           awburst_s1,
    output [3:0]           wstrb_s1,
    output [ID_WIDTH-1:0]  awid_s1,
    input                  awready_s1, wready_s1, bvalid_s1,
    input  [1:0]           bresp_s1,
    input  [ID_WIDTH-1:0]  bid_s1
);
    wire slave_sel_m0, addr_valid_m0, slave_sel_m1, addr_valid_m1;
    reg  owner_s0_valid, owner_s1_valid, owner_s0_id, owner_s1_id;
    wire [1:0] grant_s0, grant_s1;

    axi_ic_addr_map addr_map_m0 (.addr(awaddr_m0), .slave_sel(slave_sel_m0), .addr_valid(addr_valid_m0));
    axi_ic_addr_map addr_map_m1 (.addr(awaddr_m1), .slave_sel(slave_sel_m1), .addr_valid(addr_valid_m1));

    wire [1:0] req_s0 = { (awvalid_m1 && !slave_sel_m1 && addr_valid_m1 && !owner_s0_valid), (awvalid_m0 && !slave_sel_m0 && addr_valid_m0 && !owner_s0_valid) };
    wire [1:0] req_s1 = { (awvalid_m1 &&  slave_sel_m1 && addr_valid_m1 && !owner_s1_valid), (awvalid_m0 &&  slave_sel_m0 && addr_valid_m0 && !owner_s1_valid) };

    axi_ic_arbiter arb_s0 (.clk(clk), .rst_n(rst_n), .req(req_s0), .grant(grant_s0));
    axi_ic_arbiter arb_s1 (.clk(clk), .rst_n(rst_n), .req(req_s1), .grant(grant_s1));

    always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        owner_s0_valid <= 1'b0; owner_s0_id <= 1'b0;
        owner_s1_valid <= 1'b0; owner_s1_id <= 1'b0;
    end else begin
        owner_s0_valid <= (!owner_s0_valid && grant_s0 != 2'b00) ? 1'b1 : (owner_s0_valid && bvalid_s0 && bready_s0) ? 1'b0 : owner_s0_valid;
        owner_s0_id    <= (!owner_s0_valid && grant_s0 != 2'b00) ? grant_s0[1] : owner_s0_id;

        owner_s1_valid <= (!owner_s1_valid && grant_s1 != 2'b00) ? 1'b1 : (owner_s1_valid && bvalid_s1 && bready_s1) ? 1'b0 : owner_s1_valid;
        owner_s1_id    <= (!owner_s1_valid && grant_s1 != 2'b00) ? grant_s1[1] : owner_s1_id;
    end
end

    wire route_sel_s0    = owner_s0_valid ? owner_s0_id : grant_s0[1];
    wire route_active_s0 = owner_s0_valid || (grant_s0 != 2'b00);
    wire route_sel_s1    = owner_s1_valid ? owner_s1_id : grant_s1[1];
    wire route_active_s1 = owner_s1_valid || (grant_s1 != 2'b00);

    assign {awvalid_s0, awaddr_s0, awlen_s0, awsize_s0, awburst_s0, awid_s0} = route_sel_s0 ? {route_active_s0 && awvalid_m1, awaddr_m1, awlen_m1, awsize_m1, awburst_m1, awid_m1} : {route_active_s0 && awvalid_m0, awaddr_m0, awlen_m0, awsize_m0, awburst_m0, awid_m0};

    assign {awvalid_s1, awaddr_s1, awlen_s1, awsize_s1, awburst_s1, awid_s1} = route_sel_s1 ? {route_active_s1 && awvalid_m1, awaddr_m1, awlen_m1, awsize_m1, awburst_m1, awid_m1} : {route_active_s1 && awvalid_m0, awaddr_m0, awlen_m0, awsize_m0, awburst_m0, awid_m0};

    assign {wvalid_s0, wdata_s0, wstrb_s0, wlast_s0, bready_s0} = owner_s0_id ? {owner_s0_valid && wvalid_m1, wdata_m1, wstrb_m1, wlast_m1, owner_s0_valid && bready_m1} : {owner_s0_valid && wvalid_m0, wdata_m0, wstrb_m0, wlast_m0, owner_s0_valid && bready_m0};

    assign {wvalid_s1, wdata_s1, wstrb_s1, wlast_s1, bready_s1} = owner_s1_id ? {owner_s1_valid && wvalid_m1, wdata_m1, wstrb_m1, wlast_m1, owner_s1_valid && bready_m1} : {owner_s1_valid && wvalid_m0, wdata_m0, wstrb_m0, wlast_m0, owner_s1_valid && bready_m0};

    assign awready_m0 = (route_active_s0 && !route_sel_s0) ? awready_s0 : (route_active_s1 && !route_sel_s1) ? awready_s1 : 1'b0;
    assign awready_m1 = (route_active_s0 &&  route_sel_s0) ? awready_s0 : (route_active_s1 &&  route_sel_s1) ? awready_s1 : 1'b0;


    wire m0_owns_s0 = owner_s0_valid && !owner_s0_id;
    wire m0_owns_s1 = owner_s1_valid && !owner_s1_id;
    wire m1_owns_s0 = owner_s0_valid &&  owner_s0_id;
    wire m1_owns_s1 = owner_s1_valid &&  owner_s1_id;

    assign {wready_m0, bvalid_m0, bresp_m0, bid_m0} = m0_owns_s0 ? {wready_s0, bvalid_s0, bresp_s0, bid_s0} : m0_owns_s1 ? {wready_s1, bvalid_s1, bresp_s1, bid_s1} : {1'b0, 1'b0, 2'b00, {ID_WIDTH{1'b0}}};

    assign {wready_m1, bvalid_m1, bresp_m1, bid_m1} = m1_owns_s0 ? {wready_s0, bvalid_s0, bresp_s0, bid_s0} : m1_owns_s1 ? {wready_s1, bvalid_s1, bresp_s1, bid_s1} : {1'b0, 1'b0, 2'b00, {ID_WIDTH{1'b0}}};

endmodule