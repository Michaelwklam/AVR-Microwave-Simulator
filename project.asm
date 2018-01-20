; Microwave Project
; COMP2121 2016s2
; Group C10

.include "m2560def.inc"

; Status numbers
.equ STATUS_ENTRY    = 0 ; Entry mode (default)
.equ STATUS_RUNNING  = 1 ; Running mode
.equ STATUS_PAUSED   = 2 ; Paused mode
.equ STATUS_FINISHED = 3 ; Finished mode
.equ STATUS_POWER    = 4 ; Power-changing mode

; Since 0-9 are being used as
; literal numbers
.equ KEY_FALSE    = 99

; Charcode for top LED, magnetron
; and speaker (on PORTB)
.equ PIN_SPEAKER  = 0b00000001
.equ PIN_MAG      = 0b00001000
.equ PIN_OPEN     = 0b00000100
.equ PORT_SPEAKER = PORTB
.equ PORT_MAG     = PORTB
.equ PORT_OPEN    = PORTB

; Backlight pin (PORTE)
.equ PIN_BL       = 0b00001000
.equ PORT_BL      = PORTE

; Opened/closed characters
.equ OPEN_MSG =   'O'
.equ CLOSED_MSG = 'C'

.equ FADE_DISABLED = 0
.equ FADE_ON       = 1
.equ FADE_OFF      = 2

; Counter constants (Timer0, 8 prescalar)
.equ ONE_SEC      = 7812
.equ DB_SEC       = 400        ; Debounce counter (keypad, 50ms)
.equ SEC_SEC      = ONE_SEC    ; Second counter (1s)
.equ DOOR_SEC     = 1173       ; Open/close counter (buttons, 200ms)
.equ TURN_SEC     = 18750      ; Tuntable counter (2.4 sec / move)
.equ MAG_2        = ONE_SEC/2  ; Power lvl 2, (500 ms)
.equ MAG_3        = ONE_SEC/4  ; Power lvl 3, (250 ms)
.equ FINSOUND_SEC = ONE_SEC    ; Finished sound counter (1s)
.equ KEY_SEC      = ONE_SEC/5  ; 200ms

; Counter constants (Timer2, 1024 prescalar)
.equ IDLE_SEC     = 610 ; 10 seconds

; G = Global variable, used in interrupts
.def updateScr = r0  ; Used to update the screen
.def open      = r1  ; Microwave open/closed
.def cmask     = r2  ; Used for polling
.def rmask     = r3  ;
.def lastrMask = r4  ; Used for polling debounce (G)
.def lastcMask = r5  ;
.def clockwise = r6  ; Direction of turntable
.def openBtn   = r7  ; Open button push flag (G)
.def closeBtn  = r8  ; Close button push flag (G)
.def debounce  = r9  ; Timer/debounce counters (G)
.def tick      = r10 ; - 1 means ignore
.def doorDeb   = r11 ; - 0 means ready
.def turnState = r12 ; Index of turntable state
.def magTime_L = r13 ; Address of magnetron timer (G)
.def magTime_H = r14
.def finSound  = r15 ; Finish sound flag (G)

.def power     = r16 ; Power state
.def keyPress  = r17 ; Last key pressed
.def col       = r18 ; Also used for polling
.def row       = r19
.def minutes   = r20 ; Minutes/seconds
.def seconds   = r21
.def status    = r22 ; Status (G)

.def temp1     = r24 ; Temporary registers
.def temp2     = r25
; Note that XL is r26

; Below this line, macros.asm will be substituted
; <macros>

; Data variables
.dseg 
    debounceCounter  : .byte 2 ; keypad debounce
    secondsCounter   : .byte 2 ; For each second
    doorCounter      : .byte 2 ; Open/close buttons
    turnCounter      : .byte 2 ; Turntable period
    magnetronCounter : .byte 2 ; Magnetron counter
    finSoundCounter  : .byte 2 ; Finishing sound (1s)
    idleCounter      : .byte 2 ; Backlight timeout (10s)
    fadeMode         : .byte 2 ; Fade mode (FADE_ON, FADE_OFF, FADE_DISABLED)
    brightness       : .byte 2 ; Backlight brightness
    speakerCounter   : .byte 2 ; Speaker frequency
    keySoundCounter  : .byte 2 ; Key sound

; ==================Interrupt Vectors Setup=========================
.cseg
.org 0x0000
    jmp RESET
.org INT0addr
    jmp EXT_INT0        ; button 0 handler
.org INT1addr
    jmp EXT_INT1        ; button 1 handler
.org OVF2addr
    jmp Timer2OVF
    jmp DEFAULT
.org OVF0addr
    jmp Timer0OVF       ; Jump to the interrupt handler for timer0 overflow
    jmp DEFAULT         ; default service for all other interrupts

DEFAULT: reti           ; ignore, no servicing

; Strings
    msg_group:   .db "C10"        , '\0'
    msg_done:    .db "Done"       , '\0', '\0'
    msg_remove:  .db "Remove food", '\0'
    msg_blank:   .db "     ", '\0'
    msg_power:   .db "Set Power 1/2/3", '\0'
    powerStates: .db 0xFF, 0x0F, 0x03, '\0'
    rotate:      .db "-`|/"

; ================== LCD functions ======================
RESET:
    ; Set debounceCounter to 0
    clear secondsCounter
    clear turnCounter
    clear magnetronCounter
    clear idleCounter
    clear fadeMode
    ldi temp1, 255
    sts brightness, temp1
    storeDataCounteri keySoundCounter, KEY_SEC + 1
    storeDataCounteri debounceCounter, DB_SEC  + 1

    ser temp1
    out DDRB, temp1
    sts DDRH, temp1

    ; Default variable values
    ldi status, STATUS_ENTRY
    inc updateScr
    clr open      ; Microwave is closed
    clr minutes
    clr seconds
    clr openBtn
    clr closeBtn
    resetKey
    clr clockwise
    clr debounce  ; Debounce flags
    clr tick
    clr doorDeb
    clr turnState
    clr finSound

    ; Set initial power
    ; Zero-indexed, hence decrement
    ldi power, 1
    dec power
    getCharAt temp1, powerStates, power
    out PORTC, temp1
    inc power

    ; Set initial magnetron
    rcall setMag_3
    
    ; setup interrupts
    ldi temp1, (2 << ISC00)|(2 << ISC10) ; set INT0,1 as falling
    sts EICRA, temp1 ; edge triggered interrupt

    in temp1, EIMSK ; enable INT0 and INT1
    ori temp1, (1<<INT0)|(1<<INT1)
    out EIMSK, temp1

    ; Setup stack
    ldi temp1, low(RAMEND)
    out SPL, temp1
    ldi temp1, high(RAMEND)
    out SPH, temp1

    ; Setup LCD
    rcall setupLCD

    ; Update the display
    rcall updateDisplay

    ; Setup timer
    ldi temp1, 0b00000000   ; Set timer0
    out TCCR0A, temp1
    ldi temp1, 0b00000010
    out TCCR0B, temp1       ; Prescaling value=8
    ldi temp1, 1<<TOIE0     ; = 128 microseconds
    sts TIMSK0, temp1       ; T/C0 interrupt enable

    ; Setup timer2
    ldi temp1, 0b00000000   ; Set timer2
    sts TCCR2A, temp1
    ldi temp1, 0b00000111
    sts TCCR2B, temp1       ; Prescaling value=1024
    ldi temp1, 1<<TOIE2     ; = 16394 microseconds
    sts TIMSK2, temp1       ; T/C2 interrupt enable

    ; setup PWM
    ldi temp1, 0b00010000        ; set PE3 (OC3B) to output
    out DDRE, temp1

    ldi temp1, 255               ; connected to PE2
    sts OCR3BL, temp1
    clr temp1
    sts OCR3BH, temp1

    ldi temp1, (1 << CS30)       ; set the Timer3 to Phase Correct PWM mode. 
    sts TCCR3B, temp1
    ldi temp1, (1 << WGM31)|(1<< WGM30)|(1<<COM3B1)|(1<<COM3A1)
    sts TCCR3A, temp1

    ; SETUP keypad
    rcall setupKeypad

    sei                     ; Enable global interrupt
main:
    ; Polls keypad for input (keypad)
    rcall pollForInput

    ; Handles the keypress (keypress, if any)
    rcall handleKeyPress

    ; Handles open/close press (buttonPress)
    call handleButtonPress

    ; Checks if a second is reached
    ; (when in running mode)
    rcall secondReached

    ; Checks the magnetron (magnetron)
    rcall checkmagnetron

    ; Updates the display
    rcall updateDisplay

    rjmp main

secondReached_fastReturn: ret
secondReached:
    cpi status, STATUS_RUNNING
    brne secondReached_fastReturn
    tst tick
    brne secondReached_fastReturn ; if tick==1, do nothing

    cpi seconds, 0
    breq secondReached_mins
    dec seconds
    mov temp1, seconds
    add temp1, minutes
    cpi temp1, 0
    breq secondReached_done
    rjmp secondReached_end

secondReached_mins:
    dec minutes
    ldi seconds, 59
    rjmp secondReached_end

secondReached_done:
    ldi status, STATUS_FINISHED
    inc finSound
    inc updateScr
    clear finSoundCounter
    
secondReached_end:
    clear secondsCounter
    inc tick
    ret

; =================== UPDATES THE DISPLAY ================
updateDisplay:
    tst updateScr
    breq updateDisplay_skipClear
    do_lcd_commandi 0b00000001 ; clear display

updateDisplay_skipClear:
    ; Second line
    rcall updateDisplay_common

    ; Top line
    do_lcd_commandi 0b10000000
    cpi status, STATUS_FINISHED
    breq updateDisplay_finished
    cpi status, STATUS_POWER
    breq updateDisplay_power

; The method for RUNNING, READY and PAUSED
updateDisplay_default:
    ; Print the time in the first line
    call output_time

    ; Add group name bottom-left
    do_lcd_commandi 0b11000000 ; move to second line
    printMessage msg_group
    rjmp updateDisplay_end

updateDisplay_finished:
    printMessage msg_done
    
    do_lcd_commandi 0b11000000 ; move to second line
    printMessage msg_remove
    rjmp updateDisplay_end

updateDisplay_power:
    printMessage msg_power

    do_lcd_commandi 0b11000000 ; move to second line
    printMessage msg_group

updateDisplay_end:
    clr updateScr
    ret

; COMMON
updateDisplay_common:
    ; Turntable handler
    do_lcd_commandi 0b10001111
    
    ; display turn table state special case for [1]
    getCharAt temp1, rotate, turnState
    do_lcd_data temp1

turnState_checked:
    ; Print open/closed on bottom-right
    do_lcd_commandi 0b11001111

    ; If open == 0, it is closed
    tst open
    breq closedHandle

openHandle:
    ; Bottom right
    do_lcd_datai OPEN_MSG
    rjmp openHandle_after   

closedHandle:
    do_lcd_datai CLOSED_MSG
    rjmp openHandle_after

openHandle_after:
    ret

finishedSound:
    tst finSound ; if finSound == 0, do nothing
    breq finishedSound_end

    mov temp1, finSound
    andi temp1, 0b00000001
    
    cpi temp1, 1
    breq turnOn  ; If odd, turn on

    ; Turn off
    ldi temp1, PIN_SPEAKER
    out PORT_SPEAKER, temp1
    jmp finishedSound_end

turnOn:
    ldi temp1, PIN_SPEAKER
    sts PORT_SPEAKER, temp1
    jmp finishedSound_end    

finishedSound_end:
    ret
