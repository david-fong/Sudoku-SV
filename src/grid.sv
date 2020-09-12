`include "grid_dimensions.svh"

typedef enum {
    ROW_MAJOR,
    BLOCK_COL
} genpath_t;

/**
 * a network of tiles that form a sudoku grid.
 */
module grid #(genpath_t GENPATH = BLOCK_COL)
(
    input clock,
    input reset,
    input start,
    output done,
    output success
    // TODO.design an interface to request and serially receive the solution data.
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
        DONE_FAILURE = 1 << 4  //
    } state;
    assign done = (state == DONE_SUCCESS) | (state == DONE_FAILURE);
    assign success = (state == DONE_SUCCESS);

    // chaining and success signals:
    wire [`GRID_AREA-1:0] myturns;
    wire rowmaj_passbaks [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire rowmaj_passfwds [`GRID_LEN-1:0][`GRID_LEN-1:0];

    wire [`GRID_AREA-1:0] tvs_passbaks;
    wire [`GRID_AREA-1:0] tvs_passfwds;
    assign myturns = {
        1'b0, tvs_passbaks[`GRID_AREA-1:1]} |
        {tvs_passfwds[`GRID_AREA-2:0], (state==START)};

    // [rowbias] signals:
    wire [`GRID_LEN-1:0] biasidx [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire [`GRID_LEN -1:0][`GRID_LEN-1:0] rq_valtotry;
    wire [`GRID_LEN -1:0] valtotry [`GRID_LEN-1:0];

    // occupancy signals:
    // [values] is in row-major order.
    wire [`GRID_LEN-1:0] rowmajorvalues [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire [`GRID_LEN-1:0] colmajorvalues [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire [`GRID_LEN-1:0] blkmajorvalues [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire [`GRID_LEN-1:0] rowalreadyhas  [`GRID_LEN-1:0];
    wire [`GRID_LEN-1:0] colalreadyhas  [`GRID_LEN-1:0];
    wire [`GRID_LEN-1:0] blkalreadyhas  [`GRID_LEN-1:0];


    // FSM:
    always_ff @(posedge clock) begin: grid_fsm
        if (reset) begin
            state <= RESET;
        end
        else begin case (state)
            RESET: state <= start ? START : RESET;
            START: state <= WAIT;
            WAIT: begin state <= (
                tvs_passbaks[0] ? DONE_FAILURE
                : tvs_passfwds[`GRID_AREA-1] ? DONE_SUCCESS
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
                .passbak(rowmaj_passbaks[r][c]),
                .passfwd(rowmaj_passfwds[r][c]),
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

    // traversal path:
    generate
        case (GENPATH)
        ROW_MAJOR: begin
            assign tvs_passbaks = {>>{{>>{rowmaj_passbaks}}}};
            assign tvs_passfwds = {>>{{>>{rowmaj_passfwds}}}};
        end
        BLOCK_COL: begin
            wire [`GRID_ORD-1:0] _rowmaj_passbaks [`GRID_BGA-1:0] = {>>{{>>{rowmaj_passbaks}}}};
            wire [`GRID_ORD-1:0] _rowmaj_passfwds [`GRID_BGA-1:0] = {>>{{>>{rowmaj_passfwds}}}};
            for (genvar i = 0; i < `GRID_BGA; i++) begin
                const int unsigned tvsidx = (i%`GRID_ORD) + (i/`GRID_ORD*`GRID_ORD);
                assign tvs_passbaks[i*`GRID_ORD+:`GRID_ORD] = _rowmaj_passbaks[tvsidx];
                assign tvs_passfwds[i*`GRID_ORD+:`GRID_ORD] = _rowmaj_passfwds[tvsidx];
            end
        end
        endcase
    endgenerate

    // generate [OR] modules for [tile.occupiedmask] inputs:
    generate
        for (genvar i = 0; i < `GRID_LEN; i++) begin
            wor [`GRID_LEN-1:0] _rowalreadyhas;
            wor [`GRID_LEN-1:0] _colalreadyhas;
            wor [`GRID_LEN-1:0] _blkalreadyhas;
            for (genvar j = 0; j < `GRID_LEN; j++) begin
                assign _rowalreadyhas = rowmajorvalues[i][j];
                assign _colalreadyhas = colmajorvalues[i][j];
                assign _blkalreadyhas = blkmajorvalues[i][j];
            end
            assign rowalreadyhas[i] = _rowalreadyhas;
            assign colalreadyhas[i] = _colalreadyhas;
            assign blkalreadyhas[i] = _blkalreadyhas;
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

    // A task to print the grid values to the transcript:
    task print();
        $write("");
        for (int r = 0; r < `GRID_LEN; r++) begin
            if (r % `GRID_ORD == 0) begin
                _print_horizontal_line();
            end
            for (int c = 0; c < `GRID_LEN; c++) begin
                if (c % `GRID_ORD == 0) begin
                    $write("| ");
                end
                $write("%1x ", $ln(rowmajorvalues[r][c])/$ln(2));
            end
            $write("| \n");
        end
        _print_horizontal_line();
    endtask

    // Helper function:
    task _print_horizontal_line();
        for (int c = 0; c < `GRID_LEN; c++) begin
            if (c % `GRID_ORD == 0) begin
                $write("+-");
            end
            $write("--");
        end
        $write("+\n");
    endtask
endmodule : grid