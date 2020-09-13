`include "grid_dimensions.svh"

typedef enum {
    ROW_MAJOR,
    BLOCK_COL
} genpath_t;

/**
 * a network of tiles that form a sudoku grid.
 */
module grid
#(
    parameter genpath_t GENPATH = BLOCK_COL,
    parameter int LFSR_WIDTH = 8,
    parameter bit [LFSR_WIDTH-1:0] LFSR_TAPS = 8'b10111000
)(
    input clock,
    input reset,
    input start,
    input [LFSR_WIDTH-1:0] seed,
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
        RESET        = 5'b1 << 0, //
        START        = 5'b1 << 1, //
        WAIT         = 5'b1 << 2, //
        DONE_SUCCESS = 5'b1 << 3, //
        DONE_FAILURE = 5'b1 << 4  //
    } state;
    int unsigned ready_countdown;

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
    wire [`GRID_LEN-1:0][`GRID_LEN-1:0] rq_valtotry;
    wire [`GRID_LEN-1:0] valtotry [`GRID_LEN-1:0];

    // occupancy signals:
    // [values] is in row-major order.
    wire [`GRID_LEN-1:0] rowmajorvalues [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire [`GRID_LEN-1:0] colmajorvalues [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire [`GRID_LEN-1:0] blkmajorvalues [`GRID_LEN-1:0][`GRID_LEN-1:0];
    wire [`GRID_LEN-1:0] rowalreadyhas  [`GRID_LEN-1:0];
    wire [`GRID_LEN-1:0] colalreadyhas  [`GRID_LEN-1:0];
    wire [`GRID_LEN-1:0] blkalreadyhas  [`GRID_LEN-1:0];


    // reset procedure:
    always_ff @(posedge clock) begin: grid_done_reset
        if (reset) begin
            ready_countdown <= `GRID_LEN * 3; // See `reset_chain` for rowbias modules.
        end
        else if (ready_countdown > 0) begin
            ready_countdown--;
        end
    end

    // STATE MACHINE:
    always_ff @(posedge clock) begin: grid_state
        if (reset) begin
            state <= RESET;
        end
        else begin case (state)
            RESET: state <= ((ready_countdown == 0) & start) ? START : RESET;
            START: state <= WAIT;
            WAIT: begin state <= (
                tvs_passbaks[0] ? DONE_FAILURE
                : tvs_passfwds[`GRID_AREA-1] ? DONE_SUCCESS
                : WAIT); end
            DONE_SUCCESS: state <= DONE_SUCCESS;
            DONE_FAILURE: state <= DONE_FAILURE;
        endcase end
    end


    // generate [rowbias] modules:
    generate
        wire [LFSR_WIDTH-1:0] random;
        lfsr #(
            .WIDTH(LFSR_WIDTH),
            .TAPS(LFSR_TAPS)
        ) LFSRx(
            .advance(state == RESET),
            .out(random),
            .*
        );
        reg [`GRID_LEN-1:0] reset_chain;
        always_ff @(posedge clock) begin
            reset_chain <= {reset_chain[`GRID_LEN-2:0],reset};
        end
        genvar rbr;
        for (rbr = 0; rbr < `GRID_LEN; rbr++) begin: gen_rowbias // rows
            wor [`GRID_LEN-1:0] rqindex;
            genvar rbc;
            for (rbc = 0; rbc < `GRID_LEN; rbc++) begin: gen_wor_rqindex
                assign rqindex = biasidx[rbr][rbc];
            end
            rowbias #(.RAND_WIDTH(LFSR_WIDTH)) ROWBIASx(
                .clock,
                .reset(reset_chain[rbr]),
                .random,
                .update(|rq_valtotry[rbr]),
                .rqindex(rqindex),
                .valtotry(valtotry[rbr])
            );
        end // rows
    endgenerate

    // generate [tile] modules:
    generate
        genvar tlr;
        for (tlr = 0; tlr < `GRID_LEN; tlr++) begin: gen_tile_row // rows
        genvar tlc;
        for (tlc = 0; tlc < `GRID_LEN; tlc++) begin: gen_tile_col // cols
            int unsigned tli = (tlr * `GRID_LEN) + tlc;
            tile /*#()*/ TILEx(
                .clock,
                .reset,
                .myturn(myturns[tli]),
                .passbak(rowmaj_passbaks[tlr][tlc]),
                .passfwd(rowmaj_passfwds[tlr][tlc]),
                .biasidx(biasidx[tlr][tlc]),
                .rq_valtotry(rq_valtotry[tlr][tlc]),
                .valtotry(valtotry[tlr]),
                .valcannotbe({
                    rowalreadyhas[tlr] |
                    colalreadyhas[tlc] |
                    blkalreadyhas[blockof(tlr,tlc)]
                }),
                .value(rowmajorvalues[tlr][tlc])
            );
        end // cols
        end // rows
    endgenerate

    // traversal path:
    generate
        wire [`GRID_AREA-1:0] rowmaj_passbaks_packed;
        wire [`GRID_AREA-1:0] rowmaj_passfwds_packed;
        genvar gpr;
        genvar gpc;
        for (gpr = 0; gpr < `GRID_LEN; gpr++) begin: gen_pass_row
        for (gpc = 0; gpc < `GRID_LEN; gpc++) begin: gen_pass_col
            assign rowmaj_passbaks_packed[gpr*`GRID_LEN+gpc] = rowmaj_passbaks[gpr][gpc];
            assign rowmaj_passfwds_packed[gpr*`GRID_LEN+gpc] = rowmaj_passfwds[gpr][gpc];
        end
        end
        case (GENPATH)
        ROW_MAJOR: begin
            assign tvs_passbaks = rowmaj_passbaks_packed;
            assign tvs_passfwds = rowmaj_passfwds_packed;
        end
        BLOCK_COL: begin
            genvar gpbci;
            for (gpbci = 0; gpbci < `GRID_BGA; gpbci++) begin: gen_genpath_blockcol
                const int unsigned tvsidx = (gpbci%`GRID_ORD) + (gpbci/`GRID_ORD*`GRID_ORD);
                assign tvs_passbaks[gpbci*`GRID_ORD+:`GRID_ORD] = rowmaj_passbaks_packed[tvsidx*`GRID_ORD+:`GRID_ORD];
                assign tvs_passfwds[gpbci*`GRID_ORD+:`GRID_ORD] = rowmaj_passfwds_packed[tvsidx*`GRID_ORD+:`GRID_ORD];
            end
        end
        endcase
    endgenerate

    // generate [OR] modules for [tile.valcannotbe] inputs:
    generate
        genvar vcbi;
        for (vcbi = 0; vcbi < `GRID_LEN; vcbi++) begin: gen_alreadyhas
            wor [`GRID_LEN-1:0] _rowalreadyhas;
            wor [`GRID_LEN-1:0] _colalreadyhas;
            wor [`GRID_LEN-1:0] _blkalreadyhas;
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
    // r and c are in terms of row-major-order. nothing convoluted.
    generate
        genvar r;
        genvar c;
        for (r = 0; r < `GRID_LEN; r++) begin: gen_colmajorvalues_row // rows
        for (c = 0; c < `GRID_LEN; c++) begin: gen_colmajorvalues_col // cols
            assign colmajorvalues[c][r] = rowmajorvalues[r][c];
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