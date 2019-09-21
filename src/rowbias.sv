
`include "grid_dimensions.svh"

/**
 * a bus whose value is intended to be broadcasted to all tiles in a
 *     common row. values are requested from an internal pool via
 *     index into that pool. the requested value will appear on a
 *     rising clock edge if [update] is asserted.
 *
 * the internal pool contains one of each 1hot number of width
 *     `GRID_LEN+1 in random order, except the special value of all
 *     zeros, which is always addressable via the most significant
 *     bit.
 *
 * outputs are undefined if inputs attempt to index using a non-1hot
 *     value.
 */
module rowbias #(parameter w=`GRID_LEN)
(
    input clock,
    input reset,
    input update,
    input [w:0] rqindex,
    output reg [w-1:0] busvalue
);
    // initialize shufflepool:
    initial begin
        // TODO: 
        //  ideally this would be done upon each reset.
    end

    reg [w-1:0] shufflepool [w+1];

    reg [w-1:0] __busvalue;
    always_ff @(posedge clock) begin
        if (update) begin
            busvalue <= __busvalue;
        end
    end
    always_comb begin
        __busvalue = 'b0;
        for (int unsigned i = 0; i < w+1; i++) begin
            if (rqindex[i]) begin
                __busvalue = shufflepool[i];
                break;
            end
        end
    end

endmodule : rowbias



// arbiter. filter for least significant on-bit.
// currently not used since spec for rowbias does not permit non-1hot indexing.
module arbiter #(parameter w)
(
    input [w-1:0] in,
    output [w-1:0] out
);
    wire [w-1:0] scratch;
    assign scratch = in | {scratch[w-2:0],1'b0};
    assign out = in & ~scratch;
endmodule : arbiter

