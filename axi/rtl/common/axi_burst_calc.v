module axi_burst_calc (
    input  [31:0] addr_in,
    input  [2:0]  size,
    input  [7:0]  len,
    input  [1:0]  burst_type,
    output [31:0] addr_out
);

    wire [7:0]  num_bytes;
    wire [2:0]  extra_bits;
    wire [3:0]  mask_width;
    wire [31:0] wrap_mask, wrap_block_start, wrap_block_end, burst_size_bytes, next_addr_lin;

    assign num_bytes       = 1 << size;
    assign burst_size_bytes = num_bytes * (len + 1);
    assign next_addr_lin   = addr_in + num_bytes;
    assign extra_bits = (len == 8'd1)  ? 3'd1 : (len == 8'd3)  ? 3'd2 :(len == 8'd7)  ? 3'd3 :(len == 8'd15) ? 3'd4 : 3'd0; 
    assign mask_width = size + extra_bits;
    assign wrap_mask        = (32'd1 << mask_width) - 1;
    assign wrap_block_start = addr_in & ~wrap_mask;
    assign wrap_block_end   = wrap_block_start + burst_size_bytes - 1; 

    assign addr_out = (burst_type == 2'b00) ? addr_in :(burst_type == 2'b01) ? next_addr_lin :(burst_type == 2'b10) ?((next_addr_lin > wrap_block_end) ? wrap_block_start : next_addr_lin) :addr_in; 

endmodule