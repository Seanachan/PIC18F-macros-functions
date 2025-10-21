List p=18f4520
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
    org 0x00
;   /*Implement a calculator which allows 16-bit devidend and 8-bit divisor.
;   Store quotient in [0x020] for high byte, [0x21] for low byte, rem in [0x022]
;   */
; STATUS Carry(0), Digit Carry(1), Zero(2), Overflow(3), Negative(4)
   MOVLF macro val, dest
	MOVLW val
	movwf dest
    endm
; ============================================================
; 16-bit ÷ 8-bit unsigned division macro
; (divdH:divdL) ÷ divsor ? quotient (0x20:0x21), remainder (0x22)
; ============================================================
    

div MACRO divdH, divdL, divsor
    CLRF    0x20           ; quoH
    CLRF    0x22            ; remainder
    MOVLW   8
    MOVWF   0x26           ; counter

loop_high:
    RLCF    divdH, F
    RLCF    0x22, F

    MOVF    divsor, W
    SUBWF   0x22, W
    BTFSC   STATUS, 0
    GOTO    ge_high

    BCF     STATUS, 0
    RLCF    0x20, F
    GOTO    next_high

ge_high:
    MOVF    divsor, W
    SUBWF   0x22, F
    BSF     STATUS, 0
    RLCF    0x20, F

next_high:
    DECFSZ  0x26, F
    GOTO    loop_high

    CLRF    0x21           ; quoL
    MOVLW   8
    MOVWF   0x26

loop_low:
    RLCF    divdL, F
    RLCF    0x22, F

    MOVF    divsor, W
    SUBWF   0x22, W
    BTFSC   STATUS, 0
    GOTO    ge_low

    BCF     STATUS, 0
    RLCF    0x21, F
    GOTO    next_low

ge_low:
    MOVF    divsor, W
    SUBWF   0x22, F
    BSF     STATUS, 0
    RLCF    0x21, F

next_low:
    DECFSZ  0x26, F
    GOTO    loop_low
ENDM


   ;0x0406 / 0x03
   MOVLF 0x04, 0x10
   MOVLF 0x06, 0x11
   
   MOVLF 0x03, 0x13
   
   div 0x10, 0x11, 0x13
   
   NOP
    
end