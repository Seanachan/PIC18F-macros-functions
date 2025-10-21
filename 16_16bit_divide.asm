; 16-bit ÷ 16-bit unsigned division
; (divdH:divdL) ÷ (dvsH:dvsL) ? quotient (0x20:0x21), remainder (0x23:0x22)

div16 MACRO divdH, divdL, dvsH, dvsL
    LOCAL lh, ge_h, nx_h, ll, ge_l, nx_l

    CLRF    0x20            ; quoH
    CLRF    0x21            ; quoL
    CLRF    0x22            ; remL
    CLRF    0x23            ; remH

    ; ----- high byte (8 bits) -----
    MOVLW   8
    MOVWF   0x26
lh:
    RLCF    divdH, F
    RLCF    0x22,  F
    RLCF    0x23,  F

    MOVF    dvsL, W
    SUBWF   0x22, F
    MOVF    dvsH, W
    SUBWFB  0x23, F
    BTFSC   STATUS, 0
    GOTO    ge_h

    ; borrow ? restore remainder, shift in 0
    MOVF    dvsL, W
    ADDWF   0x22, F
    MOVF    dvsH, W
    ADDWFC  0x23, F
    BCF     STATUS, 0
    RLCF    0x21, F
    RLCF    0x20, F
    GOTO    nx_h

ge_h:
    ; no borrow ? keep subtraction, shift in 1
    BSF     STATUS, 0
    RLCF    0x21, F
    RLCF    0x20, F
nx_h:
    DECFSZ  0x26, F
    GOTO    lh

    ; ----- low byte (8 bits) -----
    MOVLW   8
    MOVWF   0x26
ll:
    RLCF    divdL, F
    RLCF    0x22,  F
    RLCF    0x23,  F

    MOVF    dvsL, W
    SUBWF   0x22, F
    MOVF    dvsH, W
    SUBWFB  0x23, F
    BTFSC   STATUS, 0
    GOTO    ge_l

    MOVF    dvsL, W
    ADDWF   0x22, F
    MOVF    dvsH, W
    ADDWFC  0x23, F
    BCF     STATUS, 0
    RLCF    0x21, F
    RLCF    0x20, F
    GOTO    nx_l

ge_l:
    BSF     STATUS, 0
    RLCF    0x21, F
    RLCF    0x20, F
nx_l:
    DECFSZ  0x26, F
    GOTO    ll
ENDM
