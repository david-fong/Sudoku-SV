`include "../src/grid_dimensions.svh"
`define MAX_CLOCK_CYCLES 20000

/**
 *
 */
module tb_grid;
    reg clock;
    reg reset;
    reg start;
    wire done;
    wire success;
    grid #() DUT(.*);

    // clock process:
    initial begin: tb_clock
        clock = 0;
        forever begin clock = ~clock; #1; end
    end
    // emergency break:
    initial forever begin: emergency_break
        #(2 * `MAX_CLOCK_CYCLES);
        $display("\nthe testbench hit the emergency break.");
        $stop;
    end

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

        @(posedge done);
        $display("=========================");
        $display("          DONE!          ");
        $display("=========================");
        DUT.print();
        #10;
        $stop;
    end: main
endmodule