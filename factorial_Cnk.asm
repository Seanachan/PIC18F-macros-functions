List p=18f4520
    #include <p18f4520.inc>
    #include"fact_range32.asm"
    #include"comb_rec"
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF

    org 0x00

; --- small helper ---
    MOVLF macro val, dest
        MOVLW   val
        MOVWF   dest
    endm

; --- 8/8 unsigned divide: (divd ÷ divsor) ? dest (quotient), 0x22 (remainder) ---
; uses: 0x26 as counter
    div_8_8 MACRO divd, divsor, dest
        LOCAL d8_loop, d8_ge, d8_next

        CLRF    0x22            ; rem
        CLRF    dest            ; quotient
        MOVLW   8
        MOVWF   0x26

d8_loop:
        RLCF    divd, F
        RLCF    0x22, F

        MOVF    divsor, W
        SUBWF   0x22, W
        BTFSC   STATUS, 0
        GOTO    d8_ge

        BCF     STATUS, 0
        RLCF    dest, F
        GOTO    d8_next

d8_ge:
        MOVF    divsor, W
        SUBWF   0x22, F
        BSF     STATUS, 0
        RLCF    dest, F

d8_next:
        DECFSZ  0x26, F
        GOTO    d8_loop
    ENDM

; --- factorial (8-bit, dest = n!) ---
; uses: 0x00=pro, 0x01=idx
    FACTF  macro n, f
        LOCAL f_loop, f_done
        MOVLF   0x01, 0x00      ; pro = 1
        MOVFF   n, 0x01         ; idx = n
f_loop:
        MOVF    0x01, W
        MULWF   0x00
        MOVFF   PRODL, 0x00
        DECFSZ  0x01, F
        GOTO    f_loop
f_done:
        MOVFF   0x00, f
    endm

; --- product from s..e (8-bit, modulo 256) ---
; uses: 0x01 as idx
    fact_range8 MACRO s, e, dest
        LOCAL fr8_loop, fr8_done
        MOVLW   0x01
        MOVWF   dest
        MOVFF   s, 0x01
fr8_loop:
        MOVF    0x01, W
        MULWF   dest
        MOVFF   PRODL, dest

        MOVF    e, W
        CPFSLT  0x01
        GOTO    fr8_done

        INCF    0x01, F
        GOTO    fr8_loop
fr8_done:
    ENDM

; --- C(n,k) with 8-bit arithmetic (mod 256) ---
; uses: 0x30 = n-k, 0x31 = numerator
    Cnk macro n, k, dest
        LOCAL do_swap, after_swap

        MOVF    k, W
        MOVFF   n, 0x30
        SUBWF   0x30, F         ; 0x30 = n - k

        MOVF    0x30, W
        CPFSLT  k               ; if (n-k) > k, swap so k = min(k, n-k)
        GOTO    do_swap
        GOTO    after_swap
do_swap:
        MOVFF   0x30, 0x33
        MOVFF   k,    0x30
        MOVFF   0x33, k
after_swap:

        MOVLW   0x01
        SUBWF   k, F            ; k = k-1  (so we multiply k..n)
        fact_range8 k, n, 0x31  ; numerator = product(k..n) -> 0x31

        FACTF   0x30, 0x30      ; denominator = (n-k)! -> 0x30

        div_8_8 0x31, 0x30, dest ; dest = numerator / denominator, rem in 0x22
    endm

; ---- test ----
    MOVLF 3, 0x08
    MOVLF 6, 0x09

;    Cnk 0x09, 0x08, 0x0A
;    fact_range8 0x08, 0x09, 0x05
    ; ??? 0x20..0x23 (???)
fact_range32 0x08, 0x09, 0x20, 0x21, 0x22, 0x23

;LFSR 2, 0x120
;   MOVLW 5
;   MOVWF 0x10
;   MOVLW 2
;   MOVWF 0x11
;   CALL COMB
;COMB_rec 
    NOP
end
