    LIST p=18f4520
    #include <p18f4520.inc>
    CONFIG OSC = INTIO67
    CONFIG WDT = OFF

    org 0x00
;=============================
; VARIABLES
;=============================
    cblock 0x30
        n           ; upper limit
        i           ; loop counter
        val         ; generic temp / result
        tmp1
        tmp2
        idx         ; argument for recursive lookup
        w_tmp
        status_tmp
        bsr_tmp
    endc

;=============================
; MAIN ENTRY
;=============================
    GOTO main

;------------------------------------------------------------
; build_list
;------------------------------------------------------------
; builds F(0)~F(n) bottom-up into addresses 0x00..0x0n
;------------------------------------------------------------
build_list:
    LFSR 0, 0x00          ; FSR0 points to destination table base
    CLRF i                ; i=0

    CLRF INDF0            ; F(0)=0
    INCF FSR0L, F
    MOVLW 0x01
    MOVWF INDF0           ; F(1)=1
    INCF FSR0L, F
    MOVLW 0x02
    MOVWF i               ; i=2 now points to next term

build_loop:
    MOVF i, W
    CPFSGT n
    BRA build_done        ; if i>n, stop

    ; tmp1 = F(i-1)
    MOVF i, W
    ADDLW 0xFF
    MOVWF tmp1
    LFSR 1, 0x00
    MOVF tmp1, W
    ADDWF FSR1L, F
    MOVF INDF1, W
    MOVWF tmp1

    ; tmp2 = F(i-2)
    MOVF i, W
    ADDLW 0xFE
    MOVWF tmp2
    LFSR 1, 0x00
    MOVF tmp2, W
    ADDWF FSR1L, F
    MOVF INDF1, W
    MOVWF tmp2

    ; val = tmp1 + tmp2
    MOVF tmp1, W
    ADDWF tmp2, W
    MOVWF val

    ; store val at address (0x00 + i)
    LFSR 1, 0x00
    MOVF i, W
    ADDWF FSR1L, F
    MOVFF val, INDF1

    INCF i, F
    BRA build_loop

build_done:
    RETURN

;------------------------------------------------------------
; lookup
;------------------------------------------------------------
; Recursive lookup from the built list
; Input : idx
; Output: val
;------------------------------------------------------------
lookup:
    MOVFF WREG, w_tmp
    MOVFF STATUS, status_tmp
    MOVFF BSR, bsr_tmp

    ; base case
    MOVF idx, W
    BZ lookup_base

    MOVLW 0x00
    CPFSGT idx
    BRA lookup_fetch

lookup_base:
    CLRF val
    BRA lookup_end

lookup_fetch:
    LFSR 0, 0x00
    MOVF idx, W
    ADDWF FSR0L, F
    MOVF INDF0, W
    MOVWF val

lookup_end:
    MOVFF bsr_tmp, BSR
    MOVFF status_tmp, STATUS
    MOVFF w_tmp, WREG
    RETURN

;------------------------------------------------------------
; MAIN PROGRAM
;------------------------------------------------------------
main:
    MOVLW d'13'          ; build up to F(8)
    MOVWF n

    RCALL build_list

    ; Demonstrate recursive lookup of F(5)
    MOVLW 0x05
    MOVWF idx
    RCALL lookup         ; returns F(5) in val

    SLEEP
    END
