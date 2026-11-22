// Pulse synchronizer: toggle in source domain, 2-flop sync, edge-detect in dest.
// Rule: source pulses must be spaced >= ~3 destination clock periods apart.
module pulse_sync (
    input  src_clk, src_rst_n, pulse_in,
    input  dst_clk, dst_rst_n,
    output pulse_out
);
    reg tog;
    always @(posedge src_clk or negedge src_rst_n)
        if (!src_rst_n)    tog <= 1'b0;
        else if (pulse_in) tog <= ~tog;

    reg s1, s2, s3;
    always @(posedge dst_clk or negedge dst_rst_n)
        if (!dst_rst_n) begin s1 <= 0; s2 <= 0; s3 <= 0; end
        else begin s1 <= tog; s2 <= s1; s3 <= s2; end

    assign pulse_out = s2 ^ s3;
endmodule
