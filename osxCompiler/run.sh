#!/bin/bash
# Copy the files, execute
python ../winCompiler/merge.py
wine ~/.wine/drive_c/Program\ Files/Atmel/AVR\ Tools/AvrAssembler2/avrasm2.exe -fI -W+ie -C V3 -I ./ -o project.hex project.asm

# Upload to board
avrdude -c wiring -p m2560 -P /dev/tty.usbmodem* -b 115200 -U flash:w:project.hex:i -D

# Delete files
if [ $# -eq 0 ]; then
    rm *.asm project.hex
fi
