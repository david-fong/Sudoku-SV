
`include "def_gridorder.sv"

// do not change these.
// importing def_gridorder is not necessary if this file is imported.
`ifndef DEFINE_GRIDDIMENSIONS
`define DEFINE_GRIDDIMENSIONS
    `define GRID_LEN GRID_ORD * GRID_ORD // grid length
    `define GRID_BGA GRID_ORD * GRID_LEN // block-group area
    `define GRID_ARE GRID_LEN * GRID_LEN // grid area
`endif

