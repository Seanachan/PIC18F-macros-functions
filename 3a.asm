List p=18f4520
    #include <p18f4520.inc>
    #include"fact_range32.asm"
;    #include"comb_rec"
    #include"movlf.asm"
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF

    org 0x00
    
    cblock 0x20
	upr
	lwr
    endc
    ADDFF macro f1, f2, dest
	movf f1, w
	ADDWF f2, w
	MOVWF dest
    endm
    
    swapff macro f1, f2
	MOVF f1, w
	MOVFF f2, f1
	MOVWF f2
    endm
    shift_logical macro f, n
	DECFSZ n
	GOTO shift
	GOTO finish
	
	shift:
    
	finish:
    endm
    
    MOVLF 0x93, 0x00
    MOVLF 0x4C, 0x01
    MOVLF 0x09, 0x02
    
    MOVLF 0x93, 0x00
    MOVFF 0x00, 0x01
    RLCF 0x01
    BCF 0x01, 0
    RLCF 0x01
    BCF 0x01, 0
    
    
    MOVFF 0x01, 0x02
    BTFSC 0x02, 7
    BSF 0x02, 7;set
    BTFSS 0x02, 7
    BCF 0x02, 7;clear
    
    RRCF 0x02
    BTFSC 0x02, 7
    BSF 0x02, 7;set
    BTFSS 0x02, 7
    BCF 0x02, 7;clear
    
    RRCF 0x02 
    BTFSC 0x02, 7
    BSF 0x02, 7;set
    BTFSS 0x02, 7
    BCF 0x02, 7;clear
    
    RRCF 0x02 
    BTFSC 0x02, 7
    BSF 0x02, 7;set
    BTFSS 0x02, 7
    BCF 0x02, 7;clear
    
    
    MOVFF 0x02, 0x03
    RLNCF 0x03
    RLNCF 0x03
    func macro src, dest
	MOVLW b'00001111'
	ANDWF src, w
	MOVWF lwr
	MOVLW b'11110000'
	ANDWF src, w
	MOVWF upr
	SWAPF upr

	MOVF upr, w
	MULWF lwr
	MOVFF PRODL, dest
    endm
    func 0x01, 0x11
    func 0x02, 0x12
    func 0x03, 0x13
    
    NOP
end


