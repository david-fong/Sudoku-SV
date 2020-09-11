
/**
 *
 * top level module.
 * "cursor" here refers the tile currently with control (ie. the most
 * recent tile that was told it was their turn.
 *
 * key0 is reset
 * key1 is start (TODO: consider changing to merge this into key0)
 * key2 updates cursor position monitors (hex1 and hex0) on posedge
 * key3 toggles occupancy masks view mode (row, col, or blk major)
 *
 * LEDR[8:0] displays the occupancy mask for the current view mode
 *
 * hex5 displays success / failure / working
 * hex1 displays the cursor's vertical position
 * hex0 displays the cursor's horizontal position
 *
 */
module sudoku
(
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    output [9:0] LEDR,
    output reg [6:0] HEX5
//    output [6:0] HEX4,
//    output [6:0] HEX3,
//    output [6:0] HEX2,
//    output [6:0] HEX1,
//    output [6:0] HEX0
);

    wire done_success;
    wire done_failure;

    // instantiate the grid module:
    grid #() GRIDx(
        .clock(CLOCK_50),
        .reset(~KEY[0]),
        .start(~KEY[1]),
        .done_success,
        .done_failure
    );

    // always-block for success / failure / working:
    always_comb begin
        if (done_success) begin
            HEX5 = 7'b0_01_0_01_0; // 'S'
        end
        else if (done_failure) begin
            HEX5 = 7'b0_00_1_11_0; // 'F'
        end
        else begin
            HEX5 = 7'b0_11_1_11_1; // '-'
        end
    end

endmodule : sudoku

