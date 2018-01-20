; =================== BUTTON INTERRUPTS   ================
EXT_INT0:
b0_preserve:
    push temp1
    in temp1, SREG ; save SREG
    push temp1
    push temp2

b0_checkdebounce:
    tst doorDeb ; If > 0, skip
    brne b0_debounce

b0_handlepress:
    inc closeBtn
    inc doorDeb
    clear doorCounter

b0_debounce:
    pop temp2
    pop temp1
    out SREG, temp1
    pop temp1
    reti

EXT_INT1:
b1_preserve:
    push temp1
    in temp1, SREG ; save SREG
    push temp1
    push temp2

b1_checkdebounce:
    tst doorDeb ; If > 0, skip
    brne b1_debounce

b1_handlepress:
    inc openBtn
    inc doorDeb
    clear doorCounter

b1_debounce:
    pop temp2
    pop temp1
    out SREG, temp1
    pop temp1
    reti