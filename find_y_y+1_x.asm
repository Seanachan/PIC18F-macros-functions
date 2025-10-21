List p=18f4520
    #include <p18f4520.inc>
    #include "toolbelt.asm"
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF

    org 0x00
    cblock 0x10
	i	
	x
	y
	y_1
	tmp
    endc
;    Given 8-bit prime number X, 2<X<256
;    Find the smallest Y s.t. Y OR (Y+1) = X, store in 0x00

    MOVLF 0x05, x
    MOVLF 0x01, i
    
    GOTO main
    
    check:
	MOVFF y, y_1
	INCF y_1
	MOVF y, w
	IORWF y_1, w
	CPFSEQ x
	GOTO skip
	
	MOVFF y, tmp
	skip:
	INCF y
	RETURN
    
    main:
    FOR8_REG_IND i, x, check
    
    MOVFF tmp, 0x00
    NOP
end





