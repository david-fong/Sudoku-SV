`include "grid_dimensions.svh"

/**
 * a bus whose value is intended to be broadcasted to all tiles in a
 *     common row. values are requested from an internal pool via
 *     index into that pool. the requested value will appear on a
 *     rising clock edge if [update] is asserted.
 *
 * the internal pool contains one of each 1hot number of width
 *     `GRID_LEN+1 in random order, except the special value of all
 *     zeros, which is always addressable via the most significant
 *     bit.
 *
 * outputs should be treated as undefined if inputs attempt to index
       using a non-1hot value.
 */
module rowbias
#(
    parameter WIDTH=`GRID_LEN,
    parameter RAND_WIDTH
)(
    input  clock,
    input  reset,
    input  [RAND_WIDTH-1:0] random,
    input  update,
    input  [WIDTH-1:0] rqindex,
    output reg [WIDTH-1:0] valtotry
);
    enum logic [3:0] {
        RESET           = 4'b1 << 1,
        RESET_SWAP_0    = 4'b1 << 2,
        RESET_SWAP_1    = 4'b1 << 3,
        READY           = 4'b1 << 4
    } state;
    reg [WIDTH-1:0] shufflepool [WIDTH-1:0];

    int inlzn_countup;
    wire [31:0] inlzn_countup_next = inlzn_countup + 1;
    reg [RAND_WIDTH-1:0] random_grabbed;
    reg [WIDTH-1:0] swap_temp;
    always_ff @(posedge clock) begin: rowbias_state
        if (reset) begin
            inlzn_countup <= 'x;
            state <= RESET;
        end
        else begin case (state)
            RESET: begin
                random_grabbed  <= 0;
                inlzn_countup   <= 0;
                state           <= RESET_SWAP_0;
            end
            RESET_SWAP_0: begin
                swap_temp <= (inlzn_countup != random_grabbed) ? shufflepool[random_grabbed] : 'x;
                state <= RESET_SWAP_1;
            end
            RESET_SWAP_1: begin
                // inlzn_countup <= inlzn_countup;
                if (inlzn_countup != random_grabbed) begin
                    shufflepool[inlzn_countup] <= swap_temp;
                end
                shufflepool[random_grabbed] <= {{WIDTH-1{1'b0}},1'b1} << inlzn_countup;
                random_grabbed  <= random % inlzn_countup_next;
                inlzn_countup   <= inlzn_countup_next;
                state <= (inlzn_countup_next == WIDTH) ? READY : RESET_SWAP_0;
            end
            READY: begin
                inlzn_countup  <= 'x;
                random_grabbed <= 'x;
                state <= READY;
            end
        endcase end
    end

    always_ff @(posedge clock) begin
        if (update) begin
            valtotry = 'x;
            for (int i = 0; i < WIDTH; i++) begin
                if (rqindex[i]) begin
                    valtotry = shufflepool[i];
                    break;
                end
            end
        end
    end
endmodule


// arbiter. filter for least significant on-bit.
// currently not used since spec for rowbias does not permit non-1hot indexing.
module arbiter #(parameter WIDTH)
(
    input  [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);
    wire   [WIDTH-1:0] scratch;
    assign scratch = in | {scratch[WIDTH-2:0],1'b0};
    assign out = in & ~scratch;
endmodule