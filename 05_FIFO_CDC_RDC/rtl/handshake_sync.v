// 4-phase req/ack handshake carrying a multi-bit word across clock domains.
// Data is held stable in the source domain until the ack comes back.
module handshake_sync #(parameter DW = 8)(
    input               src_clk, src_rst_n,
    input               src_valid,
    input  [DW-1:0]     src_data,
    output              src_ready,       // high when a new word can be accepted
    input               dst_clk, dst_rst_n,
    output reg          dst_valid,       // 1-cycle pulse in dst domain
    output reg [DW-1:0] dst_data
);
    // ---- source side ----
    reg          req, busy;
    reg [DW-1:0] data_hold;
    reg          ack;                    // driven from dst domain
    wire         ack_s;                  // ack synchronized into src domain
    sync_2ff #(.W(1)) u_ack (.clk(src_clk), .rst_n(src_rst_n), .d(ack), .q(ack_s));

    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin req <= 0; busy <= 0; data_hold <= 0; end
        else if (!busy && src_valid) begin
            data_hold <= src_data; req <= 1'b1; busy <= 1'b1;
        end else if (busy && req && ack_s)   req  <= 1'b0;
        else   if (busy && !req && !ack_s)   busy <= 1'b0;
    end
    assign src_ready = ~busy;

    // ---- destination side ----
    wire req_s;
    reg  req_d;
    sync_2ff #(.W(1)) u_req (.clk(dst_clk), .rst_n(dst_rst_n), .d(req), .q(req_s));

    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin req_d <= 0; ack <= 0; dst_valid <= 0; dst_data <= 0; end
        else begin
            req_d     <= req_s;
            ack       <= req_s;
            dst_valid <= req_s & ~req_d;
            if (req_s & ~req_d) dst_data <= data_hold;
        end
    end
endmodule
