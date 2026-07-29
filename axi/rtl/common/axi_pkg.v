`ifndef AXI_PKG_V
`define AXI_PKG_V

// bus params
`define AXI_ADDR_WIDTH    32
`define AXI_DATA_WIDTH    32
`define AXI_STRB_WIDTH    (`AXI_DATA_WIDTH/8)
`define AXI_ID_WIDTH      4     
`define AXI_LEN_WIDTH     8
`define NUM_MASTERS       2
`define NUM_SLAVES        2

// AxBURST[1:0]
`define AXI_BURST_FIXED   2'b00
`define AXI_BURST_INCR    2'b01
`define AXI_BURST_WRAP    2'b10
// 2'b11 reserved

// xRESP[1:0]
`define AXI_RESP_OKAY     2'b00
`define AXI_RESP_EXOKAY   2'b01  
`define AXI_RESP_SLVERR   2'b10
`define AXI_RESP_DECERR   2'b11

// AxSIZE, only 4B is legal here, rest are for the negative TB
`define AXI_SIZE_1B       3'b000
`define AXI_SIZE_2B       3'b001
`define AXI_SIZE_4B       3'b010
`define AXI_SIZE_8B       3'b011

// addr map
`define SLAVE0_BASE       32'h0000_0000
`define SLAVE0_LIMIT      32'h0000_0FFF
`define SLAVE1_BASE       32'h0000_1000
`define SLAVE1_LIMIT      32'h0000_1FFF

`define AXI_4KB_MASK      32'hFFFF_F000

// front-door cmd fsm opcodes (not AXI spec, ours)
`define CMD_OP_WRITE      1'b0
`define CMD_OP_READ       1'b1

`endif
