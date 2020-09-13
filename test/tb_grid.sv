`include "../src/grid_dimensions.svh"
`define MAX_CLOCK_CYCLES 22500

/**
 *
 */
module tb_grid;
    reg clock;
    reg reset;
    reg [7:0] seed = 8'b1;
    reg start;
    wire rowmajor_done, rowmajor_success;
    wire blockcol_done, blockcol_success;
    grid #(.GENPATH(0)) DUT_rowmajor(.done(rowmajor_done), .success(rowmajor_success), .*);
    grid #(.GENPATH(1)) DUT_blockcol(.done(blockcol_done), .success(blockcol_success), .*);

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
        #60;
        start = 0;

        @(posedge rowmajor_done);
        $display("\n=========================");
        $display(  "        ROW_MAJOR        ");
        DUT_rowmajor.print();

        @(posedge blockcol_done);
        $display("\n=========================");
        $display(  "        BLOCK_COL        ");
        DUT_blockcol.print();
        $stop;
    end
endmodule