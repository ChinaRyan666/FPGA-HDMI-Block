######################################################################
#
# File name : tb_top_hdmi_block_move_simulate.do
# Created on: Fri Jul 07 11:07:44 +0800 2023
#
# Auto generated by Vivado for 'behavioral' simulation
#
######################################################################
vsim -voptargs="+acc" -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -L xpm -lib xil_defaultlib xil_defaultlib.tb_top_hdmi_block_move xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {tb_top_hdmi_block_move_wave.do}

view wave
view structure
view signals

do {tb_top_hdmi_block_move.udo}

run 1000ns
