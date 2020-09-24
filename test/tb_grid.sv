`include "../src/grid_dimensions.svh"
`include "../src/grid.sv"
`define MAX_CLOCK_CYCLES (6100)

/**
 *
 */
module tb_grid;
    reg clock;
    reg reset;
    reg [3:0] seed = 1;

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
    genvar genpath;
    generate
        for (genpath = 0; genpath < 2; genpath++) begin: genpaths
            genpath_t gp = genpath_t'(genpath);
            reg rq_start;
            wire done, success;
            grid #(.GENPATH(genpath)) DUTx(.*);
            initial begin: main
                rq_start = 0;
                reset = 0;
                #1;
                reset = 1;
                #2;
                reset = 0;
                #2;
                rq_start = 1;
                #350;
                rq_start = 0;

                @(posedge done);
                $display("\n=========================");
                $write("        %s        \n", gp.name);
                DUTx.print();
            end
        end
    endgenerate
endmodule