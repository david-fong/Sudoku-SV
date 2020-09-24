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
 *     using a non-1hot value.
 */
module rowbias
#(
    parameter  int unsigned ORD,
    parameter  int unsigned LFSR_WIDTH,
    parameter  bit unsigned [LFSR_WIDTH-1:0] LFSR_TAPS
)(
    input  clock,
    input  reset,
    input  [LFSR_WIDTH-1:0] seed,
    output ready,
    input      unsigned [ORD*ORD-1:0] index    [ORD*ORD-1:0],
    output reg unsigned [ORD*ORD-1:0] valtotry [ORD*ORD-1:0]
);
    localparam int unsigned LEN  = ORD * ORD;
    localparam int unsigned AREA = LEN * LEN;
    enum logic [4:0] {
        RESET           = 5'b1 << 1,
        SETUP_SWAP_0    = 5'b1 << 2,
        SETUP_SWAP_1    = 5'b1 << 3,
        SETUP_NEXT_ROW  = 5'b1 << 4,
        READY           = 5'b1 << 5
    } state;
    assign ready = (state == READY);

    reg [LEN-1:0] shufflepool [LEN-1:0][LEN-1:0];
    wire [LFSR_WIDTH-1:0] random;
    lfsr #(
        .WIDTH(LFSR_WIDTH),
        .TAPS(LFSR_TAPS)
    ) LFSRx(
        .advance(state == SETUP_SWAP_0 || state == SETUP_SWAP_1),
        .out(random),
        .*
    );

    reg  unsigned [8:0] inlzn_countup;
    wire unsigned [8:0] inlzn_countup_next = inlzn_countup + 1'b1;
    reg  unsigned [8:0] inlzn_row;
    reg  unsigned [LFSR_WIDTH-1:0] random_grabbed;
    reg  unsigned [LEN-1:0] swap_temp;
    always_ff @(posedge clock) begin: rowbias_state
        if (reset) begin
            state <= RESET;
        end
        else begin case (state)
            RESET: begin
                inlzn_countup   <= 0;
                inlzn_row       <= 0;
                random_grabbed  <= 0;
                state           <= SETUP_SWAP_0;
            end
            SETUP_SWAP_0: begin
                swap_temp <= (inlzn_countup != random_grabbed) ? shufflepool[inlzn_row][random_grabbed] : 'x;
                state <= SETUP_SWAP_1;
            end
            SETUP_SWAP_1: begin
                if (inlzn_countup != random_grabbed) begin
                    shufflepool[inlzn_row][inlzn_countup] <= swap_temp;
                end
                shufflepool[inlzn_row][random_grabbed] <= {{LEN-1{1'b0}},1'b1} <<< inlzn_countup;
                inlzn_countup   <= inlzn_countup_next;
                random_grabbed  <= random % inlzn_countup_next;
                state <= (inlzn_countup_next == LEN) ? SETUP_NEXT_ROW : SETUP_SWAP_0;
            end
            SETUP_NEXT_ROW: begin
                inlzn_countup   <= 0;
                inlzn_row       <= inlzn_row + 1'b1;
                random_grabbed  <= 0;
                state <= (inlzn_row == LEN - 1) ? READY : SETUP_SWAP_0;
            end
            READY: begin
                inlzn_countup   <= 0;
                random_grabbed  <= 'x;
                state <= READY;
            end
        endcase end
    end

    generate
        genvar rbr;
        for (rbr = 0; rbr < LEN; rbr++) begin: arbiter
            always_ff @(posedge clock) begin
                if (|(index[rbr])) begin
                    valtotry[rbr] = 'x;
                    for (int i = 0; i < LEN; i++) begin
                        if (index[rbr][i]) begin
                            valtotry[rbr] = shufflepool[rbr][i];
                            break;
                        end
                    end
                end
            end
        end
    endgenerate
endmodule