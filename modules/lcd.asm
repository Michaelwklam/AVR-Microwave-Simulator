; Variables used for LCD
.equ LCD_RS = 7
.equ LCD_E  = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

; Destroys temp1
setupLCD:
    ser temp1
    out DDRF, temp1
    out DDRA, temp1
    clr temp1
    out PORTF, temp1
    out PORTA, temp1

    do_lcd_commandi 0b00111000 ; 2x5x7
    rcall sleep_5ms
    do_lcd_commandi 0b00111000 ; 2x5x7
    rcall sleep_1ms
    do_lcd_commandi 0b00111000 ; 2x5x7
    do_lcd_commandi 0b00111000 ; 2x5x7
    do_lcd_commandi 0b00001000 ; display off?
    do_lcd_commandi 0b00000001 ; clear display
    do_lcd_commandi 0b00000110 ; increment, no display shift
    do_lcd_commandi 0b00001110 ; Cursor on, bar, no blink

    ret  

clearDisplay:
	do_lcd_commandi 0b00000001
	ret
	
; Outputs the message stored in data memory
; Input: Z pointer
output_message:
    push temp1
    push ZL
    push ZH

output_message_loop:
    lpm temp1, z+
    cpi temp1, '\0'
    breq output_message_after
    do_lcd_data temp1
    rjmp output_message_loop

output_message_after:
    pop ZH
    pop ZL
    pop temp1
    ret

; Outputs the time stored in minutes/seconds
output_time:
    push temp1

    ; If one is non-zero, print i
    mov temp1, seconds
    or temp1, minutes
    cpi temp1, 0
    brne output_time_digits
    
    ; Output blanks
    printMessage msg_blank
    jmp output_time_end

output_time_digits:
    do_lcd_num_2digit minutes
    do_lcd_datai ':'
    do_lcd_num_2digit seconds

output_time_end:
    pop temp1
    ret

;
; Send a command to the LCD (r16)
;

lcd_command:
    out PORTF, r16
    rcall sleep_1ms
    lcd_set LCD_E
    rcall sleep_1ms
    lcd_clr LCD_E
    rcall sleep_1ms
    ret

lcd_data:
    out PORTF, r16
    lcd_set LCD_RS
    rcall sleep_1ms
    lcd_set LCD_E
    rcall sleep_1ms
    lcd_clr LCD_E
    rcall sleep_1ms
    lcd_clr LCD_RS
    ret

lcd_wait:
    push r16
    clr r16
    out DDRF, r16
    out PORTF, r16
    lcd_set LCD_RW

lcd_wait_loop:
    rcall sleep_1ms
    lcd_set LCD_E
    rcall sleep_1ms
    in r16, PINF
    lcd_clr LCD_E
    sbrc r16, 7
    rjmp lcd_wait_loop
    lcd_clr LCD_RW
    ser r16
    out DDRF, r16
    pop r16
    ret

sleep_1ms:
    push r24
    push r25
    ldi r25, high(DELAY_1MS)
    ldi r24, low(DELAY_1MS)
delayloop_1ms:
    sbiw r25:r24, 1
    brne delayloop_1ms
    pop r25
    pop r24
    ret

sleep_5ms:
    rcall sleep_1ms
    rcall sleep_1ms
    rcall sleep_1ms
    rcall sleep_1ms
    rcall sleep_1ms
    ret
	