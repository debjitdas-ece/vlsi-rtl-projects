module axi_addr_decode #(
    parameter REGION_BASE = `SLAVE0_BASE,
    parameter REGION_LIMIT = `SLAVE0_LIMIT
) (
    input  wire [31:0] addr,
    input wire [7:0] len,
    input wire [2:0] size,
    output wire region_hit,
    output wire boundary_okay, 
    output wire decode_error
);
    wire [7:0]  num_bytes;
    wire [31:0] burst_bytes;
    wire [31:0] end_addr;
    assign num_bytes = 1 << size;
    assign burst_bytes = num_bytes * (len + 1);
    assign end_addr = addr + burst_bytes - 1;
    assign region_hit = (addr >= REGION_BASE) && (end_addr <= REGION_LIMIT);
    assign boundary_okay = (addr & `AXI_4KB_MASK) == (end_addr & `AXI_4KB_MASK);
    assign decode_error = !(region_hit && boundary_okay);
endmodule
