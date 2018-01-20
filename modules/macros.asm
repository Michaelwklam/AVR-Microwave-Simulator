; Input: @0 = data counter,
; returns it in XL
.macro loadDataCounter
    lds XL, @0 
    lds XH, @0+1 
.endmacro

; Stores data in X register @0
.macro storeDataCounter
    sts @0, XL
    sts @0+1, XH
.endmacro

.macro storeDataCounteri
    ldi XL, low(@1)
    ldi XH, high(@1)
    storeDataCounter @0
.endmacro


; Returns the character at a cseg
; input: @0 = end register, @1 = data, @2 = index
; zero-indexed
.macro getCharAt
    push ZL
    push ZH
    ldi ZL, low (@1 << 1)
    ldi ZH, high(@1 << 1)
    ldi temp1, 0
    add ZL, @2
    adc ZH, temp1
    lpm @0, z
    pop ZH
    pop ZL
.endmacro

; @0 = PORTX, @1 = PIN_CONST
.macro disablePin
    in temp1, @0
    ldi temp2, 0b11111111
    subi temp2, @1
    and temp1, temp2
    out @0, temp1
.endmacro

.macro enablePin
    in temp1, @0
    ldi temp2, @1
    or temp1, temp2
    out @0, temp1
.endmacro

.macro changeTurnDirection
	ldi temp1, 0b00000001
	eor clockwise, temp1
.endmacro

.macro resetKey
    ldi keyPress, KEY_FALSE
.endmacro

.macro clear
    push YL
    push YH
    ldi YL, low(@0)
    ldi YH, high(@0)
    clr temp1
    st Y+, temp1
    st Y, temp1
    pop YH
    pop YL
.endmacro

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4

; ==================== LCD Macros ====================
.macro do_lcd_commandi
    push r16
    ldi r16, @0
    rcall lcd_command
    rcall lcd_wait
    pop r16
.endmacro

.macro do_lcd_data
    push r16
    mov r16, @0
    rcall lcd_data
    rcall lcd_wait
    pop r16
.endmacro

.macro do_lcd_datai
    push r16
    ldi r16, @0
    rcall lcd_data
    rcall lcd_wait
    pop r16
.endmacro

; Takes @0 as REGISTER
.macro do_lcd_num
    push r16
    mov r16, @0
    subi r16, -'0'
    rcall lcd_data
    rcall lcd_wait
    pop r16
.endmacro

; Takes @0 as IMMEDIATE
.macro do_lcd_numi
    push r16
    ldi r16, @0
    subi r16, -'0'
    rcall lcd_data
    rcall lcd_wait
    pop r16
.endmacro

.macro do_lcd_num_2digit
    push temp1
    push temp2
    mov temp1, @0
    mov temp2, temp1
    dividei temp1, 10
    ; temp1 = tens digit
    do_lcd_num temp1

    ; x = x - 10 * floor(x/10)
    multiplyi temp1, 10
    sub temp2, temp1
    do_lcd_num temp2
    pop temp2
    pop temp1
.endmacro

.macro lcd_set
    sbi PORTA, @0
.endmacro
.macro lcd_clr
    cbi PORTA, @0
.endmacro

.macro printMessage
    push ZL
    push ZH
    ldi ZL, low (@0 << 1)
    ldi ZH, high(@0 << 1)
    rcall output_message
    pop ZH
    pop ZL
.endmacro


; ==================== Maths macros ====================
.macro multiplyi
    push r16
    push r1
    push r0
    ldi r16, @1
    mul @0, r16
    mov @0, r0
    pop r0
    pop r1
    pop r16
.endmacro

.macro dividei
    push r16
    push r17
    mov r16, @0
    ldi r17, @1
    rcall divide
    mov @0, r16
    pop r17
    pop r16
.endmacro