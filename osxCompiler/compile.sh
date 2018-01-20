#!/bin/bash
# Copy the files, execute
python ../winCompiler/merge.py
wine ~/.wine/drive_c/Program\ Files/Atmel/AVR\ Tools/AvrAssembler2/avrasm2.exe -fI -W+ie -C V3 -o project.hex project.asm

# Delete files
if [ "$#" -eq 0 ]; then
    rm project.asm project.hex
fi