`include "grid_dimensions.svh"

/**
 * a network of tiles that form a sudoku grid.
 */
module grid #()
(
    input clock,
    input reset,
    input start,
    output done,
    output success
);
    // get block number given a row number and column number:
    function int unsigned blockof (
        int unsigned row,
        int unsigned col
    );
        return ((row/`GRID_ORD)*`GRID_ORD) + (col/`GRID_ORD);
    endfunction

    enum logic [4:0] {
        RESET        = 1 << 0, //
        START        = 1 << 1, //
        WAIT         = 1 << 2, //
        DONE_SUCCESS = 1 << 3, //
        DONE_FAILURE = 1 << 4 //
    } state;

    // chaining and success signals:
    wire [`GRID_AREA-1:0] myturns;
    wire passbaks [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire passfwds [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire [`GRID_AREA-1:0] _passbaks = {>>{{>>{passbaks}}}};
    wire [`GRID_AREA-1:0] _passfwds = {>>{{>>{passfwds}}}};
    assign myturns = {1'b0, _passbaks[`GRID_AREA-1:1]} | {_passfwds[`GRID_AREA-2:0], (state==START)};
    assign done = (state == DONE_SUCCESS) || (state == DONE_FAILURE);
    assign success = (state == DONE_SUCCESS);

    // [rowbias] signals:
    wire [`GRID_LEN-1:0] biasidx [`GRID_LEN][`GRID_LEN];
    wire [`GRID_LEN -1:0][`GRID_LEN-1:0] rq_valtotry;
    wire [`GRID_LEN -1:0] valtotry [`GRID_LEN];

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
            RESET: state <= start ? START : RESET;
            START: state <= WAIT;
            WAIT: begin state <= (
                  passbaks[           0] ? DONE_FAILURE
                : passfwds[`GRID_AREA-1] ? DONE_SUCCESS
                : WAIT); end
            DONE_SUCCESS: state <= DONE_SUCCESS;
            DONE_FAILURE: state <= DONE_FAILURE;
        endcase end
    end: grid_fsm


    // generate [rowbias] modules:
    generate
        for (genvar r = 0; r < `GRID_LEN; r++) begin // rows
            wor [`GRID_LEN-1:0] rqindex;
            for (genvar c = 0; c < `GRID_LEN; c++) begin
                assign rqindex = biasidx[r][c];
            end
            rowbias /*#()*/ ROWBIASx(
                .clock,
                .reset,
                .update( /*or:*/|rq_valtotry[r]),
                .rqindex(/*or:*/rqindex),
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
                .passbak(passbaks[r][c]),
                .passfwd(passfwds[r][c]),
                .biasidx(biasidx[r][c]),
                .rq_valtotry(rq_valtotry[r][c]),
                .valtotry(valtotry[r]),
                .valcannotbe({
                    rowalreadyhas[r] |
                    colalreadyhas[c] |
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
        for (genvar b = 0; b < `GRID_LEN; b++) begin // rows
        for (genvar i = 0; i < `GRID_LEN; i++) begin // cols
            // some test ideas:
            // 0,0->0,0
            // 0,3->1,0
            // 0,6->2,0
            // 1,0->0,3
            // 1,3->1,3
            // 1,6->2,3
            int unsigned r = ((b/`GRID_ORD)*`GRID_ORD) + (i/`GRID_ORD);
            int unsigned c = ((b%`GRID_ORD)*`GRID_ORD) + (i%`GRID_ORD);
            assign blkmajorvalues[b][i] = rowmajorvalues[r][c];
        end // rows
        end // cols
    endgenerate

endmodule : grid