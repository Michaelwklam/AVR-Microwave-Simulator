;============== timer2 Interrupt handler =================
Timer2OVF_fastend: reti
Timer2OVF:
    cpi status, STATUS_RUNNING
    breq Timer2OVF_fastend
    cpi status, STATUS_POWER
    breq Timer2OVF_fastend

    push XL
    push XH
    push temp1

    ; Check if it should be disabled from
    ; 10 seconds inactive (idleCounter)
    rcall idleTurnOff

    ; Check if it should be fading (fadeMode)
    rcall fade

    pop temp1
    pop XH
    pop XL

    reti

idleTurnOff:
    loadDataCounter idleCounter

    cpi XL, low(IDLE_SEC)
    ldi temp1, high(IDLE_SEC)
    cpc XH, temp1

    breq turnOffScreen
    brsh idleTurnOff_end
    adiw XH:XL, 1
    storeDataCounter idleCounter

    rjmp idleTurnOff_end

turnOffScreen:
    ldi XL, FADE_OFF
    sts fadeMode, XL

idleTurnOff_end:
    ret

fade:
    lds XL, brightness
    lds temp1, fadeMode

    cpi temp1, 1
    brlt fade_end
    breq fade_in
    brge fade_out

fade_in:
    cpi XL, 247
    brsh fade_max
    subi XL, -8
    rjmp fade_write

fade_out:
    cpi XL, 8
    brlo fade_zero
    subi XL, 8
    rjmp fade_write

fade_max:
    clr temp1
    sts fadeMode, temp1
    ldi XL, 255
    rjmp fade_write

fade_zero:
    clr temp1
    sts fadeMode, temp1
    ldi XL, 0

fade_write:
    sts brightness, XL
    mov temp1, XL
    sts OCR3BL, temp1
    clr temp1
    sts OCR3BH, temp1

fade_end:
    ret