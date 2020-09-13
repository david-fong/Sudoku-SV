
/**
 * `seed` must not be zero when resetting.
 */
module lfsr
#(
    int WIDTH,
    bit [WIDTH-1:0] TAPS
)(
    input  clock,
    input  reset,
    input  [WIDTH-1:0] seed,
    input  advance,
    output reg [WIDTH-1:0] out
);
    wire [WIDTH-1:0] next;
    generate
        genvar i;
        for (i = 0; i < WIDTH - 1; i++) begin: gen_lfsr_next
            assign next[i] = TAPS[i] ? out[0] ^ out[i+1] : out[i+1];
        end
    endgenerate
    assign next[WIDTH-1] = out[0];

    always_ff @(posedge clock) begin
        if (reset) begin
            out <= seed;
        end
        else if (advance) begin
            out <= next;
        end
    end
endmodule