`include "grid_dimensions.svh"

typedef enum {
    ROW_MAJOR,
    BLOCK_COL
} genpath_t;

// get block number given a row number and column number:
function int unsigned blockof (
    int unsigned row,
    int unsigned col
);
    return ((row/`GRID_ORD)*`GRID_ORD) + (col/`GRID_ORD);
endfunction

function automatic int unsigned f_gp2pos_rowmajor (int unsigned gpi);
    automatic int unsigned row = gpi / `GRID_LEN;
    automatic int unsigned col = gpi % `GRID_LEN;
    return (row*`GRID_LEN) + (((row % 2) == 0) ? col : (`GRID_LEN-1-col));
endfunction

function automatic int unsigned f_gp2pos_blockcol (int unsigned gpi);
    automatic int unsigned gpr = gpi / `GRID_LEN, gpc = gpi % `GRID_LEN;
    automatic int unsigned slice = (gpc % `GRID_ORD);
    automatic int unsigned row   = (gpc / `GRID_ORD) * `GRID_ORD;
    automatic int unsigned blkcol;
    if ( ((gpr%2)==0) == (((gpc/`GRID_ORD)%2)==0) ) begin
        slice = `GRID_ORD - 1 - slice;
    end;
    if ((gpc/`GRID_ORD)%2==0) begin
        row   += gpr / `GRID_ORD;
        blkcol = gpr % `GRID_ORD;
    end
    else begin
        row   += (`GRID_LEN-1-gpr) / `GRID_ORD;
        blkcol = (`GRID_LEN-1-gpr) % `GRID_ORD;
    end
    // $display("r%2h,c%2h", row, (blkcol * `GRID_ORD) + slice);
    return (row*`GRID_LEN) + (blkcol*`GRID_ORD)+slice;
endfunction

/**
 * a network of tiles that form a sudoku grid.
 */
module grid
#(
    parameter genpath_t            GENPATH    = BLOCK_COL,
    parameter int                  LFSR_WIDTH = 4,
    parameter bit [LFSR_WIDTH-1:0] LFSR_TAPS  = 4'b1100
)(
    input  clock,
    input  reset,
    input  rq_start,
    input  unsigned [LFSR_WIDTH-1:0] seed,
    output done,
    output success
    // TODO.design an interface to request and serially receive the solution data.
);

    function automatic int unsigned f_gp2pos (int unsigned gpi);
        case (GENPATH)
            ROW_MAJOR: begin
                return f_gp2pos_rowmajor(gpi);
            end
            BLOCK_COL: begin
                return f_gp2pos_blockcol(gpi);
            end
        endcase
    endfunction

    enum logic [4:0] {
        RESET        = 5'b1 << 0, //
        START        = 5'b1 << 1, //
        WAIT         = 5'b1 << 2, //
        DONE_SUCCESS = 5'b1 << 3, //
        DONE_FAILURE = 5'b1 << 4  //
    } state;
    wire ready;

    assign done    = (state == DONE_SUCCESS) | (state == DONE_FAILURE);
    assign success = (state == DONE_SUCCESS);

    // chaining and success signals:
    wire unsigned pos_pbak [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire unsigned pos_pfwd [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire unsigned [`GRID_AREA-1:0] tvs_pbak;
    wire unsigned [`GRID_AREA-1:0] tvs_pfwd;
    wire unsigned [`GRID_AREA-1:0] myturns = tvs_pbak | tvs_pfwd;

    // [rowbias] signals:
    wire unsigned [`GRID_LEN-1:0] biasidx     [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wor  unsigned [`GRID_LEN-1:0] biasidx_wor [`GRID_LEN-1:0];
    wire unsigned [`GRID_LEN-1:0] valtotry    [`GRID_LEN-1:0];

    // occupancy signals:
    // [values] is in row-major order.
    wire unsigned [`GRID_LEN-1:0] rowmajorvalues_next [`GRID_LEN-1:0][`GRID_LEN-1:0];
    reg  unsigned [`GRID_LEN-1:0] rowmajorvalues [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire unsigned [`GRID_LEN-1:0] colmajorvalues [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire unsigned [`GRID_LEN-1:0] blkmajorvalues [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire unsigned [`GRID_LEN-1:0] rowalreadyhas  [`GRID_LEN-1:0];
    wire unsigned [`GRID_LEN-1:0] colalreadyhas  [`GRID_LEN-1:0];
    wire unsigned [`GRID_LEN-1:0] blkalreadyhas  [`GRID_LEN-1:0];


    // STATE MACHINE:
    always_ff @(posedge clock) begin: grid_state
        if (reset) begin;
            state <= RESET;
        end
        else begin case (state)
            RESET: state <= (rq_start & ready) ? START : RESET;
            START: state <= WAIT;
            WAIT: begin state <= (
                pos_pbak[f_gp2pos(0)/`GRID_LEN][f_gp2pos(0)%`GRID_LEN] ? DONE_FAILURE
                : pos_pfwd[f_gp2pos(`GRID_AREA-1)/`GRID_LEN][f_gp2pos(`GRID_AREA-1)%`GRID_LEN] ? DONE_SUCCESS
                : WAIT); end
            DONE_SUCCESS: state <= DONE_SUCCESS;
            DONE_FAILURE: state <= DONE_FAILURE;
        endcase end
    end


    // generate [rowbias] modules:
    rowbias #(
        .ORD(`GRID_ORD),
        .LFSR_WIDTH(LFSR_WIDTH),
        .LFSR_TAPS(LFSR_TAPS)
    ) ROWBIASx(
        .clock,
        .reset,
        .seed,
        .ready,
        .index(biasidx_wor),
        .valtotry
    );
    // genvar rbr;
    // for (rbr = 0; rbr < `GRID_LEN; rbr++) begin: gen_rowbias // rows
    // end // rows

    // generate [tile] modules:
    generate
        genvar tlr, tlc;
        for (tlr = 0; tlr < `GRID_LEN; tlr++) begin: r // rows
        for (tlc = 0; tlc < `GRID_LEN; tlc++) begin: c // cols
            int unsigned tli = (tlr * `GRID_LEN) + tlc;
            assign biasidx_wor[tlr] = biasidx[tlr][tlc];
            tile /*#()*/ TILEx(
                .clock,
                .reset,
                .myturn(myturns[tli]),
                .passbak(pos_pbak[tlr][tlc]),
                .passfwd(pos_pfwd[tlr][tlc]),
                .biasidx( biasidx[tlr][tlc]),
                .valtotry(valtotry[tlr]),
                .valcannotbe({
                    rowalreadyhas[tlr] |
                    colalreadyhas[tlc] |
                    blkalreadyhas[blockof(tlr,tlc)]
                }),
                .value(rowmajorvalues_next[tlr][tlc])
            );
        end // cols
        end // rows
    endgenerate
    always_ff @(posedge clock) begin
        rowmajorvalues <= rowmajorvalues_next;
    end

    // traversal path:
    generate
        int unsigned gp2pos [`GRID_AREA-1:0];
        int unsigned pos2gp [`GRID_AREA-1:0];
        initial begin
            for (int unsigned gpi = 0; gpi < `GRID_AREA; gpi++) begin: gen_gp2pos
                gp2pos[gpi] = f_gp2pos(gpi);
            end
            for (int unsigned gpi = 0; gpi < `GRID_AREA; gpi++) begin: gen_pos2gp
                pos2gp[gp2pos[gpi]] = gpi;
            end
        end
        genvar pos;
        for (pos = 0; pos < `GRID_AREA; pos++) begin: traversal_path
            assign tvs_pbak[pos] = (pos2gp[pos] == `GRID_AREA-1) ?  1'b0 : pos_pbak[gp2pos[pos2gp[pos]+1]/`GRID_LEN][gp2pos[pos2gp[pos]+1]%`GRID_LEN];
            assign tvs_pfwd[pos] = (pos2gp[pos] == 0) ? (state == START) : pos_pfwd[gp2pos[pos2gp[pos]-1]/`GRID_LEN][gp2pos[pos2gp[pos]-1]%`GRID_LEN];
        end
    endgenerate

    // generate [OR] modules for [tile.valcannotbe] inputs:
    generate
        genvar vcbi;
        for (vcbi = 0; vcbi < `GRID_LEN; vcbi++) begin: gen_alreadyhas
            wor unsigned [`GRID_LEN-1:0] _rowalreadyhas;
            wor unsigned [`GRID_LEN-1:0] _colalreadyhas;
            wor unsigned [`GRID_LEN-1:0] _blkalreadyhas;
            genvar vcbj;
            for (vcbj = 0; vcbj < `GRID_LEN; vcbj++) begin: gen_wor_alreadyhas
                assign _rowalreadyhas = rowmajorvalues[vcbi][vcbj];
                assign _colalreadyhas = colmajorvalues[vcbi][vcbj];
                assign _blkalreadyhas = blkmajorvalues[vcbi][vcbj];
            end
            assign rowalreadyhas[vcbi] = _rowalreadyhas;
            assign colalreadyhas[vcbi] = _colalreadyhas;
            assign blkalreadyhas[vcbi] = _blkalreadyhas;
        end
    endgenerate

    // loop to map [rowmajorvalues] to [colmajorvalues]:
    generate
        genvar cmr, cmc;
        for (cmr = 0; cmr < `GRID_LEN; cmr++) begin: gen_colmajorvalues_row // rows
        for (cmc = 0; cmc < `GRID_LEN; cmc++) begin: gen_colmajorvalues_col // cols
            assign colmajorvalues[cmc][cmr] = rowmajorvalues[cmr][cmc];
        end // cols
        end // rows
    endgenerate

    // loop to map [rowmajorvalues] to [blkmajorvalues]:
    generate
        genvar b;
        genvar i;
        for (b = 0; b < `GRID_LEN; b++) begin: gen_blkmajorvalues_row // rows
        for (i = 0; i < `GRID_LEN; i++) begin: gen_blkmajorvalues_col // cols
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
    function void print();
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
    endfunction

    // Helper function:
    function void _print_horizontal_line();
        for (int c = 0; c < `GRID_LEN; c++) begin
            if (c % `GRID_ORD == 0) begin
                $write("+-");
            end
            $write("--");
        end
        $write("+\n");
    endfunction
endmodule : grid