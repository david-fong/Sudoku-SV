
`include "def_griddimensions.sv"

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
module rowbias #(parameter w=`GRID_LEN;)
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

    wire [w-1:0] __busvalue;
    always_ff @(posedge clock) begin
        if (update) begin
            busvalue <= __busvalue;
        end
    end
    wire [w-1:0] filteredshufflepool [w+1];
    generate
        for (genvar i = 0; i < w+1; i++) begin : poolentryloop
            assign filteredshufflepool[i] = {w{rqindex[i]}};
        end : poolentryloop
    endgenerate
    assign __busvalue = |filteredshufflepool;

endmodule : rowbias



// arbiter. filters for least significant on-bit.
// currently not used since spec for rowbias does not permit non-1hot indexing.
module arbiter #(parameter w;)
(
    input [w-1:0] in,
    output [w-1:0] out
);
    wire [w-1:0] scratch;
    assign scratch = in | {scratch[w-2:0],1'b0};
    assign out = in & ~scratch;
endmodule : arbiter

