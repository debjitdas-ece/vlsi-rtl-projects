module axi_ic_mux_rd #(
    parameter ID_WIDTH = 4
) (
    input clk, rst_n,

    // Master 0
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

    // Master 1 (identical shape)
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

    // Slave 0
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

    // Slave 1 (identical shape)
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
    wire slave_sel_m0, addr_valid_m0, slave_sel_m1, addr_valid_m1;
    reg  owner_s0_valid, owner_s1_valid, owner_s0_id, owner_s1_id;
    wire [1:0] grant_s0, grant_s1;

    axi_ic_addr_map addr_map_m0 (.addr(araddr_m0), .slave_sel(slave_sel_m0), .addr_valid(addr_valid_m0));
    axi_ic_addr_map addr_map_m1 (.addr(araddr_m1), .slave_sel(slave_sel_m1), .addr_valid(addr_valid_m1));

    wire [1:0] req_s0 = { (arvalid_m1 && !slave_sel_m1 && addr_valid_m1 && !owner_s0_valid), (arvalid_m0 && !slave_sel_m0 && addr_valid_m0 && !owner_s0_valid) };
    wire [1:0] req_s1 = { (arvalid_m1 &&  slave_sel_m1 && addr_valid_m1 && !owner_s1_valid), (arvalid_m0 &&  slave_sel_m0 && addr_valid_m0 && !owner_s1_valid) };


    axi_ic_arbiter arb_s0 (.clk(clk), .rst_n(rst_n), .req(req_s0), .grant(grant_s0));
    axi_ic_arbiter arb_s1 (.clk(clk), .rst_n(rst_n), .req(req_s1), .grant(grant_s1));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            owner_s0_valid <= 1'b0; owner_s0_id <= 1'b0;
            owner_s1_valid <= 1'b0; owner_s1_id <= 1'b0;
        end else begin
            if (!owner_s0_valid && grant_s0 != 2'b00) begin
                owner_s0_valid <= 1'b1; owner_s0_id <= grant_s0[1];
            end else if (owner_s0_valid && rvalid_s0 && rready_s0 && rlast_s0) owner_s0_valid <= 1'b0;

            if (!owner_s1_valid && grant_s1 != 2'b00) begin
                owner_s1_valid <= 1'b1; owner_s1_id <= grant_s1[1];
            end else if (owner_s1_valid && rvalid_s1 && rready_s1 && rlast_s1) owner_s1_valid <= 1'b0;
        end
    end

    wire route_sel_s0    = owner_s0_valid ? owner_s0_id : grant_s0[1];
    wire route_active_s0 = owner_s0_valid || (grant_s0 != 2'b00);
    wire route_sel_s1    = owner_s1_valid ? owner_s1_id : grant_s1[1];
    wire route_active_s1 = owner_s1_valid || (grant_s1 != 2'b00);

    assign {arvalid_s0, araddr_s0, arlen_s0, arsize_s0, arburst_s0, arid_s0} = route_sel_s0 ? {route_active_s0 && arvalid_m1, araddr_m1, arlen_m1, arsize_m1, arburst_m1, arid_m1} : {route_active_s0 && arvalid_m0, araddr_m0, arlen_m0, arsize_m0, arburst_m0, arid_m0};

    assign {arvalid_s1, araddr_s1, arlen_s1, arsize_s1, arburst_s1, arid_s1} = route_sel_s1 ? {route_active_s1 && arvalid_m1, araddr_m1, arlen_m1, arsize_m1, arburst_m1, arid_m1} : {route_active_s1 && arvalid_m0, araddr_m0, arlen_m0, arsize_m0, arburst_m0, arid_m0};

    assign rready_s0 = owner_s0_valid && (owner_s0_id ? rready_m1 : rready_m0);
    assign rready_s1 = owner_s1_valid && (owner_s1_id ? rready_m1 : rready_m0);

    assign arready_m0 = (route_active_s0 && !route_sel_s0) ? arready_s0 : (route_active_s1 && !route_sel_s1) ? arready_s1 : 1'b0;
    assign arready_m1 = (route_active_s0 &&  route_sel_s0) ? arready_s0 : (route_active_s1 &&  route_sel_s1) ? arready_s1 : 1'b0;

    wire m0_owns_s0 = owner_s0_valid && !owner_s0_id;
    wire m0_owns_s1 = owner_s1_valid && !owner_s1_id;
    wire m1_owns_s0 = owner_s0_valid &&  owner_s0_id;
    wire m1_owns_s1 = owner_s1_valid &&  owner_s1_id;

    assign {rvalid_m0, rlast_m0, rdata_m0, rresp_m0, rid_m0} = m0_owns_s0 ? {rvalid_s0, rlast_s0, rdata_s0, rresp_s0, rid_s0} : m0_owns_s1 ? {rvalid_s1, rlast_s1, rdata_s1, rresp_s1, rid_s1} : {1'b0, 1'b0, 32'b0, 2'b00, {ID_WIDTH{1'b0}}};

    assign {rvalid_m1, rlast_m1, rdata_m1, rresp_m1, rid_m1} = m1_owns_s0 ? {rvalid_s0, rlast_s0, rdata_s0, rresp_s0, rid_s0} : m1_owns_s1 ? {rvalid_s1, rlast_s1, rdata_s1, rresp_s1, rid_s1} : {1'b0, 1'b0, 32'b0, 2'b00, {ID_WIDTH{1'b0}}};

endmodule