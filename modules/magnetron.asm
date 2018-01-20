; ================ Magnetron functions ======================
turnOnMagnetron:
    enablePin PORTB, PIN_MAG
	clear magnetronCounter
    ret
    
turnOffMagnetron:
    disablePin PORTB, PIN_MAG
    ret
    
setMag_1:
    ldi temp1, low(ONE_SEC)
    mov magTime_L, temp1
    ldi temp1, high(ONE_SEC)
    mov magTime_H, temp1
    ret
    
setMag_2:
    ldi temp1, low(MAG_2)
    mov magTime_L, temp1
    ldi temp1, high(MAG_2)
    mov magTime_H, temp1
    ret
    
setMag_3:
    ldi temp1, low(MAG_3)
    mov magTime_L, temp1
    ldi temp1, high(MAG_3)
    mov magTime_H, temp1
    ret
    
checkMagnetron:
    cpi status, STATUS_RUNNING  ;turn off magnetron when not running
    brne noMagnetron
    
checkPower:
    cpi power, 1
    breq power_1
    cpi power, 2
    breq power_2
    cpi power, 3
    breq power_3
    
doneCheckMagnetron:
    ret

noMagnetron:
	clear magnetronCounter
    rcall turnOffMagnetron
    rjmp checkPower
    
;magnetron state changers
power_1:
    rcall setMag_1
    rjmp doneCheckMagnetron
    
power_2:
    rcall setMag_2
    rjmp doneCheckMagnetron
    
power_3:
    rcall setMag_3
    rjmp doneCheckMagnetron