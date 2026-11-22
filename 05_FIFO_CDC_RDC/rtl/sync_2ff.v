`timescale 1ps/1ps
// Two-flop synchronizer. Use only for single-bit signals or Gray-coded buses.
// SKEW is a SIMULATION-ONLY bus-skew model: bit i of the input is delayed by
// i*SKEW picoseconds before the first flop, so a multi-bit change is sampled
// "half old, half new" like a badly routed bus. Keep SKEW=0 for synthesis.
module sync_2ff #(
    parameter W    = 1,
    parameter SKEW = 0
)(
    input          clk,
    input          rst_n,
    input  [W-1:0] d,
    output [W-1:0] q
);
    wire [W-1:0] d_eff;
    reg  [W-1:0] s1, s2;
    assign q = s2;

    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : g_bit
            if (SKEW != 0) begin : g_dly
                assign #(i*SKEW) d_eff[i] = d[i];
            end else begin : g_nodly
                assign d_eff[i] = d[i];
            end
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin s1 <= {W{1'b0}}; s2 <= {W{1'b0}}; end
        else        begin s1 <= d_eff;     s2 <= s1;        end
    end
endmodule
