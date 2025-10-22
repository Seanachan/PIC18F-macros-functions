; ======= Equates =======
nL     EQU 0x20
nH     EQU 0x21
dL     EQU 0x22
dH     EQU 0x23
rL     EQU 0x24
rH     EQU 0x25
quoL   EQU 0x26
quoH   EQU 0x27
cnt    EQU 0x28
isPrime EQU 0x29
cnt_tmp EQU 0x2A

; DIV16U16_UNSIGNED MACRO dH,dL, vH,vL, quoH,quoL, rH,rL, cnt
;   dividend = dH:dL, divisor = vH:vL
;   quotient -> quoH:quoL, remainder -> rH:rL

; ======= PRIME TEST (simple brute-force) =======
; Input:  nH:nL  (unsigned 16-bit)
; Output: isPrime = 1 if prime, 0 otherwise
prime_test:
    CLRF    isPrime, ACCESS          ; assume not prime

    ; ----- handle 0 and 1 -----
    MOVF    nH, W, ACCESS
    IORWF   nL, W, ACCESS
    BZ      _ret                    ; n == 0
    MOVLW   0x01
    CPFSEQ  nL, ACCESS
    GOTO    _chk_two
    MOVF    nH, W, ACCESS
    BNZ     _chk_two
    GOTO    _ret                    ; n == 1

_chk_two:
    ; ----- handle 2 -----
    MOVF    nH, W, ACCESS
    BNZ     _even_chk
    MOVLW   0x02
    CPFSEQ  nL, ACCESS
    GOTO    _even_chk
    MOVLW   0x01
    MOVWF   isPrime, ACCESS
    GOTO    _ret

_even_chk:
    ; ----- even numbers > 2 ? not prime -----
    BTFSS   nL, 0, ACCESS
    GOTO    _ret                    ; even

    ; ----- test odd divisors -----
    MOVLW   0x03
    MOVWF   dL, ACCESS
    CLRF    dH, ACCESS

_loop:
    ; stop if d > n  ? prime
    MOVF    dH, W, ACCESS
    SUBWF   nH, W, ACCESS          ; W = nH - dH
    BTFSS   STATUS, C              ; if borrow ? nH < dH
    GOTO    _prime_done
    BNZ     _test_div              ; if nH > dH ? keep testing
    MOVF    dL, W, ACCESS
    SUBWF   nL, W, ACCESS          ; W = nL - dL
    BTFSS   STATUS, C              ; if borrow ? nL < dL
    GOTO    _prime_done


_test_div:
    ; r = n % d
    CLRF quoH
    CLRF quoL
    CLRF rH
    CLRF rL
    CLRF cnt

    DIV16U16_UNSIGNED  nH, nL,  dH, dL,  quoH, quoL,  rH, rL,  cnt

    ; if remainder == 0 ? divisible ? not prime
    MOVF    rL, W, ACCESS
    IORWF   rH, W, ACCESS
    BZ      _ret

    ; next odd divisor (d += 2)
    MOVLW   0x02
    ADDWF   dL, F, ACCESS
    BTFSC   STATUS, C
    INCF    dH, F, ACCESS
    GOTO    _loop

_prime_done:
    MOVLW   0x01
    MOVWF   isPrime, ACCESS
_ret:
    RETURN
