@echo off

REM Compile
python merge.py
avrasm2 project.asm -o project.hex -fI -i m2560def.inc

REM Delete files
rm project.asm project.hex