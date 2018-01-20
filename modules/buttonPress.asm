; Called from main
handleButtonPress:
    tst closeBtn
    brne handleCloseBtn
    tst openBtn
    brne handleOpenBtn

handleButtonPress_end:
    ret

handleCloseBtn:
    clr open     ; Set open = FALSE
    clr closeBtn
    disablePin PORT_OPEN, PIN_OPEN
    rjmp handleButtonPress_end

handleOpenBtn:
    clr open    ; Set open = TRUE
    inc open
    clr openBtn
    cpi status, STATUS_RUNNING
    breq pauseMicrowave
    enablePin PORT_OPEN, PIN_OPEN
    rjmp handleButtonPress_end

pauseMicrowave:
    ldi status, STATUS_PAUSED
    rjmp handleButtonPress_end 