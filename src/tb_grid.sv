`include "grid_dimensions.svh"

/**
 *
 */
module tb_grid;

    // signal mirrors:
    reg clock;
    reg reset;
    reg start;
    wire done;
    wire success;

    // device under test:
    grid #() DUT(.*);

    // clock process:
    initial begin: clock_block
        clock = 0;
        forever begin clock = ~clock; #1; end
    end
    // emergency break:
    initial begin: emergency_break #60; $stop; end

    // main process:
    initial begin: main
        start = 0;
        reset = 0;
        #1;
        reset = 1;
        #2;
        reset = 0;
        #2;
        start = 1;
        #2;
        start = 0;
        @(posedge done) $display("done!");
        $display;
        //$stop;
    end: main
endmodule