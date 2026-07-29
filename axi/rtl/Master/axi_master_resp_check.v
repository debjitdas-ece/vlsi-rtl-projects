module axi_master_resp_check #(
    parameter ID_WIDTH = 4
) (
    input wr_complete_valid, rd_complete_valid,
    input [ID_WIDTH-1:0] wr_complete_id, rd_complete_id,
    input [1:0] bresp, rresp,
    output wr_resp_error, rd_resp_error,
    output [ID_WIDTH-1:0] wr_resp_error_id, rd_resp_error_id
);
    assign {wr_resp_error, rd_resp_error} = {wr_complete_valid && (bresp != `AXI_RESP_OKAY), rd_complete_valid && (rresp != `AXI_RESP_OKAY)};
    assign {wr_resp_error_id, rd_resp_error_id} = {wr_complete_id, rd_complete_id};
endmodule