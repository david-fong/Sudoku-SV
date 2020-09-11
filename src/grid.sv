
`include "grid_dimensions.svh"

/**
 * a network of tiles that form a sudoku grid.
 */
module grid #()
(
    input clock,
    input reset,
    input start,
    output done_success,
    output done_failure
);
    enum int unsigned [4:0] {
        RESET        = 1 << 0, //
        START        = 1 << 1, //
        WAIT         = 1 << 2, //
        DONE_SUCCESS = 1 << 3, //
        DONE_FAILURE = 1 << 4, //
    } state;

    // chaining and success signals:
    wire [`GRID_AREA-1:0] myturns;
    wire [`GRID_AREA-1:0] passbaks;
    wire [`GRID_AREA-1:0] passfwds;
    assign myturns = {
        {passbaks[`GRID_AREA-1:1], 1'b0}|
        {start, passfwds[`GRID_AREA-2:0]}
    };
    assign done_failure = (state == DONE_FAILURE);
    assign done_success = (state == DONE_SUCCESS);

    // [rowbias] signals:
    wire [`GRID_LEN  :0][`GRID_AREA-1:0] biasidx;
    wire [`GRID_LEN-1:0][ `GRID_LEN-1:0] rq_valtotry;
    wire [`GRID_LEN-1:0] valtotry [`GRID_LEN];

    // occupancy signals:
    // [values] is in row-major order.
    wire [`GRID_LEN-1:0][`GRID_LEN-1:0] rowmajorvalues [`GRID_LEN];
    wire [`GRID_LEN-1:0][`GRID_LEN-1:0] colmajorvalues [`GRID_LEN];
    wire [`GRID_LEN-1:0][`GRID_LEN-1:0] blkmajorvalues [`GRID_LEN];
    wire [`GRID_LEN-1:0] rowalreadyhas [`GRID_LEN];
    wire [`GRID_LEN-1:0] colalreadyhas [`GRID_LEN];
    wire [`GRID_LEN-1:0] blkalreadyhas [`GRID_LEN];


    always_ff @(posedge clock) begin: grid_fsm
        if (reset) begin
            state <= RESET;
        end
        else begin case (state)
            RESET: state <= START;
            START: state <= WAIT;
            WAIT:  state <=
                  passbaks[           0] ? DONE_FAILURE
                : passfwds[`GRID_AREA-1] ? DONE_SUCCESS
                : WAIT;
            DONE_SUCCESS: state <= state;
            DONE_FAILURE: state <= state;
        endcase end
    end: grid_fsm


    // generate [rowbias] modules:
    generate
        for (genvar r = 0; r < `GRID_LEN; r++) begin // rows
            rowbias /*#()*/ ROWBIASx(
                .clock,
                .reset,
                .update( /*or:*/|rq_valtotry[r]),
                .rqindex(/*or:*/|{biasidx[(r*`GRID_LEN)+:`GRID_LEN]}),
                .busvalue(valtotry[r])
            );
        end // rows
    endgenerate

    // generate [tile] modules:
    generate
        for (genvar r = 0; r < `GRID_LEN; r++) begin // rows
        for (genvar c = 0; c < `GRID_LEN; c++) begin // cols
            int unsigned i = (r * `GRID_LEN) + c;
            tile /*#()*/ TILEx(
                .clock,
                .reset,
                .myturn(myturns[i]),
                .passbak(passbaks[i]),
                .passfwd(passfwds[i]),
                .biasidx(biasidx[i]),
                .rq_valtotry(rq_valtotry[r][c]),
                .valtotry(valtotry[r]),
                .valcannotbe({
                    rowalreadyhas[r]|
                    colalreadyhas[c]|
                    blkalreadyhas[blockof(r,c)]
                }),
                .value(rowmajorvalues[r][c])
            );
        end // cols
        end // rows
    endgenerate

    // generate [OR] modules for [tile.occupiedmask] inputs:
    generate
        for (genvar out = 0; out < `GRID_LEN; out++) begin
            assign rowalreadyhas[out] = /*or:*/|rowmajorvalues[out];
            assign colalreadyhas[out] = /*or:*/|colmajorvalues[out];
            assign blkalreadyhas[out] = /*or:*/|blkmajorvalues[out];
        end
    endgenerate

    // loop to map [rowmajorvalues] to [colmajorvalues]:
    // r and c are in terms of row-major-order. nothing convoluted.
    generate
        for (genvar r = 0; r < `GRID_LEN; r++) begin // rows
        for (genvar c = 0; c < `GRID_LEN; c++) begin // cols
            assign colmajorvalues[c][r] = rowmajorvalues[r][c];
        end // cols
        end // rows
    endgenerate

    // loop to map [rowmajorvalues] to [blkmajorvalues]:
    generate
        for (genvar r = 0; r < `GRID_LEN; r++) begin // rows
        for (genvar c = 0; c < `GRID_LEN; c++) begin // cols
            // some test ideas:
            // 0,0->0,0
            // 0,3->1,0
            // 0,6->2,0
            // 1,0->0,3
            // 1,3->1,3
            // 1,6->2,3
            int unsigned b = ((r / `GRID_ORD) * `GRID_ORD) + (c / `GRID_ORD);
            int unsigned i = ((r % `GRID_ORD) * `GRID_ORD) + (c % `GRID_ORD);
            assign blkmajorvalues[b][i] = rowmajorvalues[r][c];
        end // rows
        end // cols
    endgenerate

endmodule : grid


// get block number given a row number and column number:
function int unsigned blockof
(
    int unsigned row,
    int unsigned col
);
    return ((row/`GRID_ORD)*`GRID_ORD) + (col/`GRID_ORD);
endfunction