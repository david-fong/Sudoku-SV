`include "grid_dimensions.svh"

/**
 *
 */
module tile #()
(
    input   clock,
    input   reset,
    input   myturn,
    output  passbak, // nothing worked. backtrack and try something different.
    output  passfwd, // found something that worked. forge ahead.

    output                  rq_valtotry,    // bool. make valtotry update using biasidx.
    output  [`GRID_LEN-1:0] biasidx,        // 1hot.
    input   [`GRID_LEN-1:0] valtotry,       // 1hot. response from bias module.
    input   [`GRID_LEN-1:0] valcannotbe,    // 1hot. mask of external values to avoid.
    output reg [`GRID_LEN-1:0] value        // 1hot. this tile's current value.
);
    enum logic [6:0] {
        RESET   = 1 << 0, // reset internal registers.
        WAITING = 1 << 1, // wait until [myturn].
        INCRIDX = 1 << 2, // upward barrel shift of rowbias index.
        RQROWBS = 1 << 3, // request row-bias with new index.
        LDROWBS = 1 << 4, // catch and hold the value of rowbias' reply.
        PASSBAK = 1 << 5, // nothing works- signal a backtrack request.
        PASSFWD = 1 << 6  // something worked- signal to continue brute-force alg.
    } state;

    // moore-style outputs:
    assign passbak      = (state == PASSBAK);
    assign passfwd      = (state == PASSFWD);
    assign rq_valtotry  = (state == RQROWBS);

    reg [`GRID_LEN:0] index;
    assign biasidx = (state == RQROWBS) ? index[0+:`GRID_LEN] : 'b0;

    // always-block for [index]:
    always_ff @(posedge clock) begin: tile_index
        case (state)
            // set 1-hot with most significant bit on
            // ie. the tile is initialized as empty.
            RESET: index <= {1'b1,{`GRID_LEN{1'b0}}};

            // barrel-shift upward:
            INCRIDX: index <= {
                index[0+:`GRID_LEN], // shift lower bits up
                index[   `GRID_LEN]  // wrap the highest bit
            };
        endcase
    end

    // always-block for [value]:
    always_ff @(posedge clock) begin: tile_value
        case (state)
            RESET: value <= 'b0;
            LDROWBS: value <= index[`GRID_LEN] ? 'b0 : valtotry;
        endcase
    end


    // STATE MACHINE:
    always_ff @(posedge clock) begin: tile_fsm
        if (reset) begin
            state <= RESET;
        end
        else begin case (state)
            RESET:   state <= WAITING;
            WAITING: state <= myturn ? INCRIDX : WAITING;
            INCRIDX: state <= RQROWBS;
            RQROWBS: state <= LDROWBS;
            LDROWBS: begin // see [value]'s always block for effects.
                if (index[`GRID_LEN]) begin
                    // nothing works in this tile.
                    state <= PASSBAK;
                end
                else if (valcannotbe & valtotry) begin
                    // didn't work. retain control and try something different.
                    state <= INCRIDX;
                end
                else begin
                    // found something that worked.
                    state <= PASSFWD;
                end
            end
            PASSBAK: state <= WAITING;
            PASSFWD: state <= WAITING;
        endcase end
    end
endmodule