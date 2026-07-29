module axi_ic_addr_map (
    input  [31:0] addr,
    output        slave_sel,
    output        addr_valid
);
assign slave_sel  = (addr >= `SLAVE1_BASE && addr <= `SLAVE1_LIMIT) ? 1'b1 : 1'b0;
assign addr_valid = (addr >= `SLAVE0_BASE && addr <= `SLAVE0_LIMIT) || (addr >= `SLAVE1_BASE && addr <= `SLAVE1_LIMIT);

endmodule
