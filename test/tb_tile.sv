`include "../src/grid_dimensions.svh"

/**
 * a
 */
module tb_tile;

    // signal mirrors:
    reg clock;
    reg reset;
    reg myturn;
    wire passbak;
    wire passfwd;

    // more signal mirrors:
    wire [`GRID_LEN:0] rqindex;
    wire updaterowbias;
    reg [`GRID_LEN-1:0] rowbias;
    reg [`GRID_LEN-1:0] occupiedmask;
    wire [`GRID_LEN-1:0] value;

    // device under test:
    tile #() DUT(.*);



    // emergency break:
    initial begin #10_000; $stop; end

    // clock process:
    initial begin
        clock = 0;
        forever begin
            clock = ~clock;
            #5;
        end
    end



    // main process:
    initial begin
        myturn = 0;
        reset  = 0; #5;
        reset  = 1; #10;
        reset  = 0;
        myturn = 1; #10;
        myturn = 0; #5;
        $stop;
    end
endmodule