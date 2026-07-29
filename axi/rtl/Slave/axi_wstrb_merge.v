module axi_wstrb_merge (
    input [31:0] wdata, old_data,
    input [3:0] wstrb,
    output [31:0] merged_data
);
    wire [31:0] wstrb_mask = { {8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}} };
    assign merged_data = (wstrb_mask & wdata) | (~wstrb_mask & old_data);
endmodule
