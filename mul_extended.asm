;;=================================
;    Usage: 
;; main:
;    MOVLF 0x4F ,0x10 ;nL
;    MOVLF 0x00, 0x11 ;nH
;    MOVLF 0xE5, 0x12 ;mL
;    MOVLF 0x03, 0x13 ;mH
;
;    RCALL mul_extended
;;=================================

mul_extended:
    nL EQU 0x10
    nH EQU 0x11
    mL EQU 0x12
    mH EQU 0x13
    dest1 EQU 0x001
    dest2 EQU 0x002
    dest3 EQU 0x003
    dest4 EQU 0x004
    ; MOVFF 0x001, nL ;nL
    ; MOVFF 0x002, nH ;nH
    ; MOVFF 0x003, mL ;mL
    ; MOVFF 0x004, mH ;mH
    ; n * m
    ;; nH(0x11), nL(0x10)
    ;; mH(0x13), mL(0x12)
    ;;out:   Large -->  Small
    ;;out: 0x004 0x003 0x002 0x001
    CLRF dest1
    CLRF dest2
    CLRF dest3
    CLRF dest4
    nL_mL:
	MOVF nL, w
	MULWF mL
	
	MOVF PRODL, W
	ADDWF dest1, 1
	MOVF PRODH, W
	ADDWF dest2, 1
    nH_mL:
	MOVF nH, w
	MULWF mL
	
	MOVF PRODL, W
	ADDWF dest2, 1
	MOVF PRODH, W
	ADDWFC dest3, 1
    nL_mH:
	MOVF nL, w
	MULWF mH
	
	MOVF PRODL, W
	ADDWF dest2, 1
	MOVF PRODH, W
	ADDWFC dest3, 1
    nH_mH:
	MOVF nH, w
	MULWF mH
	
	MOVF PRODL, W
	ADDWF dest3, 1
	MOVF PRODH, W
	ADDWFC dest4, 1

    STEP2:
	; if op1(nH(0x11), nL(0x10)) is negative, subtrasct op2 from upper byte
	BTFSS nH, 7 ;is nH is negative
	GOTO STEP3
	
	;upper byte = 0x04, 0x03
	MOVF mL, w
	SUBWF dest3
	MOVF mH, w
	SUBWFB dest4
	
    STEP3:
	; if op2(mH(0x13), mL(0x12)) is negative, subtrasct op1 from upper byte
	BTFSS mH, 7 ;mH is negative
	GOTO finish
	
	MOVF nL, w
	SUBWF dest3
	MOVF nH, w
	SUBWFB dest4
	
    finish: