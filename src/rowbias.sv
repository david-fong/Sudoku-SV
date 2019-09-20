
`include "def_griddimensions.sv"

/**
 * a bus whose value is sent to all tiles that are in a row together.
 * values can be requested from an internal pool via index into that pool.
 * the internal pool contains one of each 1-hot number of width `GRID_LEN.
 * the values are in a random order, also indexed in 1-hot format.
 * lower indices are favoured if the requesting index is not in 1-hot format,
 *   but users of this module should not rely on this behaviour.
 * a requesting index of zero indicates a request for a bus-signal of all zeros.
 */
module rowbias #(parameter w=`GRID_LEN;)
(
    input clock,
    input reset,
    input update,
    input [w-1:0] rqindex,
    output reg [w-1:0] busvalue
);
    reg [w-1:0] shufflepool [w-1:0];

    reg [w-1:0] __busvalue;
    always_ff @(posedge clock) begin
        if (reset) begin
            busvalue <= {w{1'b0}};
        end
        else if (update) begin
            busvalue <= __busvalue;
        end
        else begin
            busvalue <= busvalue;
        end
    end
    // TODO: assign __busvalue using rqindex into shufflepool.
    //  make sure to follow spec. (resolve non-1-hot, and
    //  return value for rqindex == 0).

endmodule : rowbias

