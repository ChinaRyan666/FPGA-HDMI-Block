@echo off
REM ****************************************************************************
REM Vivado (TM) v2020.2 (64-bit)
REM
REM Filename    : elaborate.bat
REM Simulator   : Xilinx Vivado Simulator
REM Description : Script for elaborating the compiled design
REM
REM Generated by Vivado on Fri Jul 07 11:05:25 +0800 2023
REM SW Build 3064766 on Wed Nov 18 09:12:45 MST 2020
REM
REM Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
REM
REM usage: elaborate.bat
REM
REM ****************************************************************************
REM elaborate design
echo "xelab -wto 4e52d9b9ca154129a047f623a8ddf8be --incr --debug typical --relax --mt 12 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -L xpm --snapshot tb_top_hdmi_block_move_behav xil_defaultlib.tb_top_hdmi_block_move xil_defaultlib.glbl -log elaborate.log"
call xelab  -wto 4e52d9b9ca154129a047f623a8ddf8be --incr --debug typical --relax --mt 12 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -L xpm --snapshot tb_top_hdmi_block_move_behav xil_defaultlib.tb_top_hdmi_block_move xil_defaultlib.glbl -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
