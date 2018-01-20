; Variables used in polling
.equ PORTADIR = 0xF0 ; PD7-4: output, PD3-0, input
.equ INITCOLMASK = 0xEF ; scan from the rightmost column,
.equ INITROWMASK = 0x01 ; scan from the top row
.equ ROWMASK = 0x0F ; for obtaining input from Port D

setupKeypad:
    ldi temp1, PORTADIR ; PA7:4/PA3:0, out/in
    sts DDRL, temp1
    ser temp1 ; PORTC is output
    out DDRC, temp1
    ret

pollForInput:
    ldi temp1, INITCOLMASK
    mov cmask, temp1 ; initial column mask
    clr col ; initial column

colloop:
    cpi col, 4
    breq pollForInput_break ; If all keys are scanned, repeat.
    sts PORTL, cmask ; Otherwise, scan a column.
    ldi temp1, 0xFF ; Slow down the scan operation.
    jmp delay

pollForInput_break:
    jmp pollForInput_end

delay: 
    dec temp1
    brne delay
    lds temp1, PINL ; Read PINL
    andi temp1, ROWMASK ; Get the keypad output value
    cpi temp1, 0xF ; Check if any row is low
    breq nextcol
    ; If yes, find which row is low
    push temp1
    ldi temp1, INITROWMASK
    mov rmask, temp1 ; Initialize for row check
    pop temp1
    clr row 

rowloop:
    cpi row, 4
    breq nextcol ; the row scan is over.
    mov temp2, temp1
    and temp2, rmask ; check un-masked bit
    breq check_debounce ; if bit is clear, the key is pressed
    inc row ; else move to the next row
    lsl rmask
    jmp rowloop

nextcol: ; if row scan is over
    lsl cmask
    inc col ; increase column value
    jmp colloop ; go to the next column

check_debounce:
    tst debounce ; If debounce is 0
    brne pollForInput_end

    inc debounce        ; start debounce    
    clear debounceCounter
    mov lastrMask, rmask
    mov lastcMask, cmask

    cpi col, 3 ; If the pressed key is in col.3
    breq letters ; we have a letter
    ; If the key is not in col.3 and
    cpi row, 3 ; If the key is in row3,
    breq symbols ; we have a symbol or 0
    mov keyPress, row
    lsl keyPress
    add keyPress, row
    add keyPress, col ; keyPress = row*3 + col
    inc keyPress
    
    jmp pollForInput_end

letters:
    ldi keyPress, 'A'
    add keyPress, row
    rjmp pollForInput_end
    
symbols:
    cpi col, 0 ; Check if we have a star
    breq star
    cpi col, 1 ; or if we have zero
    breq zero
    ldi keyPress, '#' ; if not we have hash
    rjmp pollForInput_end

star:
    ldi keyPress, '*' ; Set to star
    rjmp pollForInput_end

zero:
    ldi keyPress, 0 ; Set to zero
    jmp pollForInput_end

pollForInput_end:
    ret