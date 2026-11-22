// Asynchronous FIFO: Gray-code pointers + 2-flop synchronizers.
// First-word-fall-through read. Depth = 2**AW.
module async_fifo #(
    parameter DW   = 8,
    parameter AW   = 4,
    parameter SKEW = 0            // sim-only bus-skew model, ps per bit (see sync_2ff)
)(
    // write domain
    input               wclk,
    input               wrst_n,
    input               winc,
    input  [DW-1:0]     wdata,
    output reg          wfull,
    // read domain
    input               rclk,
    input               rrst_n,
    input               rinc,
    output [DW-1:0]     rdata,
    output reg          rempty
);
    reg [DW-1:0] mem [0:(1<<AW)-1];

    reg  [AW:0] wbin, wgray;
    reg  [AW:0] rbin, rgray;
    wire [AW:0] wq2_rgray;        // read pointer (Gray) seen in write domain
    wire [AW:0] rq2_wgray;        // write pointer (Gray) seen in read domain

    // ---------------- write domain ----------------
    wire [AW:0] wbin_next  = wbin + {{AW{1'b0}}, (winc & ~wfull)};
    wire [AW:0] wgray_next = (wbin_next >> 1) ^ wbin_next;
    // full: next write Gray == read Gray with the top two bits inverted
    wire        wfull_val  = (wgray_next == {~wq2_rgray[AW:AW-1], wq2_rgray[AW-2:0]});

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin wbin <= 0; wgray <= 0; wfull <= 1'b0; end
        else begin wbin <= wbin_next; wgray <= wgray_next; wfull <= wfull_val; end
    end
    always @(posedge wclk)
        if (winc & ~wfull) mem[wbin[AW-1:0]] <= wdata;

    // ---------------- read domain ----------------
    wire [AW:0] rbin_next  = rbin + {{AW{1'b0}}, (rinc & ~rempty)};
    wire [AW:0] rgray_next = (rbin_next >> 1) ^ rbin_next;
    wire        rempty_val = (rgray_next == rq2_wgray);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin rbin <= 0; rgray <= 0; rempty <= 1'b1; end
        else begin rbin <= rbin_next; rgray <= rgray_next; rempty <= rempty_val; end
    end
    assign rdata = mem[rbin[AW-1:0]];

    // ---------------- crossings ----------------
    sync_2ff #(.W(AW+1), .SKEW(SKEW)) u_r2w (.clk(wclk), .rst_n(wrst_n), .d(rgray), .q(wq2_rgray));
    sync_2ff #(.W(AW+1), .SKEW(SKEW)) u_w2r (.clk(rclk), .rst_n(rrst_n), .d(wgray), .q(rq2_wgray));
endmodule
