module axi_master_cmd_fsm #(
    parameter ID_WIDTH = 4, OUTSTANDING_DEPTH = 4
) (
    input clk, rst_n,
    input cmd_valid, cmd_op, awready, arready,
    input wr_fifo_push_ready, rd_fifo_push_ready,
    input wr_complete_valid, rd_complete_valid,
    input [31:0] cmd_addr,
    input [7:0]  cmd_len,
    input [2:0]  cmd_size,
    input [1:0]  cmd_burst,
    input [ID_WIDTH-1:0] cmd_id, wr_complete_id, rd_complete_id,
    output cmd_ready, awvalid, arvalid, wr_fifo_push_valid, rd_fifo_push_valid,
    output [31:0] awaddr, araddr, wr_fifo_push_addr, rd_fifo_push_addr,
    output [7:0]  awlen, arlen, wr_fifo_push_len, rd_fifo_push_len,
    output [2:0]  awsize, arsize, wr_fifo_push_size, rd_fifo_push_size,
    output [1:0]  awburst, arburst, wr_fifo_push_burst, rd_fifo_push_burst,
    output [ID_WIDTH-1:0] awid, arid, wr_fifo_push_id, rd_fifo_push_id
);
    localparam IDLE=2'd0, DISPATCH_WR=2'd1, DISPATCH_RD=2'd2;
    reg [1:0] s, ns;
    reg [31:0] addr_reg;
    reg [7:0]  len_reg;
    reg [2:0]  size_reg;
    reg [1:0]  burst_reg;
    reg [ID_WIDTH-1:0] id_reg;

    wire wr_issue_ready, rd_issue_ready;
    wire issue_valid_wr = cmd_valid && (s==IDLE) && (cmd_op==`CMD_OP_WRITE) && wr_fifo_push_ready;
    wire issue_valid_rd = cmd_valid && (s==IDLE) && (cmd_op==`CMD_OP_READ)  && rd_fifo_push_ready;

    axi_id_tracker #(.ID_WIDTH(ID_WIDTH), .DEPTH(OUTSTANDING_DEPTH)) id_tracker_wr (
        .clk(clk), .rst_n(rst_n), .issue_valid(issue_valid_wr), .issue_id(cmd_id),
        .issue_ready(wr_issue_ready), .complete_valid(wr_complete_valid), .complete_id(wr_complete_id)
    );
    axi_id_tracker #(.ID_WIDTH(ID_WIDTH), .DEPTH(OUTSTANDING_DEPTH)) id_tracker_rd (
        .clk(clk), .rst_n(rst_n), .issue_valid(issue_valid_rd), .issue_id(cmd_id),
        .issue_ready(rd_issue_ready), .complete_valid(rd_complete_valid), .complete_id(rd_complete_id)
    );

    assign cmd_ready = (s==IDLE) && ((cmd_op==`CMD_OP_WRITE) ? wr_issue_ready : rd_issue_ready);
    wire cmd_hs = cmd_valid && cmd_ready;

    always @(*) begin
        case (s)
            IDLE:        ns = cmd_hs ? ((cmd_op==`CMD_OP_WRITE) ? DISPATCH_WR : DISPATCH_RD) : IDLE;
            DISPATCH_WR: ns = (awvalid && awready) ? IDLE : DISPATCH_WR;
            DISPATCH_RD: ns = (arvalid && arready) ? IDLE : DISPATCH_RD;
            default:     ns = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s <= IDLE; addr_reg <= 0; len_reg <= 0; size_reg <= 0; burst_reg <= 0; id_reg <= 0;
        end else begin
            s <= ns;
            if (cmd_hs) begin
                addr_reg <= cmd_addr; len_reg <= cmd_len; size_reg <= cmd_size;
                burst_reg <= cmd_burst; id_reg <= cmd_id;
            end
        end
    end

  
    assign awvalid = (s == DISPATCH_WR);
    assign arvalid = (s == DISPATCH_RD);
    assign {awaddr, awlen, awsize, awburst, awid} = {addr_reg, len_reg, size_reg, burst_reg, id_reg};
    assign {araddr, arlen, arsize, arburst, arid} = {addr_reg, len_reg, size_reg, burst_reg, id_reg};

    wire aw_hs = awvalid && awready;
    wire ar_hs = arvalid && arready;

    assign wr_fifo_push_valid = aw_hs;
    assign {wr_fifo_push_addr, wr_fifo_push_len, wr_fifo_push_size, wr_fifo_push_burst, wr_fifo_push_id}
         = {addr_reg, len_reg, size_reg, burst_reg, id_reg};

    assign rd_fifo_push_valid = ar_hs;
    assign {rd_fifo_push_addr, rd_fifo_push_len, rd_fifo_push_size, rd_fifo_push_burst, rd_fifo_push_id}
         = {addr_reg, len_reg, size_reg, burst_reg, id_reg};

endmodule