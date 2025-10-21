List p=18f4520
    #include <p18f4520.inc>
    #include"fact_range32.asm"
;    #include"comb_rec"
    #include"movlf.asm"
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF

    swapff macro f1, f2
	MOVF f1, w
	MOVFF f2, f1
	MOVwf f2
    endm
    
    org 0x00
;    Gives an array from 0x300 to 0x309.
;    The task is to reverse the subarray.
;    Given head index =3, tail index =6, reverse the subarray
    
    MOVLB 3
    MOVLF 0x65, 0x300
    MOVLF 0x06, 0x301
    MOVLF 0x03, 0x302
    MOVLF 0xF7, 0x303
    MOVLF 0x04, 0x304
    MOVLF 0x0C, 0x305
    MOVLF 0x65, 0x306
    MOVLF 0x32, 0x307
    MOVLF 0x50, 0x308
    MOVLF 0x00, 0x309

    LFSR 0, 0x030
    LFSR 1, 0x030
    
    cblock 0x10
	head
	tail
	diff
    endc
   
    MOVLF 0x300, head
    MOVLF 0x300, tail
    
    MOVLW 7
    ADDWF FSR0L, 1
    MOVLW 7
    ADDWF FSR1L, 1
    
    start:
	MOVF FSR0L, w
	CPFSLT FSR1L
	GOTO cont
	
	GOTO finish
    cont:
	swapff POSTINC0, POSTDEC1
	GOTO start
    finish:
    
    
    NOP
end


