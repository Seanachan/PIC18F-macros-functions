; =========================================================
; comb.asm ? recursive C(n,r) for MPASM
; Inputs:
;   n  -> 0x20
;   r  -> 0x21
; Output:
;   resH:resL -> 0x23:0x22
; Uses:
;   FSR2 as software stack
; =========================================================

        ; --- Variables (must match caller memory layout) ---
        CBLOCK  0x20
n
r
resL
resH
tL
tH
        ENDC

; --- Recursive function COMB ---
COMB
        ; push n, r
        MOVF    n, W
        MOVWF   POSTINC2
        MOVF    r, W
        MOVWF   POSTINC2

        ; if (r > n) ? 0
        MOVF    r, W
        SUBWF   n, W
        BTFSC   STATUS, 0
        GOTO    cb_chk_base
        CLRF    resL
        CLRF    resH
        GOTO    cb_done

cb_chk_base
        ; if (r == 0)
        MOVF    r, W
        BTFSS   STATUS, 2
        GOTO    cb_chk_eq
        MOVLW   1
        MOVWF   resL
        CLRF    resH
        GOTO    cb_done

cb_chk_eq
        ; if (r == n)
        MOVF    n, W
        XORWF   r, W
        BTFSS   STATUS, 2
        GOTO    cb_recur
        MOVLW   1
        MOVWF   resL
        CLRF    resH
        GOTO    cb_done

cb_recur
        DECF    n, F
        DECF    r, F
        CALL    COMB

        ; push t1
        MOVF    resL, W
        MOVWF   POSTINC2
        MOVF    resH, W
        MOVWF   POSTINC2

        INCF    r, F
        CALL    COMB

        ; pop t1
        MOVF    PREDEC2, W
        MOVWF   tH
        MOVF    PREDEC2, W
        MOVWF   tL

        ; res = t1 + t2
        MOVF    resL, W
        ADDWF   tL, F
        MOVF    resH, W
        ADDWFC  tH, F
        MOVFF   tL, resL
        MOVFF   tH, resH

cb_done
        ; restore
        MOVF    PREDEC2, W
        MOVWF   r
        MOVF    PREDEC2, W
        MOVWF   n
        RETURN
