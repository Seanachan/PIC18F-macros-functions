List p=18f4520
    #include <p18f4520.inc>
    #include"fact_range32.asm"
;    #include"comb_rec"
    #include"movlf.asm"
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF

    org 0x00
    
    cblock 0x10
	cur
	prev
	nxt
	a
	b
	c
	d
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
    
    
    ;lexicographic permutation
    MOVLF 0x12, 0x00
    MOVLF 0x34, 0x01
    
    MOVLW b'00001111'
    ANDWF 0x00, w
    MOVWF b
    MOVLW b'00001111'
    ANDWF 0x01, w
    MOVWF d
    MOVLW b'11110000'
    ANDWF 0x00, w
    MOVWF a
    
    MOVLW b'11110000'
    ANDWF 0x01, w
    MOVWF c
    swapf a
    swapf c
    
    first:
	MOVF d, w
	CPFSLT c
	GOTO second
	
	swapff c, d
	GOTO finish
    second:
	MOVF c, w
	CPFSLT b
	GOTO third
	
	swapff b,c
	
	MOVF d, w
	CPFSLT c
	swapff c, d
	GOTO finish
    third:
	MOVF b, w
	CPFSLT a
	GOTO finish
	
	swapff a,b
	
	MOVF c, w
	CPFSLT b
	swapff b, c
	
	MOVF d, w
	CPFSLT c
	swapff c, d
	
	MOVF c, w
	CPFSLT b
	swapff b, c
	GOTO finish
    finish:
	
	
    CLRF 0x00
    CLRF 0x01
    MOVF a, w
    ADDWF 0x00
    SWAPF 0x00
    
    MOVF b, w
    addwf 0x00
    
    MOVF c, w
    ADDWF 0x01
    SWAPF 0x01
    
    MOVF d, w
    addwf 0x01
    
    NOP
end


