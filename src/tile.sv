
`include "def_griddimensions.sv"

// state definitions:
`define TILE_S_STATEWIDTH 4
`define TILE_S_INITIAL 4'd0 // nothing happens here
`define TILE_S_INCRIDX 4'd1 // upward barrel shift of rowbias index
`define TILE_S_RQROWBS 4'd2 // request row-bias with new index
`define TILE_S_LDROWBS 4'd3 // catch and hold the value of rowbias' reply
`define TILE_S_PASSBAK 4'd4 // nothing works- signal a backtrack request
`define TILE_S_PASSFWD 4'd5 // something worked- signal to continue brute-force alg



/**
 *
 * a tile in a grid.
 *
 * should be able to assert !(occupiedmask^value).
 *
 */
module tile #()

( // I/O SIGNALS LIST BEGIN:

    input clock,
    input reset,
    input myturn,

    output passbak, // backtrack and try something different.
    output passfwd, // found something that worked. forge onward.

    output reg    [`GRID_LEN:0] rqindex,        // 1-hot. request certain entry of rowbias.
    output                      updaterowbias   //  bool. make rowbias update using rqindex.
    input       [`GRID_LEN-1:0] rowbias,        // 1-hot. value to try. request using index.
    input       [`GRID_LEN-1:0] occupiedmask,   // 1-hot. mask of external values to avoid.
    output reg  [`GRID_LEN-1:0] value,          // 1-hot. this tile's current value.

); // I/O SIGNALS LIST END.

    reg [`TILE_S_STATEWIDTH-1:0] s_curr, s_next;

    // always-block for rqindex:
    always_ff @(posedge clock) begin
        if (reset) begin
            // set 1-hot with most significant bit on:
            rqindex <= {1'b1,{`GRID_LEN{1'b0}}};
        end
        else if (s_curr == `TILE_S_INCRIDX) begin
            // barrel-shift upward:
            rqindex <= {rqindex[`GRID_LEN-1:0],rqindex[`GRID_LEN]};
        end
    end

    // always-block for value:
    always_ff @(posedge clock) begin
        if (reset) begin
            // set to all zeros:
            value <= {`GRID_LEN{1'b0}};
        end
        else if (s_curr == `TILE_S_LDROWBS) begin
            // catch and hold [rowbias]'s value:
            // this is incredibly important.
            value <= rowbias;
        end
    end



    // STATE MACHINE:
    always_comb begin case (s_curr)
        `TILE_S_INITIAL: s_next = myturn ? `TILE_S_INCRIDX : `TILE_S_INITIAL;
        `TILE_S_INCRIDX: s_next = `TILE_S_RQROWBS;
        `TILE_S_RQROWBS: s_next = `TILE_S_LDROWBS;
        `TILE_S_LDROWBS: begin // see [value]'s always block for effects.
            if (rqindex[`GRID_LEN]) begin
                s_next = `TILE_S_PASSBAK;
            end
            else if (occupiedmask & rowbias) begin
                s_next = `TILE_S_INCRIDX;
            end
            else begin
                s_next = `TILE_S_PASSFWD;
            end
        end
        `TILE_S_PASSBAK: s_next = `TILE_S_INITIAL;
        `TILE_S_PASSFWD: s_next = `TILE_S_INITIAL;
    endcase; end

    // always-block to update current state:
    always_ff @(posedge clock) begin
        if (reset) begin
            s_curr <= `TILE_S_INITIAL;
        end
        else begin
            s_curr <= s_next;
        end
    end



    // output assignments:
    assign passbak = (s_curr == `TILE_S_PASSBAK);
    assign passfwd = (s_curr == `TILE_S_PASSFWD);


endmodule : tile

