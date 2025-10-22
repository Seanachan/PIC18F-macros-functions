;=============================
; Usage
;=============================
;main:
; ====== Prepare three source lists ======
;  LFSR    0, 0x010
;  MOVLF   0x01, POSTINC0
;  MOVLF   0x04, POSTINC0
;  MOVLF   0x07, POSTINC0
;  MOVLF   0x02, POSTINC0
;  MOVLF   0x03, POSTINC0
;  MOVLF   0x09, POSTINC0
;  MOVLF   0x05, POSTINC0
;  MOVLF   0x06, POSTINC0
;  MOVLF   0x08, POSTINC0
;  
;  MOVLF 0xFF, 0x20
; ====== Sort merged data ======
;  MOVLW   0x09
;  MOVWF   len, ACCESS
;  MOVLW   0x10
;  MOVWF   baseL, ACCESS
;
;  RCALL   bubble_sort
;=============================  
    
    
    
;=============================
; VARIABLES
;=============================
    
 max EQU 0x30
 baseL EQU 0x31
 len EQU 0x32
 upr EQU 0x33
 j EQU 0x34
 temp EQU 0x35
 swapped EQU 0x36
 status_tmp EQU 0x37
 bsr_tmp EQU 0x38
 w_tmp EQU 0x39

bubble_sort:
    ; ---- Save context ----
    MOVFF   WREG, w_tmp
    MOVFF   STATUS, status_tmp
    MOVFF   BSR, bsr_tmp
    CLRF    BSR                 ; keep direct addressing consistent

    MOVLB 0x02
    ; ---- Trivial cases: len <= 1 ----
    MOVF    len, W, ACCESS
    BZ      bs_restore
    MOVF    len, W, ACCESS
    XORLW   0x01
    BZ      bs_restore

    ; upr = len - 1
    MOVF    len, W, ACCESS
    ADDLW   0xFF
    MOVWF   upr, ACCESS

bs_outer:
    CLRF    swapped, ACCESS

    ; FSR0 = baseL, FSR1 = baseL + 1
    CLRF    FSR0H, ACCESS
    MOVF    baseL, W, ACCESS
    MOVWF   FSR0L, ACCESS

    CLRF    FSR1H, ACCESS
    MOVF    baseL, W, ACCESS
    ADDLW   0x01
    MOVWF   FSR1L, ACCESS

    ; j = upr
    MOVF    upr, W, ACCESS
    MOVWF   j, ACCESS

bs_inner:
    ; if j == 0 ? this pass done
    MOVF    j, W, ACCESS
    BZ      bs_pass_done

    ; Compare adjacent: if *FSR1 < *FSR0 then swap
    MOVF    INDF0, W, ACCESS
    SUBWF   INDF1, W, ACCESS
    BTFSC   STATUS, C
    BRA     bs_no_swap

    ; swap(*FSR0, *FSR1)
    MOVF    INDF0, W, ACCESS
    MOVWF   temp, ACCESS
    MOVF    INDF1, W, ACCESS
    MOVWF   INDF0, ACCESS
    MOVF    temp, W, ACCESS
    MOVWF   INDF1, ACCESS
    MOVLW   0x01
    MOVWF   swapped, ACCESS

bs_no_swap:
    INCF    FSR0L, F, ACCESS
    INCF    FSR1L, F, ACCESS
    DECF    j, F, ACCESS
    BRA     bs_inner

bs_pass_done:
    ; if no swaps ? already sorted
    MOVF    swapped, W, ACCESS
    BZ      bs_restore

    ; shrink upr; if upr == 0 ? done
    DECF    upr, F, ACCESS
    MOVF    upr, W, ACCESS
    BNZ     bs_outer

bs_restore:
    ; ---- Restore context ----
    MOVFF   bsr_tmp, BSR
    MOVFF   status_tmp, STATUS
    MOVFF   w_tmp, WREG
    RETURN
