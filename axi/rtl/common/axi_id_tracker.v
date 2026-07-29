module axi_id_tracker #(
    parameter ID_WIDTH = 4,
    parameter DEPTH    = 4
) (
    input                 clk,
    input                 rst_n,
    input                 issue_valid,
    input  [ID_WIDTH-1:0] issue_id,
    output                issue_ready,
    input                 complete_valid,
    input  [ID_WIDTH-1:0] complete_id
);

    localparam NUM_IDS     = 1 << ID_WIDTH;
    localparam COUNT_WIDTH = $clog2(DEPTH+1);

    reg [COUNT_WIDTH-1:0] count [0:NUM_IDS-1];

    assign issue_ready = issue_valid && (count[issue_id] < DEPTH);

    wire do_issue    = issue_valid && issue_ready;
    wire do_complete = complete_valid && (count[complete_id] > 0);

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            for (i = 0; i < NUM_IDS; i = i + 1) count[i] <= 0;
        else if (issue_id == complete_id)
            count[issue_id] <= count[issue_id] + (do_issue ? 1'b1 : 1'b0) - (do_complete ? 1'b1 : 1'b0);
        else begin
            count[issue_id]    <= do_issue    ? count[issue_id]+1'b1    : count[issue_id];
            count[complete_id] <= do_complete ? count[complete_id]-1'b1 : count[complete_id];
        end
    end

endmodule