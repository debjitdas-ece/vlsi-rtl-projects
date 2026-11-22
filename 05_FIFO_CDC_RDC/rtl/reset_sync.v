// Reset synchronizer: asynchronous assert, synchronous de-assert.
module reset_sync #(parameter STAGES = 2)(
    input  clk,
    input  arst_n,
    output srst_n
);
    reg [STAGES-1:0] sh;
    always @(posedge clk or negedge arst_n)
        if (!arst_n) sh <= {STAGES{1'b0}};
        else         sh <= {sh[STAGES-2:0], 1'b1};
    assign srst_n = sh[STAGES-1];
endmodule
