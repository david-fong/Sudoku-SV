
/**
 `seed` must not be zero when resetting.
 https://en.wikipedia.org/wiki/Linear-feedback_shift_register#Some_polynomials_for_maximal_LFSRs
  2'b11
  3'b110
  4'b1100
  5'b10100
  6'b110000
  7'b1100000
  8'b10111000
  9'b100010000
 10'b1001000000
 11'b10100000000
 12'b111000001000
 */
module lfsr
#(
    int WIDTH,
    bit [WIDTH-1:0] TAPS
)(
    input  clock,
    input  reset,
    input  unsigned [WIDTH-1:0] seed,
    input  advance,
    output reg unsigned [WIDTH-1:0] out
);
    wire unsigned [WIDTH-1:0] next;
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