; ================ MATHS functions ======================
; Helper function
; r16 / r17 as input
; r16 as output
divide:
    push r17
    push r18
    push r19

    clr r18
    mov r19, r17

divide_while:         ; While r16 is greater than r17
    cp r16, r17
    brlo divide_end   ; Branch if r16 < r17
    inc r18
    add r17, r19
    brcs divide_end   ; Branch if positive overflow
    
    rjmp divide_while

divide_end:
    mov r16, r18

    pop r19
    pop r18
    pop r17
    ret