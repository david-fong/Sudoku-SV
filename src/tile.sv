
`include "def_griddimensions.sv"

typedef enum logic [2:0] {
    INITIAL, // nothing happens here. waits until [myturn].
    INCRIDX, // upward barrel shift of rowbias index.
    RQROWBS, // request row-bias with new index.
    LDROWBS, // catch and hold the value of rowbias' reply.
    PASSBAK, // nothing works- signal a backtrack request.
    PASSFWD  // something worked- signal to continue brute-force alg.
} tile_fsm_state;



/**
 *
 * a tile in a grid.
 *
 * should be able to assert !(occupiedmask^value).
 *
 */
module tile #()
(
    input clock,
    input reset,
    input myturn,
    output passbak, // nothing worked. backtrack and try something different.
    output passfwd, // found something that worked. forge ahead.

    output reg  [`GRID_LEN  :0] rqindex,        // 1hot. request certain entry of rowbias.
    output                      updaterowbias   // bool. make rowbias update using rqindex.
    input       [`GRID_LEN-1:0] rowbias,        // 1hot. value to try. request using index.
    input       [`GRID_LEN-1:0] occupiedmask,   // 1hot. mask of external values to avoid.
    output reg  [`GRID_LEN-1:0] value,          // 1hot. this tile's current value.
);

    tile_fsm_state s_curr;
    tile_fsm_state s_next;

    // always-block for [rqindex]:
    always_ff @(posedge clock) begin
        if (reset) begin
            // set 1-hot with most significant bit on:
            rqindex <= {1'b1,{`GRID_LEN{1'b0}}};
        end
        else if (s_curr == INCRIDX) begin
            // barrel-shift upward:
            rqindex <= {rqindex[`GRID_LEN-1:0],rqindex[`GRID_LEN]};
        end
    end

    // always-block for [value]:
    always_ff @(posedge clock) begin
        if (reset) begin
            // set to all zeros:
            value <= {`GRID_LEN{1'b0}};
        end
        else if (s_curr == LDROWBS) begin
            // catch and hold [rowbias]'s value:
            // this is incredibly important.
            value <= rowbias;
        end
    end



    // STATE MACHINE:
    // always-block for [s_next]. veto-able by [reset].
    always_comb begin case (s_curr)
        INITIAL: s_next = myturn ? INCRIDX : INITIAL;
        INCRIDX: s_next = RQROWBS;
        RQROWBS: s_next = LDROWBS;
        LDROWBS: begin // see [value]'s always block for effects.
            if (rqindex[`GRID_LEN]) begin
                // nothing works in this tile.
                s_next = PASSBAK;
            end
            else if (occupiedmask & rowbias) begin
                // the new rowbias value didn't work.
                // keep control and try something different.
                s_next = INCRIDX;
            end
            else begin
                // found something that worked.
                s_next = PASSFWD;
            end
        end
        PASSBAK: s_next = INITIAL;
        PASSFWD: s_next = INITIAL;
    endcase; end

    // always-block to update [s_curr]:
    always_ff @(posedge clock) begin
        if (reset) begin
            s_curr <= INITIAL;
        end
        else begin
            s_curr <= s_next;
        end
    end



    // output assignments:
    assign passbak = (s_curr == PASSBAK);
    assign passfwd = (s_curr == PASSFWD);
    assign updaterowbias = (s_curr == RQROWBIAS);


endmodule : tile

