;======================= timer0 Interrupt handler ==========================
Timer0OVF:
    push temp1
    in temp1, SREG          ;preserve our variables
    push temp1
    push temp2

    ; Enable the speaker
    call enableSpeaker

    ; Increment the debounce counter,
    ; reset the debounce mode if necessary
    rcall incrementDebounce

    ; Increment door counter
    rcall incrementDoor

    ; Increment fin sound
    rcall incrementFinSound

    cpi status, STATUS_RUNNING
    brne skip_running

    ; Increment seconds counter, decrement seconds where
    ; necessary
    rcall decrementSeconds

    ; Increment turn counter
    rcall incrementTurn

    ; Increment Magnetron counter (magnetron)
    rcall IncrementMag

skip_running:
    ; Disable sound
    disablePin PORT_SPEAKER, PIN_SPEAKER

    ; Restore from stack
    pop temp2
    pop temp1
    out SREG, temp1
    pop temp1
    reti

; Increment debounce counter
incrementDebounce:
    push temp2
    push temp1
    push XL
    push XH

    lds XL, debounceCounter
    lds XH, debounceCounter+1

    adiw XH:XL, 1               ; DebounceCounter++
    cpi XL, low(DB_SEC+1)       ; check if ~200ms has passed (1700 interrupts)
    ldi temp1, high(DB_SEC+1)
    cpc XH, temp1
    breq resetDebounce
    brsh incrementDebounce_end

    rjmp enableIdle

resetDebounce:
    sts PORTL, lastcMask ; check if the button is being held on to
    ldi temp1, 0xFF 

ddelay: 
    dec temp1
    brne ddelay
    lds temp1, PINL       ; Read PINL
    andi temp1, ROWMASK   ; Get the keypad output value

    mov temp2, temp1
    and temp2, lastrMask  ; check un-masked bit
    breq continueDebounce ; if bit is clear, the key is pressed

    clr debounce
    jmp incrementDebounce_update

continueDebounce:
    lds XL, 0
    lds XH, 0

enableIdle:
    clear idleCounter
    clear keySoundCounter
    lds temp1, brightness
    cpi temp1, 255
    brlo enableFade
    rjmp incrementDebounce_update

enableFade:
    ldi temp1, FADE_ON
    sts fadeMode, temp1

incrementDebounce_update:
    sts debounceCounter, XL   ; Store the debounce counter
    sts debounceCounter+1, XH

incrementDebounce_end:
    pop XH
    pop XL
    pop temp1
    pop temp2
    ret

decrementSeconds:
    push temp1
    push XL
    push XH

    lds XL, secondsCounter 
    lds XH, secondsCounter+1 
    adiw XH:XL, 1
    cpi XL, low(SEC_SEC)
    ldi temp1, high(SEC_SEC) 
    cpc XH, temp1
    breq decrementSeconds_set

    sts secondsCounter, XL
    sts secondsCounter+1, XH
    jmp decrementSeconds_end

decrementSeconds_set:
    clr tick
    
decrementSeconds_end:
    pop XH
    pop XL
    pop temp1
    ret

incrementDoor:
    push temp1
    push XL
    push XH

    lds XL, doorCounter 
    lds XH, doorCounter+1 
    adiw XH:XL, 1
    cpi XL, low(DOOR_SEC)
    ldi temp1, high(DOOR_SEC) 
    cpc XH, temp1
    breq incrementDoor_set

    sts doorCounter, XL
    sts doorCounter+1, XH
    jmp incrementDoor_end

incrementDoor_set:
    clr doorDeb
    clear doorCounter

incrementDoor_end:
    pop XH
    pop XL
    pop temp1
    ret

incrementFinSound_fastend: ret
incrementFinSound:
    tst finSound
    breq incrementFinSound_fastend

    push XL
    push XH
    push temp1

    lds XL, finSoundCounter
    lds XH, finSoundCounter+1
    adiw XH:XL, 1
    cpi XL, low(FINSOUND_SEC)
    ldi temp1, high(FINSOUND_SEC)
    cpc XH, temp1
    breq enableFinSound

    sts finSoundCounter, XL
    sts finSoundCounter+1, XH
    rjmp incrementFinSound_end

enableFinSound:
    mov temp1, finSound
    cpi temp1, 6
    breq disableFinSound
    inc finSound
    clear finSoundCounter
    rjmp incrementFinSound_end

disableFinSound:
    clr finSound

incrementFinSound_end:
    pop temp1
    pop XH
    pop XL
    ret

incrementTurn:
    push temp1
    push XL
    push XH

    lds XL, turnCounter 
    lds XH, turnCounter+1 
    adiw XH:XL, 1
    cpi XL, low(TURN_SEC)
    ldi temp1, high(TURN_SEC) 
    cpc XH, temp1
    breq update_turnState

    sts turnCounter, XL
    sts turnCounter+1, XH
    jmp incrementTurn_end

update_turnState:
    tst clockwise           ;check clockwise or anti clockwise
    sbrc clockwise, 0       ;check if clockwise is 0
    rjmp dec_turnState
    inc turnState
    
turnState_Updated:
    clear turnCounter

turn_wrapping:              ;works like a mod function
    ldi temp1, 4
    cp turnState, temp1
    breq wrap_turnState
    
incrementTurn_end:
    pop XH
    pop XL
    pop temp1
    ret
    
dec_turnState:
    tst turnState 
    breq rewrap_turnState
    dec turnState
    rjmp turnState_Updated
    
wrap_turnState:
    clr turnState
    rjmp incrementTurn_end

rewrap_turnState:
    ldi temp1, 4
    mov turnState, temp1
    rjmp incrementTurn_end

IncrementMag:
    push temp1
    push XL
    push XH

    lds XL, magnetronCounter 
    lds XH, magnetronCounter+1 
    adiw XH:XL, 1
    
    cpi XL, low(ONE_SEC)        ; every second we turn it back on
    ldi temp1, high(ONE_SEC)
    cpc XH, temp1
    breq magnetron_secondup
    
    cp XL, magTime_L
    cpc XH, magTime_H
    breq off_magnetron  
    
    rjmp save_magCounter
    
off_magnetron:
    rcall turnOffMagnetron
    rjmp save_magCounter
    
magnetron_secondup: 
    rcall turnOnMagnetron
    clear magnetronCounter
    rjmp doneMagnetron
    
save_magCounter:
    sts magnetronCounter, XL
    sts magnetronCounter+1, XH
    
doneMagnetron:
    pop XH
    pop XL
    pop temp1
    ret