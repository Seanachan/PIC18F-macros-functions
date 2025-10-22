; ===================== toolbelt.inc (MPASM) =====================

; --- tiny helpers ---
MOVLF    MACRO val, dest       ; dest = literal
        MOVLW   val
        MOVWF   dest, ACCESS
        ENDM
SETBIT   MACRO f,b             ; f.b = 1
        BSF     f,b
        ENDM
CLRBIT   MACRO f,b             ; f.b = 0
        BCF     f,b
        ENDM
XCHG     MACRO a,b             ; swap a<->b (uses WREG)
        MOVF    a,W
        XORWF   b,F
        XORWF   a,F
        XORWF   b,F
        ENDM

; --- 16-bit add/sub/cmp (dest += src, etc.) ---
ADD16    MACRO dL,dH,sL,sH
        MOVF    sL,W
        ADDWF   dL,F
        MOVF    sH,W
        ADDWFC  dH,F
        ENDM

ADD16_TO MACRO aL,aH, bL,bH, rL,rH
        ; rL = aL + bL
        MOVFF   aL, rL
        MOVF    bL, W
        ADDWF   rL, F

        ; rH = aH + bH + carry
        MOVFF   aH, rH
        MOVF    bH, W
        ADDWFC  rH, F
        ENDM

SUB16    MACRO dL,dH,sL,sH ;d -= s
        MOVF    sL,W
        SUBWF   dL,F
        MOVF    sH,W
        SUBWFB  dH,F
        ENDM

SUB16_TO    MACRO dL,dH,sL,sH, rL, rH ;r = d - s
        ; rL = dL - sL
        MOVFF   dL, rL
        MOVF    sL, W
        SUBWF   rL, F
        ; BTFSS STATUS, C  ;for not using SUBWFB
        ; MOVLF 0x01, 0x40

        ; rH = dH - sH - borrow
        MOVFF   dH, rH
        MOVF    sH, W
        SUBWF  rH, F

        ; BTFSC    0x40, 0
        ; DECF rH
        ENDM
CMP16    MACRO aL,aH,bL,bH     ; sets C/Z from (a-b) without changing a
        LOCAL   _c1,_c2
        MOVF    bL,W
        SUBWF   aL,W           ; W=(aL-bL)
        MOVWF   0x7F           ; temp in access if allowed; else change
_c1     MOVF    bH,W
        SUBWFB  aH,W
        ENDM
INC16    MACRO xL,xH
        INCF    xL,F
        BTFSC   STATUS,0
        INCF    xH,F
        ENDM
DEC16    MACRO xL,xH
        MOVLW   1
        SUBWF   xL,F
        BTFSS   STATUS,0
        DECF    xH,F
        ENDM

; --- logical & arithmetic shifts (16-bit) ---
LSL16    MACRO xL,xH
        BCF     STATUS,0
        RLCF    xL,F
        RLCF    xH,F
        ENDM
LSR16    MACRO xL,xH
        BCF     STATUS,0
        RRCF    xH,F
        RRCF    xL,F
        ENDM
ASR16    MACRO xL,xH            ; arithmetic >>1
        BTFSC   xH,7
        BSF     STATUS,0
        BTFSS   xH,7
        BCF     STATUS,0
        RRCF    xH,F
        RRCF    xL,F
        ENDM
; ======= Equates (assumed) =======
; nL/nH: dividend, dL/dH: divisor
; quoL/quoH: quotient, rL/rH: remainder
; cnt: scratch for DIV16U16_UNSIGNED
; cnt_tmp: scratch for sign bookkeeping

; Helper: NEG16 in-place (two's complement)
;   Args:  lo, hi (registers)
NEG16    MACRO lo, hi
    COMF    lo, F
    COMF    hi, F
    INCF    lo, F
    BTFSC   STATUS, Z
    INCF    hi, F
    ENDM

; Helper: ABS16 in-place (two's complement if negative)
;   Sets Z if result == 0, preserves sign in C? (not relied upon)
;   Args: lo, hi
ABS16    MACRO lo, hi
    BTFSS   hi, 7, ACCESS      ; if negative?
    GOTO    $+3
    NEG16   lo, hi
    NOP                         ; align (optional)
    ENDM

; ======= DIV16S16_SIGNED subroutine =======
; Input : nH:nL (dividend), dH:dL (divisor), unsigned macro available
; Output: quoH:quoL (signed quotient), rH:rL (signed remainder)
; Clobbers: W, STATUS, PRODH/PRODL (via macro), cnt, cnt_tmp
; Behavior:
;   - If divisor == 0: quotient=0, remainder=0 (graceful return)
;   - If dividend = 0x8000 and divisor = 0xFFFF: sets quotient=0x7FFF, remainder=0  ; (saturate)
;       (Change to 0x8000 if you prefer wraparound?see comment below)
DIV16S16_SIGNED:
    ; Clear outputs by default (useful for div-by-zero path)
    CLRF    quoL, ACCESS
    CLRF    quoH, ACCESS
    CLRF    rL,  ACCESS
    CLRF    rH,  ACCESS

    ; --- Check divisor == 0 ? return (quo=0, rem=0) ---
    MOVF    dH, W, ACCESS
    IORWF   dL, W, ACCESS
    BZ      _sdone

    ; --- Save sign info into cnt_tmp bits ---
    ; cnt_tmp bit0 = sign(dividend), bit1 = sign(divisor), bit2 = sign(quotient) = XOR
    CLRF    cnt_tmp, ACCESS
    BTFSC   nH, 7, ACCESS
    BSF     cnt_tmp, 0, ACCESS      ; sN
    BTFSC   dH, 7, ACCESS
    BSF     cnt_tmp, 1, ACCESS      ; sD
    ; sQ = sN XOR sD ? bit2
    BTFSC   cnt_tmp, 0, ACCESS
    BTG     cnt_tmp, 2, ACCESS
    BTFSC   cnt_tmp, 1, ACCESS
    BTG     cnt_tmp, 2, ACCESS

    ; --- Overflow guard: (-32768) / (-1) ---
    ; n == 0x8000 and d == 0xFFFF ?
    MOVLW   0x80
    CPFSEQ  nH, ACCESS
    GOTO    _skip_OVF
    MOVF    nL, W, ACCESS
    BNZ     _skip_OVF
    MOVLW   0xFF
    CPFSEQ  dH, ACCESS
    GOTO    _skip_OVF
    MOVF    dL, W, ACCESS
    BNZ     _skip_OVF

    ; Saturate: quotient = +32767 (0x7FFF), remainder = 0
    MOVLW   0xFF
    MOVWF   quoL, ACCESS
    MOVLW   0x7F
    MOVWF   quoH, ACCESS
    CLRF    rL, ACCESS
    CLRF    rH, ACCESS
    GOTO    _sdone
_skip_OVF:

    ; --- Take absolute values for unsigned divide ---
    ; abs(dividend) in-place
    BTFSS   cnt_tmp, 0, ACCESS      ; if dividend was negative
    GOTO    $+3
    NEG16   nL, nH
    NOP
    ; abs(divisor) in-place
    BTFSS   cnt_tmp, 1, ACCESS      ; if divisor was negative
    GOTO    $+3
    NEG16   dL, dH
    NOP

    ; --- Unsigned divide: q = |n| / |d|, r = |n| % |d| ---
    DIV16U16_UNSIGNED  nH, nL,  dH, dL,  quoH, quoL,  rH, rL,  cnt

    ; --- Restore quotient sign: if sQ then negate quotient ---
    BTFSS   cnt_tmp, 2, ACCESS
    GOTO    _rem_sign
    ; q = -q
    ; (Two's complement even if zero; zero stays zero)
    NEG16   quoL, quoH

_rem_sign:
    ; --- Restore remainder sign: same sign as original dividend (sN) ---
    ; If r == 0, leave as 0 (signless). Otherwise, negate if sN=1.
    MOVF    rH, W, ACCESS
    IORWF   rL, W, ACCESS
    BZ      _sdone
    BTFSS   cnt_tmp, 0, ACCESS      ; if dividend negative
    GOTO    _sdone
    NEG16   rL, rH

_sdone:
    RETURN

; --- 16/8 unsigned division: (dH:dL)/div -> quoH:quoL, rem ---
DIV16U8  MACRO dH,dL, div, quoH,quoL, rem, cnt
        LOCAL   _h,_hge,_hnx,_l,_lge,_lnx
        CLRF    quoH
        CLRF    rem
        MOVLW   8
        MOVWF   cnt
_h      RLCF    dH,F
        RLCF    rem,F
        MOVF    div,W
        SUBWF   rem,W
        BTFSC   STATUS,0
        GOTO    _hge
        BCF     STATUS,0
        RLCF    quoH,F
        GOTO    _hnx
_hge    MOVF    div,W
        SUBWF   rem,F
        BSF     STATUS,0
        RLCF    quoH,F
_hnx    DECFSZ  cnt,F
        GOTO    _h
        CLRF    quoL
        MOVLW   8
        MOVWF   cnt
_l      RLCF    dL,F
        RLCF    rem,F
        MOVF    div,W
        SUBWF   rem,W
        BTFSC   STATUS,0
        GOTO    _lge
        BCF     STATUS,0
        RLCF    quoL,F
        GOTO    _lnx
_lge    MOVF    div,W
        SUBWF   rem,F
        BSF     STATUS,0
        RLCF    quoL,F
_lnx    DECFSZ  cnt,F
        GOTO    _l
        ENDM

; ======= 16/8 unsigned long-division (remainder + quotient) =======
; (divH:divL) / divsor  ?  quoH:quoL, rem
DIV16U8_LONG MACRO divH, divL, divsor, quoH, quoL, rem, cnt
    LOCAL _loop, _no_sub, _next
    CLRF    quoH
    CLRF    quoL
    CLRF    rem
    MOVLW   16
    MOVWF   cnt
_loop:
    BCF     STATUS, C
    RLCF    divL, F
    RLCF    divH, F
    RLCF    rem, F
    MOVF    divsor, W
    SUBWF   rem, W          ; C=1 if rem >= divsor
    BTFSS   STATUS, C
    GOTO    _no_sub
    MOVF    divsor, W
    SUBWF   rem, F
    RLCF    quoL, F         ; shift in 1
    RLCF    quoH, F
    GOTO    _next
_no_sub:
    BCF     STATUS, C       ; shift in 0
    RLCF    quoL, F
    RLCF    quoH, F
_next:
    DECFSZ  cnt, F
    GOTO    _loop
ENDM

; --- 8x8 -> 16 multiply accumulate: acc += a*b (acc = aH:aL) ---
MAC16_8x8 MACRO a,b, accL,accH
        MOVF    a,W
        MULWF   b              ; PRODH:PRODL = a*b
        MOVF    PRODL,W
        ADDWF   accL,F
        MOVF    PRODH,W
        ADDWFC  accH,F
        ENDM

; FOR8_REG i, limReg, bodyLbl
; for (i=0; i<[*limReg]; i++) bodyLbl();
FOR8_REG MACRO i, limReg , bodyLbl
    LOCAL _loop, _end
    CLRF    i
_loop
    MOVF    i, W, ACCESS
    SUBWF   limReg, w, ACCESS
    BTFSC   STATUS, Z  ; if equal ? stop
    GOTO    _end
    BTFSS   STATUS, C  ; if i > limit ? stop
    GOTO    _end

    ; <<< Your code here >>>
    ; you can either write instructions directly here,
    ; or define a subroutine and replace the CALL below.

    CALL    bodyLbl    ; body() executes each loop

    INCF    i, F, ACCESS       ; i++
    GOTO    _loop
_end
ENDM


; --- simple 8-bit for(i=0;i<limit;i++) { body() } ---
FOR8 MACRO i, limit, bodyLbl
    LOCAL _loop, _end
    CLRF    i          ; i = 0
_loop
    MOVF    i, W
    SUBLW   limit      ; compare i with limit
    BTFSC   STATUS, Z  ; if equal ? stop
    GOTO    _end
    BTFSS   STATUS, C  ; if i > limit ? stop
    GOTO    _end

    ; <<< Your code here >>>
    ; you can either write instructions directly here,
    ; or define a subroutine and replace the CALL below.

    CALL    bodyLbl    ; body() executes each loop

    INCF    i, F       ; i++
    GOTO    _loop
_end
ENDM

; ============================================================
; FOR2D_REG i, j, limI, limJ, bodyLbl
; for (i=0; i<[*limI]; i++)
;   for (j=0; j<[*limJ]; j++)
;       bodyLbl();
; Notes:
;  - limI, limJ are register addresses holding the limits.
;  - Compares via (i - limit) so:
;      Z=1 ? i == limit  ? stop
;      C=1 ? i >  limit  ? stop (no-borrow means i >= limit)
; ============================================================
FOR2D_REG MACRO i, j, limI, limJ, bodyLbl
    LOCAL _outer, _inner, _end_inner, _end_outer

    CLRF    i                 ; i = 0
_outer
    MOVF    limI, W
    SUBWF   i, W              ; W = i - limI
    BTFSC   STATUS, Z         ; i == limI ?
    GOTO    _end_outer
    BTFSC   STATUS, C         ; i > limI ?
    GOTO    _end_outer

    CLRF    j                 ; j = 0
_inner
    MOVF    limJ, W
    SUBWF   j, W              ; W = j - limJ
    BTFSC   STATUS, Z         ; j == limJ ?
    GOTO    _end_inner
    BTFSC   STATUS, C         ; j > limJ ?
    GOTO    _end_inner

    ; ---------- your operation here ----------
    CALL    bodyLbl
    ; -----------------------------------------

    INCF    j, F              ; j++
    GOTO    _inner

_end_inner
    INCF    i, F              ; i++
    GOTO    _outer

_end_outer
ENDM


    
; --- memset: fill count bytes at FSRx with value in W ---
MEMSET   MACRO fsrL,fsrH, count
        LOCAL   _ms1,_ms2
_ms1    MOVF    count,W
        BZ      _ms2
        MOVWF   POSTINC0       ; assumes FSR0 targeted; change if needed
        DECF    count,F
        GOTO    _ms1
_ms2    ENDM

; --- memcpy: copy count bytes FSR0 -> FSR1 ---
MEMCPY   MACRO count
        LOCAL   _cp1,_cp2
_cp1    MOVF    count,W
        BZ      _cp2
        MOVF    POSTINC0,W
        MOVWF   POSTINC1
        DECF    count,F
        GOTO    _cp1
_cp2    ENDM

; --- nibble helpers ---
GET_HINIB MACRO src,dst
        MOVF    src,W
        MOVWF   dst
        SWAPF   dst,F
        ANDLW   0x0F
        MOVWF   dst
        ENDM
GET_LONIB MACRO src,dst
        MOVF    src,W
        ANDLW   0x0F
        MOVWF   dst
        ENDM
PACK_NIB  MACRO hi,lo,dst
        MOVF    hi,W
        ANDLW   0x0F
        MOVWF   dst
        SWAPF   dst,F
        MOVF    lo,W
        ANDLW   0x0F
        IORWF   dst,F
        ENDM

; div_8_8 divd, divsor, quo_dest, rem_dest
; (divd / divsor) ? quotient in quo_dest, remainder in rem_dest
; Uses temps: 0x20 (quo), 0x22 (rem), 0x26 (cnt)

div_8_8 MACRO divd, divsor, quo_dest, rem_dest, cnt_dest
    LOCAL loop, no_sub, next

    CLRF    quo_dest            ; quo
    CLRF    rem_dest            ; rem
    MOVLW   8
    MOVWF   cnt_dest            ; cnt = 8

loop:
    ; shift dividend bit into remainder (MSB-first)
    BCF     STATUS, C       ; ensure 0 shifts into LSB
    RLCF    divd, F
    RLCF    rem_dest, F         ; rem <<= 1 | carry

    ; compare rem vs divsor (unsigned)
    MOVF    divsor, W
    SUBWF   rem_dest, W         ; C=1 if rem >= divsor
    BTFSS   STATUS, C
    GOTO    no_sub

    ; rem >= divsor ? subtract, shift '1' into quotient
    MOVF    divsor, W
    SUBWF   rem_dest, F         ; rem -= divsor (leaves C=1)
    RLCF    quo_dest, F         ; shift in 1 to quo
    GOTO    next

no_sub:
    ; rem < divsor ? shift '0' into quotient
    BCF     STATUS, C
    RLCF    quo_dest, F

next:
    DECFSZ  cnt_dest, F
    GOTO    loop

    CLRF    cnt_dest
ENDM

;; 16-bit ÷ 16-bit (unsigned, restoring division)
;; (dH:dL) / (vH:vL) ? quoH:quoL, remainder in rH:rL
;; cnt is a scratch loop counter (clobbered)
;; Clobbers: WREG, STATUS (C/Z)
;; Assumes operands live in access RAM when using ,ACCESS

DIV16U16_UNSIGNED MACRO dH,dL, vH,vL, quoH,quoL, rH,rL, cnt
    LOCAL _ok, _loop, _ge, _lt, _next, _done, _divzero

    ; init outputs
    CLRF    quoH, ACCESS
    CLRF    quoL, ACCESS
    CLRF    rH,   ACCESS
    CLRF    rL,   ACCESS

    ; handle divisor == 0 (policy: quotient=FFFFh, remainder=dividend)
    MOVF    vL, W, ACCESS
    IORWF   vH, W, ACCESS
    BNZ     _ok
_divzero
    MOVLW   0xFF
    MOVWF   quoH, ACCESS
    MOVWF   quoL, ACCESS
    MOVF    dL, W, ACCESS
    MOVWF   rL, ACCESS
    MOVF    dH, W, ACCESS
    MOVWF   rH, ACCESS
    GOTO    _done

_ok
    MOVLW   d'16'
    MOVWF   cnt, ACCESS

_loop
    ; shift dividend left; C ends up = old bit15 of dividend
    BCF     STATUS, C
    RLCF    dL, F, ACCESS
    RLCF    dH, F, ACCESS

    ; shift remainder left, bringing in that bit from C
    RLCF    rL, F, ACCESS
    RLCF    rH, F, ACCESS

    ; compare (rH:rL) ? (vH:vL), leave r intact; final C=1 iff r>=v
    MOVF    vL, W, ACCESS
    SUBWF   rL, W, ACCESS           ; W = rL - vL, sets C
    MOVF    vH, W, ACCESS
    SUBWFB  rH, W, ACCESS           ; final C from full 16-bit compare

    ; branch BEFORE touching C
    BTFSS   STATUS, C
    GOTO    _lt

_ge
    ; C=1 ? quotient bit = 1, then r -= v
    RLCF    quoL, F, ACCESS
    RLCF    quoH, F, ACCESS
    MOVF    vL, W, ACCESS
    SUBWF   rL, F, ACCESS
    MOVF    vH, W, ACCESS
    SUBWFB  rH, F, ACCESS
    GOTO    _next

_lt
    ; C=0 ? quotient bit = 0 (no subtract)
    RLCF    quoL, F, ACCESS
    RLCF    quoH, F, ACCESS

_next
    DECFSZ  cnt, F, ACCESS
    GOTO    _loop

_done
ENDM

;;; Integer sqrt via Newton's method (unsigned 16-bit)
;; Input : nH:nL = N
;; In/Out: xH:xL = initial guess on entry; floor(sqrt(N)) on return
;; Scratch: qH:qL (N/x), rH:rL (unused remainder), tH:tL (next x),
;;          iter (outer loop cap), cnt_div (divider loop counter)
SQRT16_NEWTON MACRO nH,nL, xH,xL, qH,qL, rH,rL, tH,tL, iter, cnt_div
    LOCAL _seed_ok, _iter, _done

    ; N==0 ? x=0
    MOVF    nL, W, ACCESS
    IORWF   nH, W, ACCESS
    BNZ     _seed_ok
    CLRF    xL, ACCESS
    CLRF    xH, ACCESS
    GOTO    _done

_seed_ok
    ; ensure x != 0 (avoid div-by-zero)
    MOVF    xL, W, ACCESS
    IORWF   xH, W, ACCESS
    BNZ     $+4
    MOVFF   nL, xL
    MOVFF   nH, xH

    ; optional safety cap: ? 16 Newton steps
    MOVLW   16
    MOVWF   iter, ACCESS

_iter
    ; q = N / x
    DIV16U16_UNSIGNED nH,nL, xH,xL, qH, qL, rH, rL, cnt_div

    ; t = (x + q) >> 1
    MOVFF   xL, tL
    MOVF    qL, W, ACCESS
    ADDWF   tL, F, ACCESS
    MOVFF   xH, tH
    MOVF    qH, W, ACCESS
    ADDWFC  tH, F, ACCESS
    RRCF    tH, F, ACCESS
    RRCF    tL, F, ACCESS

    ; stop if t == x
    MOVF    tL, W, ACCESS
    XORWF   xL, W, ACCESS
    BNZ     $+6
    MOVF    tH, W, ACCESS
    XORWF   xH, W, ACCESS
    BZ      _done

    ; x = t
    MOVFF   tL, xL
    MOVFF   tH, xH

    ; loop guard (separate from divider!)
    DECFSZ  iter, F, ACCESS
    GOTO    _iter

_done
ENDM



;; --- Template for recursion ---
;RECUR_FUNC:
;    ; base case
;    <check condition>
;    BZ  BASE_DONE
;
;    ; save current state
;    MOVFF PARAM, TEMP
;    <modify PARAM for recursive call>
;
;    CALL RECUR_FUNC       ; recursion
;
;    ; restore
;    MOVFF TEMP, PARAM
;    <combine result>
;
;BASE_DONE:
;    RETURN

; =========================================================
; GCD8 a, b, dest, t0
; Computes gcd(a, b) for 8-bit unsigned values.
; Result placed in 'dest'. Uses temp byte 't0'.
; Does not require any other macros.
; =========================================================
GCD8 MACRO a, b, dest, t0
    LOCAL _start, _a_zero, _b_zero, _loop, _mod_try, _mod_done, _done

_start
    ; handle edge cases
    MOVF    a, W
    BZ      _a_zero
    MOVF    b, W
    BZ      _b_zero
    GOTO    _loop

_a_zero
    MOVFF   b, dest
    GOTO    _done

_b_zero
    MOVFF   a, dest
    GOTO    _done

; Euclid loop:
; while (b != 0) { t0 = a % b; a = b; b = t0; }
_loop
    ; t0 = a % b  (repeated subtraction modulo)
    MOVF    a, W
    MOVWF   t0

_mod_try
    ; try t0 -= b; if borrow (C=0), undo and finish modulo
    MOVF    b, W
    SUBWF   t0, F          ; t0 = t0 - b
    BTFSC   STATUS, C      ; if no borrow (t0 >= 0), keep subtracting
    GOTO    _mod_try

    ; borrow occurred ? undo last subtract, t0 is remainder
    MOVF    b, W
    ADDWF   t0, F          ; t0 += b (restore to positive remainder)

_mod_done
    ; a = b; b = t0
    MOVFF   b, a
    MOVFF   t0, b

    ; if b == 0 ? done (gcd in a)
    MOVF    b, W
    BZ      _b_zero        ; reuse path: dest = a

    GOTO    _loop

_done
ENDM

; =========================================================
; GCD16U_STEIN aL,aH, bL,bH, outL,outH,  tL,tH,  k, tmp
; Computes gcd( (aH:aL), (bH:bL) ) ? (outH:outL), unsigned.
; Temps:
;   tL:tH = work copy of B
;   k     = common power-of-two count
;   tmp   = 1-byte scratch for swapping
; No other macro dependencies.
; =========================================================
GCD16U_STEIN MACRO aL,aH, bL,bH, outL,outH, tL,tH, k, tmp
    LOCAL _a_zero,_b_zero,_common,_make_a_odd,_gcd_loop,_t_even
    LOCAL _cmp_swap,_do_swap,_sub,_done,_shift_back

    ; out = A, t = B
    MOVFF   aL, outL
    MOVFF   aH, outH
    MOVFF   bL, tL
    MOVFF   bH, tH

    ; if A == 0 ? gcd = B
    MOVF    outL, W
    IORWF   outH, W
    BZ      _a_zero

    ; if B == 0 ? gcd = A
    MOVF    tL, W
    IORWF   tH, W
    BZ      _b_zero

    ; k = 0 (common factors of 2)
    CLRF    k

_common
    ; while A even AND B even: A>>=1; B>>=1; k++
    BTFSC   outL, 0
    GOTO    _make_a_odd
    BTFSC   tL, 0
    GOTO    _make_a_odd

    ; A >>= 1 (logical)
    BCF     STATUS, C
    RRCF    outH, F
    RRCF    outL, F
    ; B >>= 1 (logical)
    BCF     STATUS, C
    RRCF    tH, F
    RRCF    tL, F
    INCF    k, F
    GOTO    _common

_make_a_odd
    ; make A odd: while A even, A >>= 1
    BTFSC   outL, 0
    GOTO    _gcd_loop
    BCF     STATUS, C
    RRCF    outH, F
    RRCF    outL, F
    GOTO    _make_a_odd

_gcd_loop
    ; if B == 0 ? done (A is gcd)
    MOVF    tL, W
    IORWF   tH, W
    BZ      _shift_back

_t_even
    ; while B even, B >>= 1
    BTFSC   tL, 0
    GOTO    _cmp_swap
    BCF     STATUS, C
    RRCF    tH, F
    RRCF    tL, F
    GOTO    _t_even

_cmp_swap
    ; if A > B, swap(A,B) so that B >= A
    MOVF    tL, W
    SUBWF   outL, W        ; W = outL - tL
    MOVF    tH, W
    SUBWFB  outH, W        ; C=1 ? A >= B
    BTFSC   STATUS, C
    GOTO    _do_swap       ; swap if A >= B (safe also for equality)

    ; B = B - A
_sub
    MOVF    outL, W
    SUBWF   tL, F
    MOVF    outH, W
    SUBWFB  tH, F
    GOTO    _gcd_loop

_do_swap
    ; swap outL <-> tL  (use tmp)
    MOVFF   outL, tmp
    MOVFF   tL,  outL
    MOVFF   tmp, tL
    ; swap outH <-> tH
    MOVFF   outH, tmp
    MOVFF   tH,  outH
    MOVFF   tmp, tH
    GOTO    _sub

_shift_back
    ; restore common factor: A <<= k
    MOVF    k, W
    BZ      _done
    ; loop: while k-- > 0: A <<= 1
    ; (logical left shift)
    BCF     STATUS, C
    RLCF    outL, F
    RLCF    outH, F
    DECF    k, F
    GOTO    _shift_back

_a_zero
    ; gcd = B
    MOVFF   tL, outL
    MOVFF   tH, outH
    GOTO    _done

_b_zero
    ; gcd = A already in out
_done
ENDM

; =========================================================
; Comparators
; =========================================================

;---------------------------------------------------------
; CMP16U  ? set flags for unsigned a ? b
;   Input: aL,aH, bL,bH
;   Effect: final C = 1 iff a >= b ; final C = 0 iff a < b
;           (Do NOT trust Z for equality)
;---------------------------------------------------------
CMP16U MACRO aL,aH, bL,bH
    MOVF    bL, W, ACCESS
    SUBWF   aL, W, ACCESS       ; W = aL - bL, sets C/Z for low
    MOVF    bH, W, ACCESS
    SUBWFB  aH, W, ACCESS       ; W = aH - bH - !C ; final C is correct for 16-bit
ENDM

;---------------------------------------------------------
; BR_LT16U label   ? branch if a <  b   (unsigned)
; BR_GE16U label   ? branch if a >= b   (unsigned)
;   Uses only C from the prior CMP16U
;---------------------------------------------------------
BR_LT16U MACRO label
    BTFSS   STATUS, C           ; C=0 ? a<b
    GOTO    label
ENDM

BR_GE16U MACRO label
    BTFSC   STATUS, C           ; C=1 ? a>=b
    GOTO    label
ENDM

;---------------------------------------------------------
; BR_EQ16U  aL,aH,bL,bH,label   ? branch if a == b
; BR_NE16U  aL,aH,bL,bH,label   ? branch if a != b
;   Uses CPFSEQ (does not touch STATUS) to test equality.
;   Safe to call after CMP16U (doesn't clobber C).
;---------------------------------------------------------
BR_EQ16U MACRO aL,aH, bL,bH, label
    LOCAL _neq,_end
    MOVF    aL, W, ACCESS
    CPFSEQ  bL, ACCESS          ; skip next if equal
    GOTO    _neq
    MOVF    aH, W, ACCESS
    CPFSEQ  bH, ACCESS
    GOTO    _neq
    GOTO    label               ; both bytes equal
_neq:
_end:
ENDM

BR_NE16U MACRO aL,aH, bL,bH, label
    LOCAL _ne,_end
    MOVF    aL, W, ACCESS
    CPFSEQ  bL, ACCESS
    GOTO    _ne                 ; low differs
    MOVF    aH, W, ACCESS
    CPFSEQ  bH, ACCESS
    GOTO    _ne                 ; high differs
    GOTO    _end                ; equal ? do not branch
_ne:
    GOTO    label
_end:
ENDM

;---------------------------------------------------------
; BR_GT16U  aL,aH,bL,bH,label   ? branch if a > b
;   Logic: (a>=b) AND (a!=b) without trusting Z.
;   Keeps C from CMP16U and checks inequality via CPFSEQ.
;---------------------------------------------------------
BR_GT16U MACRO aL,aH, bL,bH, label
    LOCAL _maybe,_end,_ne
    ; need a>=b first
    BTFSC   STATUS, C           ; C=1 ? a>=b
    GOTO    _maybe
    GOTO    _end                ; a<b ? no branch

_maybe:
    ; if a != b, then a>b (since we already know a>=b)
    MOVF    aL, W, ACCESS
    CPFSEQ  bL, ACCESS
    GOTO    _ne
    MOVF    aH, W, ACCESS
    CPFSEQ  bH, ACCESS
    GOTO    _ne                ; equal ? not greater

    GOTO _end
_ne:
    GOTO    label
_end:
ENDM


; =================== sample usage ===================
; ; Compare A(0x31:0x30) with B(0x33:0x32)
; CMP16U  0x30,0x31, 0x32,0x33
; BR_EQ16  equal_u
; BR_LT16U less_u
; ; else greater_u
; GOTO    greater_u

; equal_u:
;     ; a==b
;     GOTO done

; less_u:
;     ; a<b (unsigned)
;     GOTO done

; greater_u:
;     ; a>b (unsigned)
; done:

; =================== end of toolbelt.inc ===================