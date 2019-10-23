
`include "grid_dimensions.svh"

/**
 *
 * a tile in a grid.
 *
 */
module tile #()
(
    input   clock,
    input   reset,
    input   myturn,
    output  passbak, // nothing worked. backtrack and try something different.
    output  passfwd, // found something that worked. forge ahead.

    output  [`GRID_LEN-1:0] index_pass, // 1hot. index into parent row's bias mem.
    output  [`GRID_LEN  :0] index_fail, // 1hot. request certain entry of rowbias.
    output                  rq_rowbias, // bool. make rowbias update using rqindex.
    input   [`GRID_LEN  :0] value_test, // 1hot. value to try. request using index.
    input   [`GRID_LEN-1:0] occup_mask, // 1hot. mask of external values to avoid.
    output  [`GRID_LEN-1:0] value_pass  // 1hot. this tile's current value.
);

    enum int unsigned [6:0] {
        RESETIN = 1 << 0, // reset internal registers.
        WAITING = 1 << 1, // wait until [myturn].
        INCRIDX = 1 << 2, // upward barrel shift of rowbias index.
        RQROWBS = 1 << 3, // request row-bias with new index.
        LDROWBS = 1 << 4, // catch and hold the value of rowbias' reply.
        PASSBAK = 1 << 5, // nothing works- signal a backtrack request.
        PASSFWD = 1 << 6  // something worked- signal to continue brute-force alg.
    } s_curr, s_next;

    // moore-style outputs:
    assign passbak      = (s_curr == PASSBAK);
    assign passfwd      = (s_curr == PASSFWD);
    assign rq_rowbias   = (s_curr == RQROWBS);



    // internal counters:
    reg [`GRID_LEN:0] index;
    reg [`GRID_LEN:0] value;

    // external views of internal counters:
    assign index_pass = index[0+:`GRID_LEN];
    assign index_fail = index & {`GRID_LEN+1{1'b0}};
    assign value_pass = value[0+:`GRID_LEN];



    // always-block for [index]:
    always_ff @(posedge clock) begin: tile_index
        case (s_curr)
            // set 1-hot with most significant bit on
            // ie. the tile is initialized as empty.
            RESETIN: index <= {1'b1,{`GRID_LEN{1'b0}}};

            // barrel-shift upward:
            INCRIDX: index <= {
                index[0+:`GRID_LEN], // shift lower bits up
                index[   `GRID_LEN]  // wrap the highest bit
            };
        endcase
    end: tile_index

    // always-block for [value]:
    always_ff @(posedge clock) begin: tile_value
        case (s_curr)
            // set to all zeros:
            RESETIN: value <= 'b0;

            // catch and hold [rowbias]'s value:
            // this is incredibly important.
            LDROWBS: value <= rowbias;
        endcase
    end: tile_value



    // STATE MACHINE:
    // always-block for [s_next]. veto-able by [reset].
    always_comb begin: tile_fsm_next
        case (s_curr)
            RESETIN: s_next = WAITING;
            WAITING: s_next = myturn ? INCRIDX : WAITING;
            INCRIDX: s_next = RQROWBS;
            RQROWBS: s_next = LDROWBS;
            LDROWBS: begin // see [value]'s always block for effects.
                if (rqindex[`GRID_LEN]) begin
                    // nothing works in this tile.
                    s_next = PASSBAK;
                end
                else if (occmask & rowbias) begin
                    // the new rowbias value didn't work.
                    // keep control and try something different.
                    s_next = INCRIDX;
                end
                else begin
                    // found something that worked.
                    s_next = PASSFWD;
                end
            end
            PASSBAK: s_next = WAITING;
            PASSFWD: s_next = WAITING;
        endcase
    end: tile_fsm_next

    // always-block to update [s_curr]:
    always_ff @(posedge clock) begin: tile_fsm_curr
        if (reset) begin
            s_curr <= RESETIN;
        end
        else begin
            s_curr <= s_next;
        end
    end: tile_fsm_curr



endmodule : tile

