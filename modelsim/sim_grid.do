project compileoutofdate
vsim -gui work.tb_grid
restart -f
run -all
do ./wave_grid.do