List p=18f4520
    #include <p18f4520.inc>
    #include "toolbelt.asm"
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
	org 0x00
	GOTO main
	cblock 0x10
	    n
	    prev
	    mid
	    next
	endc
	fib:
	    
    
	    MOVFF mid, next
	    MOVF prev, w
	    ADDWF next, 1
	    
	    MOVFF mid, prev
	    MOVFF next, mid
	    
	    DCFSNZ n
	    RETURN
	    GOTO fib
	main:
	    MOVLF d'4', n
	    MOVLF 0x01, prev
	    MOVLF 0x01, mid
	    MOVLF 0x01, next
	    
	    MOVLW 0x03
	    CPFSLT n
	    RCALL fib
	    
	    
	MOVFF next, 0x00
	
	to_gray:
	    MOVFF 0x00, 0x01
	    RRCF 0x01
	    MOVF 0x01, w
	    XORWF 0x00, 1 
    NOP
end
