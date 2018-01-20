@echo off
set arg1=%1

REM Copy the files, execute
python merge.py
avrasm2 project.asm -o project.hex -fI -i m2560def.inc

REM Download the files onto the board
call download COM3 project.hex

REM Delete files if there is no first argument
IF [%1] == [] (
	rm project.asm project.hex
)