
//
module mydff
#( // PARAMETERS:
    parameter w;
)
( // I/O SIGNALS LIST BEGIN:
    input clock,
    input reset,
    input doload,
    input [w-1:0] loadvalue,
    output reg [w-1:0] heldvalue
); // I/O SIGNALS LIST END.

always_ff @(posedge clock) begin
    if (reset) begin heldvalue = 
end

endmodule : mydff

