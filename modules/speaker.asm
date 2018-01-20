; Called from timer0
enableSpeaker:
    loadDataCounter speakerCounter
    adiw XH:XL, 1
    storeDataCounter speakerCounter

    ldi temp1, 4 ; 7812 / 5 = 1572Hz
    and XL, temp1
    cpi XL, 0
    breq enableSpeaker_end

    ; Check if fin sound is needed
    tst finSound
    breq skipFinSound
    mov temp1, finSound
    andi temp1, 1
    cpi temp1, 1
    brne skipFinSound
    enablePin PORT_SPEAKER, PIN_SPEAKER

skipFinSound:
    ; Check if key sound is needed
    loadDataCounter keySoundCounter
    adiw XH:XL, 1

    ; If keySoundCounter + 1 >= KEY_SEC + 1, don't enable
    cpi XL, low(KEY_SEC+1)
    ldi temp1, high(KEY_SEC+1)
    cpc XH, temp1
    brsh enableSpeaker_end

    enablePin PORT_SPEAKER, PIN_SPEAKER
    storeDataCounter keySoundCounter

enableSpeaker_end:
    ret