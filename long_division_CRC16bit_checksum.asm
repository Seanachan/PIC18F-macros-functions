List p=18f4520
    #include <p18f4520.inc>
    #include "toolbelt.asm"
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF

    org 0x00
    cblock 0x10
        msg
        src
        outL
        outH
        cnt
    endc
    MOVLF d'24', cnt
    MOVLF 0xFE, msg
    MOVFF msg, src
;    Given 8-bit prime number X, 2<X<256
;    Find the smallest Y s.t. Y OR (Y+1) = X, store in 0x00
;    polynomial: 10001000000100001 (17bits)
;    INput: 11111110 0xFE
;_loop RLCF src
;    RLCF outL
;    RLCF outH
;    BTFSS STATUS, 0
;    GOTO _skip
;    MOVLW 0x21
;    XORWF outL, 1
;    MOVLW 0x10
;    XORWF outH, F
;_skip
;    DECFSZ cnt, F
;    GOTO _loop
    MOVLF 0x04, 0x00
    MOVLF 0x06, 0x01
    MOVLF 0x03, 0x02
    DIV16U8  0x00,0x01, 0x02, 0x03,0x04, 0x05, 0x06
    NOP
end
