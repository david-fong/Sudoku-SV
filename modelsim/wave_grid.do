onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix binary /tb_grid/reset
add wave -noupdate -radix binary /tb_grid/clock
add wave -noupdate -radix binary /tb_grid/start
add wave -noupdate -radix ascii -radixenum numeric /tb_grid/DUT/state
add wave -noupdate -radix binary /tb_grid/done
add wave -noupdate -radix binary /tb_grid/success
add wave -noupdate -radix hexadecimal -childformat {{{/tb_grid/DUT/rowmajorvalues[0]} -radix hexadecimal -childformat {{{/tb_grid/DUT/rowmajorvalues[0][8]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][7]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][6]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][5]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][4]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][3]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][2]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][1]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][0]} -radix binary}}} {{/tb_grid/DUT/rowmajorvalues[1]} -radix hexadecimal} {{/tb_grid/DUT/rowmajorvalues[2]} -radix hexadecimal} {{/tb_grid/DUT/rowmajorvalues[3]} -radix hexadecimal} {{/tb_grid/DUT/rowmajorvalues[4]} -radix hexadecimal} {{/tb_grid/DUT/rowmajorvalues[5]} -radix hexadecimal} {{/tb_grid/DUT/rowmajorvalues[6]} -radix hexadecimal} {{/tb_grid/DUT/rowmajorvalues[7]} -radix hexadecimal} {{/tb_grid/DUT/rowmajorvalues[8]} -radix hexadecimal}} -subitemconfig {{/tb_grid/DUT/rowmajorvalues[0]} {-height 15 -radix hexadecimal -childformat {{{/tb_grid/DUT/rowmajorvalues[0][8]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][7]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][6]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][5]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][4]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][3]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][2]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][1]} -radix binary} {{/tb_grid/DUT/rowmajorvalues[0][0]} -radix binary}}} {/tb_grid/DUT/rowmajorvalues[0][8]} {-height 15 -radix binary} {/tb_grid/DUT/rowmajorvalues[0][7]} {-height 15 -radix binary} {/tb_grid/DUT/rowmajorvalues[0][6]} {-height 15 -radix binary} {/tb_grid/DUT/rowmajorvalues[0][5]} {-height 15 -radix binary} {/tb_grid/DUT/rowmajorvalues[0][4]} {-height 15 -radix binary} {/tb_grid/DUT/rowmajorvalues[0][3]} {-height 15 -radix binary} {/tb_grid/DUT/rowmajorvalues[0][2]} {-height 15 -radix binary} {/tb_grid/DUT/rowmajorvalues[0][1]} {-height 15 -radix binary} {/tb_grid/DUT/rowmajorvalues[0][0]} {-height 15 -radix binary} {/tb_grid/DUT/rowmajorvalues[1]} {-height 15 -radix hexadecimal} {/tb_grid/DUT/rowmajorvalues[2]} {-height 15 -radix hexadecimal} {/tb_grid/DUT/rowmajorvalues[3]} {-height 15 -radix hexadecimal} {/tb_grid/DUT/rowmajorvalues[4]} {-height 15 -radix hexadecimal} {/tb_grid/DUT/rowmajorvalues[5]} {-height 15 -radix hexadecimal} {/tb_grid/DUT/rowmajorvalues[6]} {-height 15 -radix hexadecimal} {/tb_grid/DUT/rowmajorvalues[7]} {-height 15 -radix hexadecimal} {/tb_grid/DUT/rowmajorvalues[8]} {-height 15 -radix hexadecimal}} /tb_grid/DUT/rowmajorvalues
add wave -noupdate -radix decimal /tb_grid/DUT/myturns
add wave -noupdate -radix decimal /tb_grid/DUT/_passfwds
add wave -noupdate -height 15 -expand -group tile0 {/tb_grid/DUT/genblk2[0]/genblk1[0]/TILEx/index}
add wave -noupdate -height 15 -expand -group tile0 {/tb_grid/DUT/genblk2[0]/genblk1[0]/TILEx/myturn}
add wave -noupdate -height 15 -expand -group tile0 {/tb_grid/DUT/genblk2[0]/genblk1[0]/TILEx/passbak}
add wave -noupdate -height 15 -expand -group tile0 {/tb_grid/DUT/genblk2[0]/genblk1[0]/TILEx/passfwd}
add wave -noupdate -height 15 -expand -group tile0 {/tb_grid/DUT/genblk2[0]/genblk1[0]/TILEx/rq_valtotry}
add wave -noupdate -height 15 -expand -group tile0 {/tb_grid/DUT/genblk2[0]/genblk1[0]/TILEx/state}
add wave -noupdate -height 15 -expand -group tile0 {/tb_grid/DUT/genblk2[0]/genblk1[0]/TILEx/valcannotbe}
add wave -noupdate -height 15 -expand -group tile0 {/tb_grid/DUT/genblk2[0]/genblk1[0]/TILEx/valtotry}
add wave -noupdate -height 15 -expand -group tile0 {/tb_grid/DUT/genblk2[0]/genblk1[0]/TILEx/value}
add wave -noupdate -height 15 -expand -group tile1 {/tb_grid/DUT/genblk2[0]/genblk1[1]/TILEx/index}
add wave -noupdate -height 15 -expand -group tile1 {/tb_grid/DUT/genblk2[0]/genblk1[1]/TILEx/state}
add wave -noupdate {/tb_grid/DUT/genblk1[0]/ROWBIASx/update}
add wave -noupdate {/tb_grid/DUT/genblk1[0]/ROWBIASx/rqindex}
add wave -noupdate {/tb_grid/DUT/genblk1[0]/ROWBIASx/busvalue}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {26 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 151
configure wave -valuecolwidth 66
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {19 ps} {35 ps}
