module axi_resp_gen (
    input decode_err, slave_err,
    output [1:0] resp
);
    assign resp = decode_err ? `AXI_RESP_DECERR : (slave_err ? `AXI_RESP_SLVERR : `AXI_RESP_OKAY);

endmodule
