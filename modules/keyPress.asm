handleKeyPress_fastReturn:
    resetKey
    ret

handleKeyPress:
    cpi keyPress, KEY_FALSE
    breq handleKeyPress_fastReturn
    tst open ; If it is open
    brne handleKeyPress_fastReturn

    push temp1
    push temp2

    cpi keyPress, '#' ; Hash
    breq handleKeyPress_hash
    cpi keyPress, '*' ; Star
    breq handleKeyPress_star
    cpi keyPress, 'A' ; A letter
    brge handleKeyPress_letter

    cpi keyPress, 10 ; A number
    brlt handleKeyPress_Number

handleKeyPress_hash:
    cpi status, STATUS_RUNNING
    breq pauseOperation
    cpi status, STATUS_POWER
    breq returnToEntry

    ; All other states clears the time
    ; PAUSED, FINISHED and ENTRY
    clr finSound
    inc updateScr
    ldi minutes, 0
    ldi seconds, 0
    cpi status, STATUS_ENTRY
    breq skipChangeDirection
    changeTurnDirection
    ldi status, STATUS_ENTRY

skipChangeDirection:
    jmp handleKeyPress_End

pauseOperation:
    ldi status, STATUS_PAUSED
    jmp handleKeyPress_End

returnToEntry:
    ldi status, STATUS_ENTRY
    inc updateScr
	rcall clearDisplay
    jmp handleKeyPress_End

handleKeyPress_star:
    ; Check status
    cpi status, STATUS_POWER
    breq handleKeyPress_End
    cpi status, STATUS_FINISHED
    breq handleKeyPress_End
    cpi status, STATUS_RUNNING
    breq addOneMinute

; Default for PAUSED or ENTRY
moveToRunning:
    clear secondsCounter
    clr tick
    inc tick
    ldi status, STATUS_RUNNING
	rcall turnOnMagnetron
    mov temp1, seconds
    or temp1, minutes
    cpi temp1, 0
    breq addOneMinute
    jmp handleKeyPress_End

addOneMinute:
    cpi minutes, 99
    brge handleKeyPress_End
    inc minutes
    jmp handleKeyPress_End

handleKeyPress_Number:
    cpi status, STATUS_POWER
    breq setPowerState
    cpi status, STATUS_ENTRY
    brne handleKeyPress_End
    rcall incrementKey
    jmp handleKeyPress_End

handleKeyPress_letter:
    cpi keyPress, 'A'
    breq handleKeyPress_letter_jmp
    cpi status, STATUS_RUNNING
    brne handleKeyPress_End
    jmp handleKeyPress_AddSubtract

handleKeyPress_letter_jmp:
    jmp switchToPowerStatus

handleKeyPress_End:
    pop temp2
    pop temp1
    resetKey
    ret

setPowerState:
    ; Ensure that it is 1-3
    cpi keyPress, 0
    breq handleKeyPress_End
    cpi keyPress, 4
    brge handleKeyPress_End

    dec keyPress
    getCharAt temp1, powerStates, keyPress
    inc keyPress
    out PORTC, temp1
    mov power, keyPress
    jmp handleKeyPress_End
	
; Uses whatever is in keyPress (ascii), adds it to
; the seconds, with overflow if necessary
incrementKey:
    push temp1
    push temp2

    ; Check minutes
    cpi minutes, 10
    brge incrementKey_end

    ; Overflow is needed when:
    ; seconds >= 10 || minutes >= 1
    cpi seconds, 10
    brge seconds_overflow
    cpi minutes, 1
    brge seconds_overflow

    rjmp minutes_skip

seconds_overflow:
    ; EXAMPLE minutes = 2, seconds = 56, input = 2
    mov temp1, seconds    ; temp1 = 56
    mov temp2, temp1      ; temp2 = 56
    dividei temp1, 10     ; temp1 = 5
    multiplyi minutes, 10 ; minutes = 20
    add minutes, temp1    ; minutes = 25
    
    ; x = x - 10 * floor(x/10)
    multiplyi temp1, 10   ; temp1 = 50
    sub temp2, temp1      ; temp2 = 6
    mov seconds, temp2    ; seconds = 6

minutes_skip:
    multiplyi seconds, 10 ; seconds = 60
    add seconds, keyPress ; seconds = 62

incrementKey_end:
    pop temp2
    pop temp1
    ret

; A button handler
switchToPowerStatus:
    cpi status, STATUS_ENTRY
    brne switchToPowerStatus_end
    ldi status, STATUS_POWER
    inc updateScr

switchToPowerStatus_end:
    jmp handleKeyPress_End

; B-D button handler
; Only called if STATUS_RUNNING
handleKeyPress_AddSubtract:
    cpi keyPress, 'B'
    breq handleKeyPress_AddSubtract_end

    cpi keyPress, 'C'
    breq addThirty

; D-key handler
subThirty:
    ; If seconds >= 30, overflow doesn't occur
    cpi seconds, 30
    brge skipTradeMinutes

    ; If minutes == 0, we cannot trade
    cpi minutes, 0
    brne tradeMinutesDec
    ldi seconds, 1
    clr tick       ; Indicate the end of a second
    jmp handleKeyPress_AddSubtract_end

tradeMinutesDec:
    dec minutes
    subi seconds, -60

skipTradeMinutes:
    subi seconds, 30
    jmp handleKeyPress_AddSubtract_end

addThirty:
    ; If minutes == 99, only do seconds
    cpi minutes, 99
    breq maxMinutes

    cpi seconds, 30
    ; If seconds < 30, trading doesn't occur
    brlt noTrading

tradeMinutesInc:
    subi seconds, 30 ; seconds -= 30
    inc minutes      ; minutes++

    jmp handleKeyPress_end

maxMinutes:
    cpi seconds, 70
    brsh force99
    subi seconds, -30
    jmp handleKeyPress_AddSubtract_end

force99:
    ldi seconds, 99
    jmp handleKeyPress_AddSubtract_end

noTrading:
    subi seconds, -30

handleKeyPress_AddSubtract_end:
    jmp handleKeyPress_End