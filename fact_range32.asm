
	; 32-bit product (mod 2^32): Product := s * (s+1) * ... * e
; uses: idx=0x01, carr=0x34
; result in d0(low),d1,d2,d3(high)

MUL32x8 MACRO d0, d1, d2, d3, x
        MOVF    x, W
        MULWF   d0
        MOVFF   PRODL, d0
        MOVFF   PRODH, 0x34

        MOVF    x, W
        MULWF   d1
        MOVF    PRODL, W
        ADDWF   0x34, W
        MOVWF   d1
        MOVF    PRODH, W
        BTFSC   STATUS,0
        ADDLW   1
        MOVWF   0x34

        MOVF    x, W
        MULWF   d2
        MOVF    PRODL, W
        ADDWF   0x34, W
        MOVWF   d2
        MOVF    PRODH, W
        BTFSC   STATUS,0
        ADDLW   1
        MOVWF   0x34

        MOVF    x, W
        MULWF   d3
        MOVF    PRODL, W
        ADDWF   0x34, W
        MOVWF   d3
        ; high carry discarded (mod 32-bit)
    ENDM

fact_range32 MACRO s, e, d0, d1, d2, d3
    LOCAL fr32_loop, fr32_done
        CLRF    d0
        CLRF    d1
        CLRF    d2
        CLRF    d3
        MOVLW   1
        MOVWF   d0             ; P = 1

        MOVFF   s, 0x0C        ; idx = s
fr32_loop:
        MUL32x8 d0, d1, d2, d3, 0x0C

        MOVF    e, W
        CPFSLT  0x0C
        GOTO    fr32_done

        INCF    0x0C, F
        GOTO    fr32_loop
fr32_done:
    ENDM
    
;    fact_range32 0x08, 0x09, 0x20, 0x21, 0x22, 0x23

