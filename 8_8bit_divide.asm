;   /*Implement a calculator which allows 16-bit devidend and 8-bit divisor.
;   Store quotient in [0x020] for high byte, [0x21] for low byte, rem in [0x022]
;   */
; STATUS Carry(0), Digit Carry(1), Zero(2), Overflow(3), Negative(4)
   
; ============================================================
; 16-bit ÷ 8-bit unsigned division macro
; (divdH:divdL) ÷ divsor ? quotient (0x20:0x21), remainder (0x22)
; ============================================================
    




   ;0x0406 / 0x03
;   MOVLF 0xF0, 0x11
;   
;   MOVLF 0x03, 0x13
;   
;   div_8_8 0x11, 0x13, 0x00
   
   NOP