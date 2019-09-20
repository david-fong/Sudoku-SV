
`include "def_griddimensions.sv"

/**
 * 
 * a network of tiles that form a sudoku grid.
 *
 */
module grid #()
(
    input clock,
    input reset,
    input start,
    output done_success,
    output done_failure
);

    // chaining and success signals:
    wire [`GRID_AREA-1:0] myturns;
    wire [`GRID_AREA-1:0] passbaks;
    wire [`GRID_AREA-1:0] passfwds;
    assign myturns = {
        {passbaks[`GRID_AREA-1:1],1'b0} | 
        {start,passfwds[`GRID_AREA-2:0]}
    };
    assign done_failure = passbaks[0];
    assign done_success = passfwds[`GRID_AREA-1];

    // [rowbias] signals:
    wire [`GRID_LEN:0] rqindices [`GRID_AREA];
    wire [`GRID_LEN-1:0] updaterowbiases [`GRID_LEN];
    wire [`GRID_LEN-1:0] rowbiases [`GRID_LEN];

    // occupancy signals:
    // [values] is in row-major order.
    wire [`GRID_LEN-1:0] rowmajorvalues [`GRID_LEN][`GRID_LEN];
    wire [`GRID_LEN-1:0] colmajorvalues [`GRID_LEN][`GRID_LEN];
    wire [`GRID_LEN-1:0] blkmajorvalues [`GRID_LEN][`GRID_LEN];
    wire [`GRID_LEN-1:0] rowoccmasks [`GRID_LEN];
    wire [`GRID_LEN-1:0] coloccmasks [`GRID_LEN];
    wire [`GRID_LEN-1:0] blkoccmasks [`GRID_LEN];




    // generate [rowbias] modules:
    generate
        for (integer r = 0; r < `GRID_LEN; r++) begin : rowloop
            rowbias #() ROWBIASx(
                .clock,
                .reset,
                .update(|updaterowbiases[r]),
                .rqindex(|rqindices[((r+1)*`GRID_LEN)-1:(r*`GRID_LEN)]),
                .busvalue(rowbiases[r]),
            );
        end : rowloop
    endgenerate

    // generate [tile] modules:
    generate
        genvar r, c, i;
        for (r = 0; r < `GRID_LEN; r++) begin : rowloop
        for (c = 0; c < `GRID_LEN; c++) begin : colloop
            i = (r * `GRID_LEN) + c;
            tile #() TILEx(
                .clock,
                .reset,
                .myturn(myturns[i]),
                .passbak(passbaks[i]),
                .passfwd(passfwds[i]),
                .rqindex(rqindices[i]),
                .updaterowbias(updaterowbiases[r][c]),
                .rowbias(rowbiases[r]),
                .occupiedmask({
                    rowoccmasks[r]|
                    coloccmasks[c]|
                    blkoccmasks[blockof(r,c)]
                }),
                .value(rowmajorvalues[r][c]),
            );
        end : colloop
        end : rowloop
    endgenerate

    // generate [OR] modules for [tile.occupiedmask] inputs:
    generate
        genvar out;
        for (out = 0; out < `GRID_LEN; out++) begin : outloop
            assign rowoccmasks[out] = |rowmajorvalues[out];
            assign coloccmasks[out] = |colmajorvalues[out];
            assign blkoccmasks[out] = |blkmajorvalues[out];
        end : outloop
    endgenerate

    // TODO: loop to map rowmajorvalues to colmajorvalues:
    generate
        ;
    endgenerate

    // TODO: loop to map rowmajorvalues to blkmajorvalues:
    generate
        ;
    endgenerate



endmodule : grid

function blockof(integer row, integer col) begin
    return ((row/`GRID_ORD)*`GRID_ORD) + (col/`GRID_ORD);
end

